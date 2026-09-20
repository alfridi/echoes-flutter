import 'dart:convert';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../models/user_profile.dart';
import '../../domain/models/auth_tokens.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] integrating [ApiClient],
/// [SecureStorageService], and [SupabaseService].
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService secureStorage;
  final SupabaseService _supabase;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.secureStorage,
    SupabaseService? supabase,
  }) : _supabase = supabase ?? SupabaseService();

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    // 1. Call Authentication API via ApiClient
    final tokens = await apiClient.login(
      email: email,
      password: password,
    );

    // 2. Persist tokens in SecureStorageService (strictly no SharedPreferences)
    await secureStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    // 3. Sync active session with Supabase client if refreshToken is valid
    try {
      if (tokens.refreshToken.isNotEmpty) {
        await _supabase.client.auth.setSession(tokens.refreshToken);
      }
    } catch (_) {
      // Best-effort SDK session synchronization
    }

    return tokens;
  }

  @override
  Future<AuthTokens?> refreshToken(String refreshToken) async {
    try {
      final base = SupabaseConstants.url;
      final uri = Uri.parse('$base/auth/v1/token?grant_type=refresh_token');

      final response = await apiClient.post(
        uri,
        headers: {
          'apikey': SupabaseConstants.publishableKey,
          'Content-Type': 'application/json',
          'x-no-auth': 'true',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newTokens = AuthTokens.fromJson(data);

        await secureStorage.saveTokens(
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken.isNotEmpty
              ? newTokens.refreshToken
              : refreshToken,
        );

        try {
          final effectiveRefresh = newTokens.refreshToken.isNotEmpty
              ? newTokens.refreshToken
              : refreshToken;
          await _supabase.client.auth.setSession(effectiveRefresh);
        } catch (_) {}

        return newTokens;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<bool> validateSession(String accessToken) async {
    if (accessToken.trim().isEmpty) return false;

    // 1. Check JWT expiration timestamp locally if token has standard JWT 3-part format
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final normalized = base64Url.normalize(parts[1]);
        final payloadString = utf8.decode(base64Url.decode(normalized));
        final payload = jsonDecode(payloadString);
        if (payload is Map && payload.containsKey('exp')) {
          final expSeconds = payload['exp'] as int;
          final nowSeconds =
              DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (nowSeconds >= expSeconds) {
            // Access token has expired
            return false;
          }
        }
      }
    } catch (_) {
      // If parsing fails, proceed to remote validation
    }

    // 2. Validate token with backend `/auth/v1/user` endpoint
    try {
      final base = SupabaseConstants.url;
      final uri = Uri.parse('$base/auth/v1/user');

      final response = await apiClient.get(
        uri,
        headers: {
          'apikey': SupabaseConstants.publishableKey,
          'Authorization': 'Bearer $accessToken',
          'x-no-auth': 'true',
        },
        requiresAuth: false,
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.logout();
    } catch (_) {}

    try {
      await _supabase.signOut();
    } catch (_) {}

    await secureStorage.clearTokens();
  }

  @override
  Future<UserProfile> fetchUserProfile(String userId, String? email) async {
    try {
      final data = await _supabase.fetchProfile(userId);
      if (data != null) {
        return UserProfile.fromMap(data);
      }
    } catch (_) {}

    return UserProfile(
      id: userId,
      email: email,
      displayName: email?.split('@').first ?? 'Voice Custodian',
      role: 'Custodian',
    );
  }

  @override
  Future<AuthTokens?> getSavedTokens() async {
    final access = await secureStorage.getAccessToken();
    final refresh = await secureStorage.getRefreshToken();
    if (access != null && access.isNotEmpty) {
      return AuthTokens(
        accessToken: access,
        refreshToken: refresh ?? '',
      );
    }
    return null;
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    await secureStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  @override
  Future<void> clearTokens() async {
    await secureStorage.clearTokens();
  }
}
