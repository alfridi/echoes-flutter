import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../cubits/audio_player/audio_player_cubit.dart';
import '../../cubits/audio_recorder/audio_recorder_cubit.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/explore/explore_cubit.dart';
import '../../repositories/language_repository.dart';
import '../../repositories/recording_repository.dart';
import '../../repositories/word_repository.dart';
import '../network/chucker_terminal_interceptor.dart';
import '../services/supabase_service.dart';

/// Global service locator instance powered by `get_it`.
final GetIt getIt = GetIt.instance;

/// Short alias for [getIt] commonly used across Flutter clean architecture layers.
GetIt get sl => getIt;

/// Configures and registers all application dependencies, repositories,
/// network interceptors (Chucker), and cubits.
Future<void> setupServiceLocator({
  http.Client? customHttpClient,
  SupabaseService? customSupabaseService,
  bool enableChucker = true,
}) async {
  // 1. Configure Chucker to completely disable in-app notifications and release UI
  ChuckerFlutter.showNotification = false;
  ChuckerFlutter.showOnRelease = false;
  ChuckerFlutter.configure(
    showOnRelease: false,
    showNotification: false,
  );

  // 2. HTTP Client with Chucker Terminal Network Logger
  if (!getIt.isRegistered<http.Client>()) {
    final baseClient = customHttpClient ?? http.Client();
    final effectiveClient =
        (enableChucker && (kDebugMode || ChuckerFlutter.showOnRelease))
            ? ChuckerTerminalHttpClient(baseClient)
            : baseClient;
    getIt.registerLazySingleton<http.Client>(() => effectiveClient);
  }

  // 2. Supabase Backend Service
  if (!getIt.isRegistered<SupabaseService>()) {
    getIt.registerLazySingleton<SupabaseService>(
      () => customSupabaseService ?? SupabaseService(),
    );
  }

  // 3. Domain Repositories
  if (!getIt.isRegistered<LanguageRepository>()) {
    getIt.registerLazySingleton<LanguageRepository>(
      () => SupabaseLanguageRepository(supabase: getIt<SupabaseService>()),
    );
  }

  if (!getIt.isRegistered<WordRepository>()) {
    getIt.registerLazySingleton<WordRepository>(
      () => SupabaseWordRepository(supabase: getIt<SupabaseService>()),
    );
  }

  if (!getIt.isRegistered<RecordingRepository>()) {
    getIt.registerLazySingleton<RecordingRepository>(
      () => SupabaseRecordingRepository(supabase: getIt<SupabaseService>()),
    );
  }

  // 4. Cubits (registered as factory for isolated state lifecycles)
  if (!getIt.isRegistered<AuthCubit>()) {
    getIt.registerFactory<AuthCubit>(
      () => AuthCubit(supabase: getIt<SupabaseService>()),
    );
  }

  if (!getIt.isRegistered<AudioPlayerCubit>()) {
    getIt.registerLazySingleton<AudioPlayerCubit>(
      () => AudioPlayerCubit(),
    );
  }

  if (!getIt.isRegistered<AudioRecorderCubit>()) {
    getIt.registerFactory<AudioRecorderCubit>(
      () => AudioRecorderCubit(
        recordingRepository: getIt<RecordingRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<ExploreCubit>()) {
    getIt.registerFactory<ExploreCubit>(
      () => ExploreCubit(
        languageRepository: getIt<LanguageRepository>(),
        wordRepository: getIt<WordRepository>(),
      ),
    );
  }
}

/// Resets all registered services in [getIt]. Useful for unit and widget testing.
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
