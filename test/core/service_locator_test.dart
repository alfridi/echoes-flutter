import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:echoes_flutter/core/di/service_locator.dart';
import 'package:echoes_flutter/core/services/supabase_service.dart';
import 'package:echoes_flutter/cubits/auth/auth_cubit.dart';
import 'package:echoes_flutter/repositories/language_repository.dart';
import 'package:echoes_flutter/repositories/recording_repository.dart';
import 'package:echoes_flutter/repositories/word_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  setUp(() async {
    await resetServiceLocator();
  });

  tearDown(() async {
    await resetServiceLocator();
  });

  group('Service Locator (get_it) & Flutter Chucker Integration', () {
    test('sl is an alias to getIt', () {
      expect(identical(sl, getIt), isTrue);
    });

    test('registers http.Client wrapped with ChuckerHttpClient when enabled', () async {
      await setupServiceLocator(enableChucker: true);

      expect(getIt.isRegistered<http.Client>(), isTrue);
      final client = getIt<http.Client>();
      expect(client, isA<ChuckerHttpClient>());
    });

    test('registers standard http.Client when Chucker is disabled', () async {
      await setupServiceLocator(enableChucker: false);

      expect(getIt.isRegistered<http.Client>(), isTrue);
      final client = getIt<http.Client>();
      expect(client, isNot(isA<ChuckerHttpClient>()));
      expect(client, isA<http.Client>());
    });

    test('registers custom http.Client when provided', () async {
      final customClient = http.Client();
      await setupServiceLocator(
        customHttpClient: customClient,
        enableChucker: false,
      );

      expect(getIt<http.Client>(), same(customClient));
    });

    test('registers SupabaseService as lazy singleton', () async {
      await setupServiceLocator(enableChucker: false);

      expect(getIt.isRegistered<SupabaseService>(), isTrue);
      final service1 = getIt<SupabaseService>();
      final service2 = getIt<SupabaseService>();
      expect(identical(service1, service2), isTrue);
    });

    test('registers custom SupabaseService when injected', () async {
      final customService = SupabaseService();
      await setupServiceLocator(
        customSupabaseService: customService,
        enableChucker: false,
      );

      expect(getIt<SupabaseService>(), same(customService));
    });

    test('registers LanguageRepository, WordRepository, RecordingRepository', () async {
      await setupServiceLocator(enableChucker: false);

      expect(getIt.isRegistered<LanguageRepository>(), isTrue);
      expect(getIt<LanguageRepository>(), isA<SupabaseLanguageRepository>());

      expect(getIt.isRegistered<WordRepository>(), isTrue);
      expect(getIt<WordRepository>(), isA<SupabaseWordRepository>());

      expect(getIt.isRegistered<RecordingRepository>(), isTrue);
      expect(getIt<RecordingRepository>(), isA<SupabaseRecordingRepository>());
    });

    test('registers AuthCubit as factory producing distinct instances', () async {
      await setupServiceLocator(enableChucker: false);

      expect(getIt.isRegistered<AuthCubit>(), isTrue);
      final cubit1 = getIt<AuthCubit>();
      final cubit2 = getIt<AuthCubit>();

      expect(cubit1, isA<AuthCubit>());
      expect(cubit2, isA<AuthCubit>());
      expect(identical(cubit1, cubit2), isFalse);

      await cubit1.close();
      await cubit2.close();
    });

    test('resetServiceLocator clears all registrations', () async {
      await setupServiceLocator(enableChucker: false);
      expect(getIt.isRegistered<LanguageRepository>(), isTrue);

      await resetServiceLocator();

      expect(getIt.isRegistered<http.Client>(), isFalse);
      expect(getIt.isRegistered<SupabaseService>(), isFalse);
      expect(getIt.isRegistered<LanguageRepository>(), isFalse);
      expect(getIt.isRegistered<WordRepository>(), isFalse);
      expect(getIt.isRegistered<RecordingRepository>(), isFalse);
      expect(getIt.isRegistered<AuthCubit>(), isFalse);
    });
  });
}
