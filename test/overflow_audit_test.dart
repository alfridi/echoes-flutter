import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echoes_flutter/screens/onboarding/onboarding_screen.dart';
import 'package:echoes_flutter/screens/map/widgets/featured_echo_card.dart';
import 'package:echoes_flutter/screens/language/language_detail_screen.dart';
import 'package:echoes_flutter/screens/word/word_detail_screen.dart';
import 'package:echoes_flutter/screens/record/record_voice_screen.dart';
import 'package:echoes_flutter/screens/auth/login_screen.dart';
import 'package:echoes_flutter/screens/map/world_map_screen.dart';
import 'package:echoes_flutter/models/word_entry.dart';
import 'package:echoes_flutter/models/language.dart';
import 'package:echoes_flutter/models/map_pin.dart';
import 'package:echoes_flutter/models/echo_recording.dart';
import 'package:echoes_flutter/cubits/audio_player/audio_player_cubit.dart';
import 'package:echoes_flutter/cubits/audio_recorder/audio_recorder_cubit.dart';
import 'package:echoes_flutter/cubits/auth/auth_cubit.dart';
import 'package:echoes_flutter/cubits/explore/explore_cubit.dart';
import 'package:echoes_flutter/repositories/language_repository.dart';
import 'package:echoes_flutter/repositories/word_repository.dart';
import 'package:echoes_flutter/repositories/recording_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MockLanguageRepo implements LanguageRepository {
  final Language lang;
  MockLanguageRepo(this.lang);
  @override
  Future<List<Language>> getLanguages() async => [lang];
  @override
  Future<Language> getLanguageById(String id) async => lang;
  @override
  Future<List<DialectPinModel>> getDialectPins() async => [];
}

class MockWordRepo implements WordRepository {
  final WordEntry word;
  MockWordRepo(this.word);
  @override
  Future<List<WordEntry>> getWordsForLanguage(String languageId) async => [word];
  @override
  Future<WordEntry> getWordDetail(String id) async => word;
  @override
  Future<WordEntry?> getFeaturedWordOfTheDay() async => word;
}

class MockRecordingRepo implements RecordingRepository {
  @override
  Future<List<EchoRecording>> getRecordingsForWord(String wordId) async => [
    EchoRecording(
      id: 'rec-1',
      wordId: wordId,
      languageId: 'malayalam',
      audioUrl: 'https://example.com/audio.m4a',
      duration: const Duration(seconds: 3),
      contributorName: 'Professor A. R. Raja Raja Varma',
      contributorAvatarUrl: '',
      accentTerritory: 'Central Travancore Vernacular Accent',
      acousticFidelity: '48 kHz Studio Master Lossless',
      upvotesCount: 42,
      createdAt: DateTime(2026, 3, 15),
    ),
  ];

  @override
  Future<EchoRecording> uploadAndCreateRecording({
    required File audioFile,
    required String wordId,
    required String languageId,
    required Duration duration,
    required String accentTerritory,
    required String contributorName,
    required String contributorAvatarUrl,
  }) async {
    return EchoRecording(
      id: 'rec-new',
      wordId: wordId,
      languageId: languageId,
      audioUrl: 'https://example.com/uploaded.m4a',
      duration: duration,
      contributorName: contributorName,
      contributorAvatarUrl: contributorAvatarUrl,
      accentTerritory: accentTerritory,
      acousticFidelity: 'Pristine',
      upvotesCount: 0,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  final sampleWord = WordEntry(
    id: 'welcome',
    languageId: 'malayalam',
    englishWord: 'Welcome',
    nativeScript: 'സ്വാഗതം',
    transliteration: 'swagatham',
    phoneticIpa: '/sʋaːɡɐt̪ɐm/',
    category: 'Greetings',
    culturalEtymology: 'Traditional invocation of goodwill and hospitality across southern Kerala.',
    originTerritory: 'Kerala, South India',
    availableRecordingsCount: 14,
    sampleAudioUrl: 'https://example.com/audio.m4a',
    duration: const Duration(seconds: 3),
    contributorName: 'Dr. Evelyn Reed (Oxford Phonetics)',
    contributorAvatarUrl: '',
  );

  final sampleLanguage = Language(
    id: 'malayalam',
    name: 'Malayalam Dialect Group',
    nativeScript: 'മലയാളം (Kēraḷaṁ)',
    isoCode: 'mal',
    branch: 'Southern Dravidian',
    region: 'Kerala · South India',
    countryEmoji: '🇮🇳',
    summary: 'A melodious language.',
    preservedPeopleCount: 128,
    verifiedAudioCount: 342,
    contributorAvatarUrls: const [],
  );

  final mockRecRepo = MockRecordingRepo();
  final mockLangRepo = MockLanguageRepo(sampleLanguage);
  final mockWordRepo = MockWordRepo(sampleWord);

  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains('RenderFlex overflowed')) {
        print('\n>>> RENDERFLEX OVERFLOW: $msg');
        final firstLine = details.summary.toString();
        print('    Summary: $firstLine');
        if (details.context != null) {
          print('    Context: ${details.context}');
        }
      }
    };
  });

  testWidgets('Find all RenderFlex overflows across all screens', (tester) async {
    final widths = [360.0, 375.0, 390.0, 393.0, 412.0];

    for (final width in widths) {
      print('\n--- TESTING WIDTH: $width ---');
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1.0;

      // 1. OnboardingScreen
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const OnboardingScreen()),
              GoRoute(path: '/world-map', builder: (_, _) => const SizedBox()),
              GoRoute(path: '/login', builder: (_, _) => const SizedBox()),
            ],
          ),
        ),
      );
      await tester.pump();

      // 2. FeaturedEchoCard
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocProvider(
                create: (_) => AudioPlayerCubit(),
                child: FeaturedEchoCard(
                  word: sampleWord,
                  language: sampleLanguage,
                  onDetailsTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 3. LanguageDetailScreen
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<LanguageRepository>.value(value: mockLangRepo),
            RepositoryProvider<WordRepository>.value(value: mockWordRepo),
          ],
          child: BlocProvider(
            create: (_) => AudioPlayerCubit(),
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(path: '/', builder: (_, _) => const LanguageDetailScreen(languageId: 'malayalam')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 4. WordDetailScreen
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RecordingRepository>.value(value: mockRecRepo),
            RepositoryProvider<WordRepository>.value(value: mockWordRepo),
          ],
          child: BlocProvider(
            create: (_) => AudioPlayerCubit(),
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(path: '/', builder: (_, _) => const WordDetailScreen(wordId: 'welcome')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 5. LoginScreen
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => AuthCubit(),
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const LoginScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // 6. RecordVoiceScreen
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AudioRecorderCubit(recordingRepository: mockRecRepo)),
            BlocProvider(create: (_) => AudioPlayerCubit()),
            BlocProvider(create: (_) => AuthCubit()),
          ],
          child: RepositoryProvider<WordRepository>.value(
            value: mockWordRepo,
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(path: '/', builder: (_, _) => const RecordVoiceScreen(wordId: 'welcome', languageId: 'malayalam')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 7. WorldMapScreen
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<LanguageRepository>.value(value: mockLangRepo),
            RepositoryProvider<WordRepository>.value(value: mockWordRepo),
            RepositoryProvider<RecordingRepository>.value(value: mockRecRepo),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => AuthCubit()),
              BlocProvider(create: (_) => AudioPlayerCubit()),
              BlocProvider(create: (_) => ExploreCubit(
                languageRepository: mockLangRepo,
                wordRepository: mockWordRepo,
              )),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(path: '/', builder: (_, _) => const WorldMapScreen()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }
  });
}
