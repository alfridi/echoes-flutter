import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/language/language_detail_screen.dart';
import '../../screens/map/world_map_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/record/record_voice_screen.dart';
import '../../screens/word/word_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/world-map',
      builder: (context, state) => const WorldMapScreen(),
    ),
    GoRoute(
      path: '/explore',
      redirect: (context, state) => '/world-map',
    ),
    GoRoute(
      path: '/language/:id',
      builder: (context, state) => LanguageDetailScreen(
        languageId: state.pathParameters['id'] ?? 'malayalam',
      ),
    ),
    GoRoute(
      path: '/word/:id',
      builder: (context, state) => WordDetailScreen(
        wordId: state.pathParameters['id'] ?? 'welcome',
      ),
    ),
    GoRoute(
      path: '/record',
      builder: (context, state) => RecordVoiceScreen(
        wordId: state.uri.queryParameters['wordId'] ?? 'welcome',
        languageId: state.uri.queryParameters['languageId'] ?? 'malayalam',
      ),
    ),
  ],
);
