import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'cubits/audio_player/audio_player_cubit.dart';
import 'cubits/audio_recorder/audio_recorder_cubit.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/explore/explore_cubit.dart';
import 'features/recordings/domain/repositories/recording_repository.dart'
    as feature_rec;
import 'repositories/language_repository.dart';
import 'repositories/recording_repository.dart';
import 'repositories/word_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Notice: .env file loading skipped or not present: $e');
  }

  // 1. Initialize Dependency Injection (get_it) & Flutter Chucker inspector
  await setupServiceLocator();

  // 2. Initialize Supabase Backend with Chucker-intercepted HTTP client
  try {
    await SupabaseService.initialize(
      httpClient: getIt<http.Client>(),
    );
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  runApp(const EchoesApp());
}

class EchoesApp extends StatelessWidget {
  final LanguageRepository? languageRepository;
  final WordRepository? wordRepository;
  final RecordingRepository? recordingRepository;
  final AuthCubit? authCubit;
  final AudioPlayerCubit? audioPlayerCubit;
  final AudioRecorderCubit? audioRecorderCubit;
  final ExploreCubit? exploreCubit;

  const EchoesApp({
    super.key,
    this.languageRepository,
    this.wordRepository,
    this.recordingRepository,
    this.authCubit,
    this.audioPlayerCubit,
    this.audioRecorderCubit,
    this.exploreCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LanguageRepository>.value(
          value: languageRepository ?? getIt<LanguageRepository>(),
        ),
        RepositoryProvider<WordRepository>.value(
          value: wordRepository ?? getIt<WordRepository>(),
        ),
        RepositoryProvider<RecordingRepository>.value(
          value: recordingRepository ?? getIt<RecordingRepository>(),
        ),
        RepositoryProvider<feature_rec.RecordingRepository>.value(
          value: getIt<feature_rec.RecordingRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (ctx) => (authCubit ?? getIt<AuthCubit>())..checkAuth(),
          ),
          BlocProvider<AudioPlayerCubit>(
            create: (ctx) => audioPlayerCubit ?? getIt<AudioPlayerCubit>(),
          ),
          BlocProvider<AudioRecorderCubit>(
            create: (ctx) => audioRecorderCubit ?? getIt<AudioRecorderCubit>(),
          ),
          BlocProvider<ExploreCubit>(
            create: (ctx) =>
                (exploreCubit ?? getIt<ExploreCubit>())..loadAtlasData(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Echoes — Dialect Archive',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
