import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../constants/supabase_constants.dart';
import '../storage/secure_storage_service.dart';
import '../../features/authentication/domain/models/auth_tokens.dart';

/// Centralized API client and network interceptor responsible for:
/// 1. Automatically injecting `Authorization: Bearer <access_token>` into authenticated requests.
/// 2. Reading access and refresh tokens from [SecureStorageService].
/// 3. Intercepting `401 Unauthorized` responses and executing single-retry token refresh.
/// 4. Clearing credentials and dispatching [onAuthFailed] when refresh fails or expires.
/// 5. Preventing infinite retry loops.
class ApiClient extends http.BaseClient {
  final http.Client _innerClient;
  final SecureStorageService secureStorage;
  final String? baseUrl;

  /// Callback executed when token refresh fails and session is deemed unauthenticated.
  VoidCallback? onAuthFailed;

  /// Custom refresh token handler, useful for mocking or custom auth backends.
  Future<AuthTokens?> Function(String refreshToken)? refreshTokenHandler;

  /// Custom login handler, useful for mocking or custom auth backends.
  Future<AuthTokens> Function(String email, String password)? loginHandler;

  /// Mutex future preventing multiple concurrent token refreshes (thundering herd).
  Future<AuthTokens?>? _refreshFuture;

  ApiClient({
    http.Client? innerClient,
    required this.secureStorage,
    this.baseUrl,
    this.onAuthFailed,
    this.refreshTokenHandler,
    this.loginHandler,
  }) : _innerClient = innerClient ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uriPath = request.url.path;
    final isAuthEndpoint = uriPath.contains('/token') ||
        uriPath.contains('/login') ||
        uriPath.contains('/refresh');
    final isNoAuthExplicit = request.headers['x-no-auth'] == 'true';
    final shouldAttachAuth = !isNoAuthExplicit &&
        !isAuthEndpoint &&
        !request.headers.containsKey('Authorization');

    // 1. Inject Authorization header if token exists
    if (shouldAttachAuth) {
      final token = await secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    // 2. Clone request before first send to allow retrying on 401
    final isRetried = request.headers['x-retried'] == 'true';
    final requestForRetry = (!isRetried && !isAuthEndpoint && !isNoAuthExplicit)
        ? _cloneBaseRequest(request)
        : null;

    final response = await _innerClient.send(request);

    // 3. Handle 401 Unauthorized for authenticated requests
    if (response.statusCode == 401 && !isRetried && !isAuthEndpoint && !isNoAuthExplicit) {
      final refreshedTokens = await _performTokenRefresh();

      if (refreshedTokens != null &&
          refreshedTokens.accessToken.isNotEmpty &&
          requestForRetry != null) {
        // Retry the original request once with the new access token
        final retriedRequest = _cloneBaseRequest(requestForRetry);
        retriedRequest.headers['Authorization'] =
            'Bearer ${refreshedTokens.accessToken}';
        retriedRequest.headers['x-retried'] = 'true';

        return await _innerClient.send(retriedRequest);
      }
    }

    return response;
  }

