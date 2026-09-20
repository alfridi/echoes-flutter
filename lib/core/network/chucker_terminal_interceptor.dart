import 'dart:convert';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP client wrapper extending [ChuckerHttpClient] that directs all network
/// traffic inspection strictly to the developer terminal/debug console.
///
/// Completely suppresses and disables all Chucker in-app UI (overlay notifications,
/// floating button, screen navigation, routes, drawers).
///
/// Automatically disabled in release mode via [kDebugMode].
class ChuckerTerminalHttpClient extends ChuckerHttpClient {
  /// Creates a [ChuckerTerminalHttpClient] wrapping [innerClient].
  ChuckerTerminalHttpClient(
    this._innerClient, {
    this.enabled = true,
    this.logCallback,
  }) : super(_innerClient) {
    // Ensure all Chucker in-app notification & release UI flags are disabled.
    ChuckerFlutter.showNotification = false;
    ChuckerFlutter.showOnRelease = false;
    ChuckerFlutter.configure(
      showOnRelease: false,
      showNotification: false,
    );
  }

  final http.Client _innerClient;

  /// Whether terminal logging is enabled.
  final bool enabled;

  /// Optional custom log sink (primarily for automated unit testing).
  /// Falls back to [debugPrint] in debug mode.
  final void Function(String message)? logCallback;

  static const String _divider = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  static const JsonEncoder _prettyJsonEncoder = JsonEncoder.withIndent('  ');

