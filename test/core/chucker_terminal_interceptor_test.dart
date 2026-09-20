import 'dart:convert';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:echoes_flutter/core/network/chucker_terminal_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ChuckerTerminalHttpClient', () {
    test('is an instance of ChuckerHttpClient and http.Client', () {
      final client = ChuckerTerminalHttpClient(http.Client());
      expect(client, isA<ChuckerHttpClient>());
      expect(client, isA<http.Client>());
      client.close();
    });

    test('disables all Chucker in-app UI and notifications upon initialization', () {
      ChuckerTerminalHttpClient(http.Client());
      expect(ChuckerFlutter.showNotification, isFalse);
      expect(ChuckerFlutter.showOnRelease, isFalse);
    });

    test('logs full GET request and response with headers and query parameters to terminal', () async {
      final logs = <String>[];

      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.headers['Authorization'], equals('Bearer test_jwt_token_12345'));

        return http.Response(
          json.encode({'id': '123', 'name': 'John'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ChuckerTerminalHttpClient(
        mockClient,
        logCallback: (msg) => logs.add(msg),
      );

      final response = await client.get(
        Uri.parse('https://example.com/api/profile?user_id=123'),
        headers: {
          'Authorization': 'Bearer test_jwt_token_12345',
          'Accept': 'application/json',
        },
      );

      expect(response.statusCode, equals(200));
      expect(logs.length, equals(2));

      final requestLog = logs[0];
      expect(requestLog, contains('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
      expect(requestLog, contains('🌐 REQUEST'));
      expect(requestLog, contains('GET https://example.com/api/profile?user_id=123'));
      expect(requestLog, contains('QUERY PARAMETERS:'));
      expect(requestLog, contains('user_id: 123'));
      expect(requestLog, contains('HEADERS:'));
      expect(requestLog, contains('Authorization: Bearer test_jwt_token_12345'));
      expect(requestLog, contains('Accept: application/json'));

      final responseLog = logs[1];
      expect(responseLog, contains('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
      expect(responseLog, contains('✅ RESPONSE'));
      expect(responseLog, contains('STATUS: 200'));
      expect(responseLog, contains('DURATION:'));
      expect(responseLog, contains('URL: https://example.com/api/profile?user_id=123'));
      expect(responseLog, contains('HEADERS:'));
      expect(responseLog, contains('content-type: application/json'));
      expect(responseLog, contains('BODY:'));
      expect(responseLog, contains('"id": "123"'));
      expect(responseLog, contains('"name": "John"'));
    });

    test('logs full POST request body and response body', () async {
      final logs = <String>[];

      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        return http.Response(
          json.encode({'status': 'created', 'record_id': 'echo_999'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ChuckerTerminalHttpClient(
        mockClient,
        logCallback: (msg) => logs.add(msg),
      );

      final response = await client.post(
        Uri.parse('https://example.com/api/echoes'),
        headers: {
          'Authorization': 'Bearer secret_access_token_xyz',
          'Content-Type': 'application/json',
        },
        body: json.encode({'word_id': 'welcome', 'language_id': 'malayalam'}),
      );

      expect(response.statusCode, equals(201));
      expect(logs.length, equals(2));

      final requestLog = logs[0];
      expect(requestLog, contains('🌐 REQUEST'));
      expect(requestLog, contains('POST https://example.com/api/echoes'));
      expect(requestLog, contains('Authorization: Bearer secret_access_token_xyz'));
      expect(requestLog, contains('BODY:'));
      expect(requestLog, contains('"word_id": "welcome"'));
      expect(requestLog, contains('"language_id": "malayalam"'));

      final responseLog = logs[1];
      expect(responseLog, contains('✅ RESPONSE'));
      expect(responseLog, contains('STATUS: 201'));
      expect(responseLog, contains('"status": "created"'));
      expect(responseLog, contains('"record_id": "echo_999"'));
    });

    test('logs full HTTP ERROR (401, 403, 400, 500) with request headers, body, and error response body', () async {
      final logs = <String>[];

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'code': 'PGRST301', 'message': 'JWT expired'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ChuckerTerminalHttpClient(
        mockClient,
        logCallback: (msg) => logs.add(msg),
      );

      final response = await client.post(
        Uri.parse('https://example.com/rest/v1/profiles'),
        headers: {
          'Authorization': 'Bearer expired_token_abc',
          'apikey': 'anon_key_123',
          'Content-Type': 'application/json',
        },
        body: json.encode({'username': 'custodian'}),
      );

      expect(response.statusCode, equals(401));
      expect(logs.length, equals(2));

      final errorLog = logs[1];
      expect(errorLog, contains('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
      expect(errorLog, contains('❌ HTTP ERROR'));
      expect(errorLog, contains('STATUS: 401'));
      expect(errorLog, contains('URL: https://example.com/rest/v1/profiles'));
      expect(errorLog, contains('REQUEST HEADERS:'));
      expect(errorLog, contains('Authorization: Bearer expired_token_abc'));
      expect(errorLog, contains('apikey: anon_key_123'));
      expect(errorLog, contains('REQUEST BODY:'));
      expect(errorLog, contains('"username": "custodian"'));
      expect(errorLog, contains('RESPONSE HEADERS:'));
      expect(errorLog, contains('content-type: application/json'));
      expect(errorLog, contains('RESPONSE BODY:'));
      expect(errorLog, contains('"code": "PGRST301"'));
      expect(errorLog, contains('"message": "JWT expired"'));
    });

    test('logs NETWORK ERROR and rethrows when innerClient throws an exception', () async {
      final logs = <String>[];

      final mockClient = MockClient((request) async {
        throw http.ClientException('Failed to connect to host');
      });

      final client = ChuckerTerminalHttpClient(
        mockClient,
        logCallback: (msg) => logs.add(msg),
      );

      await expectLater(
        client.get(
          Uri.parse('https://example.com/api/offline'),
          headers: {'Authorization': 'Bearer token'},
        ),
        throwsA(isA<http.ClientException>()),
      );

      expect(logs.length, equals(2));
      expect(logs[0], contains('🌐 REQUEST'));

      final networkErrorLog = logs[1];
      expect(networkErrorLog, contains('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
      expect(networkErrorLog, contains('❌ NETWORK ERROR'));
      expect(networkErrorLog, contains('URL: https://example.com/api/offline'));
      expect(networkErrorLog, contains('ERROR:'));
      expect(networkErrorLog, contains('Failed to connect to host'));
    });

    test('does not output logs when enabled is false (release mode emulation)', () async {
      final logs = <String>[];

      final mockClient = MockClient((request) async {
        return http.Response('{"status": "ok"}', 200);
      });

      final client = ChuckerTerminalHttpClient(
        mockClient,
        enabled: false,
        logCallback: (msg) => logs.add(msg),
      );

      final response = await client.get(Uri.parse('https://example.com/api/test'));
      expect(response.statusCode, equals(200));
      expect(logs, isEmpty);
    });

    test('intercepts Supabase Postgrest queries and logs traffic', () async {
      final logs = <String>[];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/rest/v1/languages')) {
          return http.Response(
            json.encode([
              {'id': 'malayalam', 'name': 'Malayalam', 'code': 'ml'},
              {'id': 'tamil', 'name': 'Tamil', 'code': 'ta'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ChuckerTerminalHttpClient(
        mockClient,
        logCallback: (msg) => logs.add(msg),
      );

      final response = await client.get(
        Uri.parse('https://xyz.supabase.co/rest/v1/languages?select=*&order=name.asc'),
        headers: {
          'apikey': 'sb_publishable_key',
          'Authorization': 'Bearer sb_publishable_key',
        },
      );

      expect(response.statusCode, equals(200));
      expect(logs.length, equals(2));

      expect(logs[0], contains('🌐 REQUEST'));
      expect(logs[0], contains('https://xyz.supabase.co/rest/v1/languages?select=*&order=name.asc'));
      expect(logs[0], contains('QUERY PARAMETERS:'));
      expect(logs[0], contains('select: *'));
      expect(logs[0], contains('order: name.asc'));
      expect(logs[0], contains('apikey: sb_publishable_key'));

      expect(logs[1], contains('✅ RESPONSE'));
      expect(logs[1], contains('STATUS: 200'));
      expect(logs[1], contains('"id": "malayalam"'));
    });
  });
}
