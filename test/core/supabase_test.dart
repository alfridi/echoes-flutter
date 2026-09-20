import 'package:flutter_test/flutter_test.dart';
import 'package:echoes_flutter/core/constants/supabase_constants.dart';
import 'package:echoes_flutter/core/services/supabase_service.dart';

void main() {
  group('SupabaseConstants', () {
    test('default constants match FLUTTER_IMPLEMENTATION 2.md values', () {
      expect(SupabaseConstants.url, isNotEmpty);
      expect(SupabaseConstants.anonKey, isNotEmpty);
      expect(SupabaseConstants.audioBucket, equals('echoes-audio'));
      expect(SupabaseConstants.recordingsFolder, equals('recordings'));
    });

    test('table names match PostgreSQL schema in FLUTTER_IMPLEMENTATION 2.md', () {
      expect(SupabaseConstants.tableProfiles, equals('profiles'));
      expect(SupabaseConstants.tableLanguages, equals('languages'));
      expect(SupabaseConstants.tableWords, equals('words'));
      expect(SupabaseConstants.tableEchoRecordings, equals('echo_recordings'));
      expect(SupabaseConstants.tableDialectPins, equals('dialect_pins'));
    });

    test('RPC names match PostgreSQL schema', () {
      expect(
        SupabaseConstants.rpcIncrementWordRecordings,
        equals('increment_word_recordings'),
      );
    });
  });

  group('SupabaseService', () {
    test('singleton returns identical instance', () {
      final service1 = SupabaseService();
      final service2 = SupabaseService();
      expect(identical(service1, service2), isTrue);
    });
  });
}