  /// Logging is strictly enabled in debug mode.
  bool get _shouldLog => enabled && kDebugMode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_shouldLog) {
      return _innerClient.send(request);
    }

    final requestBody = _extractRequestBody(request);
    _logRequest(request, requestBody);

    final stopwatch = Stopwatch()..start();
    final http.StreamedResponse response;
    try {
      final interceptedRequest = onRequest(request);
      response = await _innerClient.send(interceptedRequest);
    } catch (error) {
      stopwatch.stop();
      _logNetworkException(
        request: request,
        requestBody: requestBody,
        error: error,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    }

    stopwatch.stop();
    final durationMs = stopwatch.elapsedMilliseconds;

    final bytes = await response.stream.toBytes();
    final responseBody = _extractResponseBody(bytes, response.headers);

    if (response.statusCode >= 400) {
      _logHttpError(
        request: request,
        requestBody: requestBody,
        statusCode: response.statusCode,
        durationMs: durationMs,
        responseHeaders: response.headers,
        responseBody: responseBody,
      );
    } else {
      _logResponse(
        request: request,
        statusCode: response.statusCode,
        durationMs: durationMs,
        headers: response.headers,
        responseBody: responseBody,
      );
    }

    final interceptedResponse = onResponse(response);
    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      interceptedResponse.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }

  // ---------------------------------------------------------------------------
  // Terminal Formatting & Output
  // ---------------------------------------------------------------------------

  void _output(String message) {
    if (logCallback != null) {
      logCallback!(message);
    } else {
      debugPrint(message);
    }
  }

  void _logRequest(http.BaseRequest request, String? requestBody) {
    final buffer = StringBuffer();
    buffer.writeln(_divider);
    buffer.writeln('🌐 REQUEST');
    buffer.writeln('${request.method} ${request.url}');

    if (request.url.queryParameters.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('QUERY PARAMETERS:');
      for (final entry in request.url.queryParameters.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }

    buffer.writeln();
    buffer.writeln('HEADERS:');
    if (request.headers.isNotEmpty) {
      for (final entry in request.headers.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    } else {
      buffer.writeln('(none)');
    }

    if (requestBody != null && requestBody.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('BODY:');
      buffer.writeln(requestBody);
    }

    buffer.write(_divider);
    _output(buffer.toString());
  }

  void _logResponse({
    required http.BaseRequest request,
    required int statusCode,
    required int durationMs,
    required Map<String, String> headers,
    required String? responseBody,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(_divider);
    buffer.writeln('✅ RESPONSE');
    buffer.writeln('STATUS: $statusCode');
    buffer.writeln('DURATION: ${durationMs}ms');
    buffer.writeln('URL: ${request.url}');

    buffer.writeln();
    buffer.writeln('HEADERS:');
    if (headers.isNotEmpty) {
      for (final entry in headers.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    } else {
      buffer.writeln('(none)');
    }

    if (responseBody != null && responseBody.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('BODY:');
      buffer.writeln(responseBody);
    }

    buffer.write(_divider);
    _output(buffer.toString());
  }

  void _logHttpError({
    required http.BaseRequest request,
    required String? requestBody,
    required int statusCode,
    required int durationMs,
    required Map<String, String> responseHeaders,
    required String? responseBody,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(_divider);
    buffer.writeln('❌ HTTP ERROR');
    buffer.writeln('STATUS: $statusCode');
    buffer.writeln('DURATION: ${durationMs}ms');
    buffer.writeln('URL: ${request.url}');

    buffer.writeln();
    buffer.writeln('REQUEST HEADERS:');
    if (request.headers.isNotEmpty) {
      for (final entry in request.headers.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    } else {
      buffer.writeln('(none)');
    }

    if (requestBody != null && requestBody.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('REQUEST BODY:');
      buffer.writeln(requestBody);
    }

    buffer.writeln();
    buffer.writeln('RESPONSE HEADERS:');
    if (responseHeaders.isNotEmpty) {
      for (final entry in responseHeaders.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    } else {
      buffer.writeln('(none)');
    }

    if (responseBody != null && responseBody.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('RESPONSE BODY:');
      buffer.writeln(responseBody);
    }

    buffer.write(_divider);
    _output(buffer.toString());
  }

  void _logNetworkException({
    required http.BaseRequest request,
    required String? requestBody,
    required Object error,
    required int durationMs,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(_divider);
    buffer.writeln('❌ NETWORK ERROR');
    buffer.writeln('DURATION: ${durationMs}ms');
    buffer.writeln('URL: ${request.url}');

    buffer.writeln();
    buffer.writeln('REQUEST HEADERS:');
    if (request.headers.isNotEmpty) {
      for (final entry in request.headers.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    } else {
      buffer.writeln('(none)');
    }

    if (requestBody != null && requestBody.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('REQUEST BODY:');
      buffer.writeln(requestBody);
    }

    buffer.writeln();
    buffer.writeln('ERROR:');
    buffer.writeln(error.toString());

    buffer.write(_divider);
    _output(buffer.toString());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String? _formatBody(dynamic body) {
    if (body == null) return null;
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        return _prettyJsonEncoder.convert(decoded);
      } catch (_) {
        return trimmed;
      }
    }
    try {
      return _prettyJsonEncoder.convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  static String? _extractRequestBody(http.BaseRequest request) {
    if (request is http.Request) {
      if (request.body.trim().isEmpty) return null;
      return _formatBody(request.body);
    }
    if (request is http.MultipartRequest) {
      final map = <String, dynamic>{};
      if (request.fields.isNotEmpty) {
        map['fields'] = request.fields;
      }
      if (request.files.isNotEmpty) {
        map['files'] = request.files
            .map((f) => {
                  'field': f.field,
                  'filename': f.filename,
                  'length': f.length,
                  'contentType': f.contentType.toString(),
                })
            .toList();
      }
      return _formatBody(map);
    }
    if (request is http.StreamedRequest) {
      return '[Streamed request body: ${request.contentLength ?? 0} bytes]';
    }
    return null;
  }

  static String? _extractResponseBody(
    List<int> bytes,
    Map<String, String> headers,
  ) {
    if (bytes.isEmpty) return null;
    final contentType =
        headers['content-type'] ?? headers['Content-Type'] ?? '';
    final isBinary = contentType.startsWith('audio/') ||
        contentType.startsWith('image/') ||
        contentType.startsWith('video/') ||
        contentType.contains('octet-stream');
    if (isBinary) {
      return '[Binary data: ${bytes.length} bytes, contentType: $contentType]';
    }
    try {
      final text = utf8.decode(bytes);
      return _formatBody(text);
    } catch (_) {
      return '[Binary / non-UTF8 data: ${bytes.length} bytes]';
    }
  }
}
