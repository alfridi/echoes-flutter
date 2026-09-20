import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../di/service_locator.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/language/language_detail_screen.dart';
import '../../screens/map/world_map_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../features/recordings/presentation/views/recording_screen.dart';
import '../../features/recordings/presentation/views/recordings_screen.dart';
import '../../screens/record/record_voice_screen.dart';
import '../../screens/word/word_detail_screen.dart';

/// Stream listener bridging Bloc/Cubit stream notifications to GoRouter's [Listenable].
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter? _instanceAppRouter;

/// Global [GoRouter] instance configured with centralized route protection.
GoRouter get appRouter => _instanceAppRouter ??= createAppRouter();

/// Resets the global [appRouter] instance, useful in tests.
void resetAppRouter() {
  _instanceAppRouter?.dispose();
  _instanceAppRouter = null;
}

/// Factory creating a [GoRouter] with route guards for authenticated vs unauthenticated users.
///
/// Route protection rule: Users can ONLY access the home screen (/world-map, /explore)
/// and other protected features AFTER signing in.
GoRouter createAppRouter({AuthCubit? authCubit}) {
  final effectiveAuthCubit = authCubit ??
      (getIt.isRegistered<AuthCubit>() ? getIt<AuthCubit>() : null);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: effectiveAuthCubit != null
        ? GoRouterRefreshStream(effectiveAuthCubit.stream)
        : null,
    redirect: (context, state) {
      if (effectiveAuthCubit == null) return null;

      final authState = effectiveAuthCubit.state;
      final isAuthenticated = authState.isAuthenticated;
      final isUnauthenticated = authState.isUnauthenticated;

      final matchedPath = state.matchedLocation;
      final isLoginRoute = matchedPath == '/login';
      final isOnboardingRoute = matchedPath == '/onboarding';

      // 1. Authenticated User:
      // If user has a valid active session, bypass Login / Onboarding and enter World Map / Home.
      if (isAuthenticated) {
        if (isLoginRoute || isOnboardingRoute) {
          return '/world-map';
        }
        return null;
      }

      // 2. Unauthenticated User:
      // Only after sign-in can the user get access to the home screen and other archival features.
      // Unauthenticated users are strictly locked out of protected screens and redirected to /login.
      if (isUnauthenticated) {
        if (!isLoginRoute) {
          return '/login';
        }
        return null;
      }

      // 3. Initial / Loading State:
      // Stay on current route or /login while checking credentials on startup.
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
        builder: (context, state) => RecordingScreen(
          wordId: state.uri.queryParameters['wordId'],
          languageId: state.uri.queryParameters['languageId'],
        ),
      ),
      GoRoute(
        path: '/recordings',
        builder: (context, state) => const RecordingsScreen(),
      ),
      GoRoute(
        path: '/legacy-record',
        builder: (context, state) => RecordVoiceScreen(
          wordId: state.uri.queryParameters['wordId'] ?? 'welcome',
          languageId: state.uri.queryParameters['languageId'] ?? 'malayalam',
        ),
      ),
    ],
  );
}