  /// Thread-safe / deduplicated token refresh execution.
  Future<AuthTokens?> _performTokenRefresh() async {
    if (_refreshFuture != null) {
      return await _refreshFuture;
    }

    final completer = Completer<AuthTokens?>();
    _refreshFuture = completer.future;

    try {
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await secureStorage.clearTokens();
        onAuthFailed?.call();
        completer.complete(null);
        return null;
      }

      final newTokens = await _executeRefreshToken(refreshToken);
      if (newTokens != null && newTokens.accessToken.isNotEmpty) {
        await secureStorage.saveTokens(
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken.isNotEmpty
              ? newTokens.refreshToken
              : refreshToken,
        );
        completer.complete(newTokens);
        return newTokens;
      } else {
        await secureStorage.clearTokens();
        onAuthFailed?.call();
        completer.complete(null);
        return null;
      }
    } catch (_) {
      await secureStorage.clearTokens();
      onAuthFailed?.call();
      completer.complete(null);
      return null;
    } finally {
      _refreshFuture = null;
    }
  }

  /// Executes the refresh token API call.
  Future<AuthTokens?> _executeRefreshToken(String refreshToken) async {
    if (refreshTokenHandler != null) {
      return await refreshTokenHandler!(refreshToken);
    }

    final base = baseUrl ?? SupabaseConstants.url;
    final refreshUri = Uri.parse('$base/auth/v1/token?grant_type=refresh_token');

    final response = await _innerClient.post(
      refreshUri,
      headers: {
        'apikey': SupabaseConstants.publishableKey,
        'Content-Type': 'application/json',
        'x-no-auth': 'true',
      },
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthTokens.fromJson(data);
    }

    return null;
  }

  /// Authenticates using email and password against the auth API.
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    if (loginHandler != null) {
      final tokens = await loginHandler!(email, password);
      await secureStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens;
    }

    final base = baseUrl ?? SupabaseConstants.url;
    final loginUri = Uri.parse('$base/auth/v1/token?grant_type=password');

    final response = await _innerClient.post(
      loginUri,
      headers: {
        'apikey': SupabaseConstants.publishableKey,
        'Content-Type': 'application/json',
        'x-no-auth': 'true',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data);
      await secureStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens;
    } else {
      String errorMessage = 'Authentication failed (${response.statusCode})';
      try {
        final err = jsonDecode(response.body);
        if (err is Map && err.containsKey('error_description')) {
          errorMessage = err['error_description'];
        } else if (err is Map && err.containsKey('message')) {
          errorMessage = err['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  /// Signs out the user by calling the logout endpoint if one exists,
  /// and clearing credentials from secure storage.
  Future<void> logout() async {
    try {
      final token = await secureStorage.getAccessToken();
      final base = baseUrl ?? SupabaseConstants.url;
      final logoutUri = Uri.parse('$base/auth/v1/logout');

      if (token != null && token.isNotEmpty) {
        await _innerClient.post(
          logoutUri,
          headers: {
            'apikey': SupabaseConstants.publishableKey,
            'Authorization': 'Bearer $token',
            'x-no-auth': 'true',
          },
        );
      }
    } catch (_) {
      // Best-effort logout: ignore network failures on backend invalidation
    } finally {
      await secureStorage.clearTokens();
    }
  }

  /// Clones an HTTP request for retry execution.
  http.BaseRequest _cloneBaseRequest(http.BaseRequest request) {
    if (request is http.Request) {
      final copy = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
      return copy;
    } else if (request is http.MultipartRequest) {
      final copy = http.MultipartRequest(request.method, request.url)
        ..headers.addAll(request.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      return copy;
    }
    return request;
  }

  // ---------------------------------------------------------------------------
  // Convenience HTTP Methods
  // ---------------------------------------------------------------------------

  @override
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final effectiveHeaders = Map<String, String>.from(headers ?? {});
    if (!requiresAuth) {
      effectiveHeaders['x-no-auth'] = 'true';
    }
    final req = http.Request('GET', url)..headers.addAll(effectiveHeaders);
    final streamed = await send(req);
    return await http.Response.fromStream(streamed);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requiresAuth = true,
  }) async {
    final effectiveHeaders = Map<String, String>.from(headers ?? {});
    if (!requiresAuth) {
      effectiveHeaders['x-no-auth'] = 'true';
    }
    final req = http.Request('POST', url)..headers.addAll(effectiveHeaders);
    if (body != null) {
      if (body is String) {
        req.body = body;
      } else if (body is List<int>) {
        req.bodyBytes = body;
      } else if (body is Map || body is List) {
        req.body = jsonEncode(body);
        req.headers.putIfAbsent('content-type', () => 'application/json');
      }
    }
    if (encoding != null) {
      req.encoding = encoding;
    }
    final streamed = await send(req);
    return await http.Response.fromStream(streamed);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requiresAuth = true,
  }) async {
    final effectiveHeaders = Map<String, String>.from(headers ?? {});
    if (!requiresAuth) {
      effectiveHeaders['x-no-auth'] = 'true';
    }
    final req = http.Request('PUT', url)..headers.addAll(effectiveHeaders);
    if (body != null) {
      if (body is String) {
        req.body = body;
      } else if (body is List<int>) {
        req.bodyBytes = body;
      } else if (body is Map || body is List) {
        req.body = jsonEncode(body);
        req.headers.putIfAbsent('content-type', () => 'application/json');
      }
    }
    if (encoding != null) {
      req.encoding = encoding;
    }
    final streamed = await send(req);
    return await http.Response.fromStream(streamed);
  }

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requiresAuth = true,
  }) async {
    final effectiveHeaders = Map<String, String>.from(headers ?? {});
    if (!requiresAuth) {
      effectiveHeaders['x-no-auth'] = 'true';
    }
    final req = http.Request('PATCH', url)..headers.addAll(effectiveHeaders);
    if (body != null) {
      if (body is String) {
        req.body = body;
      } else if (body is List<int>) {
        req.bodyBytes = body;
      } else if (body is Map || body is List) {
        req.body = jsonEncode(body);
        req.headers.putIfAbsent('content-type', () => 'application/json');
      }
    }
    if (encoding != null) {
      req.encoding = encoding;
    }
    final streamed = await send(req);
    return await http.Response.fromStream(streamed);
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requiresAuth = true,
  }) async {
    final effectiveHeaders = Map<String, String>.from(headers ?? {});
    if (!requiresAuth) {
      effectiveHeaders['x-no-auth'] = 'true';
    }
    final req = http.Request('DELETE', url)..headers.addAll(effectiveHeaders);
    if (body != null) {
      if (body is String) {
        req.body = body;
      } else if (body is List<int>) {
        req.bodyBytes = body;
      } else if (body is Map || body is List) {
        req.body = jsonEncode(body);
        req.headers.putIfAbsent('content-type', () => 'application/json');
      }
    }
    if (encoding != null) {
      req.encoding = encoding;
    }
    final streamed = await send(req);
    return await http.Response.fromStream(streamed);
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }
}
