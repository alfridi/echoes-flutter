import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../models/user_profile.dart';
import '../di/service_locator.dart';
import '../network/api_client.dart';
import '../services/supabase_service.dart';
import '../storage/secure_storage_service.dart';
import 'auth_state.dart';

/// Centralized authentication controller / cubit managing login flow,
/// secure token storage, app startup session validation, and logout.
class AuthController extends Cubit<EchoesAuthState> {
  final SupabaseService _supabase;
  final SecureStorageService _secureStorage;
  final ApiClient? _apiClient;
  final AuthRepository? _authRepository;

  AuthController({
    SupabaseService? supabase,
    SecureStorageService? secureStorage,
    ApiClient? apiClient,
    AuthRepository? authRepository,
  })  : _supabase = supabase ??
            (getIt.isRegistered<SupabaseService>()
                ? getIt<SupabaseService>()
                : SupabaseService()),
        _secureStorage = secureStorage ??
            (getIt.isRegistered<SecureStorageService>()
                ? getIt<SecureStorageService>()
                : SecureStorageService()),
        _apiClient = apiClient ??
            (getIt.isRegistered<ApiClient>() ? getIt<ApiClient>() : null),
        _authRepository = authRepository ??
            (getIt.isRegistered<AuthRepository>()
                ? getIt<AuthRepository>()
                : null),
        super(const AuthInitial()) {
    // Listen for unrecoverable 401 refresh token failures from the network layer
    _apiClient?.onAuthFailed = _handleAuthFailed;
  }

  void _handleAuthFailed() {
    if (state is! Unauthenticated) {
      emit(const Unauthenticated());
    }
  }

  /// App Startup Flow:
  /// 1. Checks FlutterSecureStorage for stored access token.
  /// 2. If no token exists -> Unauthenticated -> Login.
  /// 3. If access token exists -> Validates session.
  ///    - Valid -> Authenticated -> Dashboard.
  ///    - Invalid -> Tries token refresh with stored refresh token.
  ///      - Refresh Success -> Stores new tokens -> Authenticated -> Dashboard.
  ///      - Refresh Failure -> Clears tokens -> Unauthenticated -> Login.
  Future<void> checkAuth() async {
    try {
      emit(const AuthLoading());

      // 1. Check secure storage for access token
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        emit(const Unauthenticated());
        return;
      }

      // 2. Validate session
      bool isValid = false;
      if (_authRepository != null) {
        isValid = await _authRepository.validateSession(accessToken);
      } else {
        // Fallback validation via Supabase currentUser / session
        isValid = _supabase.currentUser != null;
      }

      if (isValid) {
        final user = _supabase.currentUser;
        final profile = await _fetchProfile(
          user?.id ?? 'custodian',
          user?.email,
        );
        emit(Authenticated(
          profile: profile,
          isAnonymous: user?.isAnonymous ?? false,
        ));
        return;
      }

      // 3. If access token was invalid, try refresh
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _secureStorage.clearTokens();
        emit(const Unauthenticated());
        return;
      }

      if (_authRepository != null) {
        final newTokens = await _authRepository.refreshToken(refreshToken);
        if (newTokens != null && newTokens.accessToken.isNotEmpty) {
          final user = _supabase.currentUser;
          final profile = await _fetchProfile(
            user?.id ?? 'custodian',
            user?.email,
          );
          emit(Authenticated(
            profile: profile,
            isAnonymous: user?.isAnonymous ?? false,
          ));
          return;
        }
      }

      // Refresh failed or not possible
      await _secureStorage.clearTokens();
      emit(const Unauthenticated());
    } catch (_) {
      await _secureStorage.clearTokens();
      emit(const Unauthenticated());
    }
  }

  /// Login Flow:
  /// Calls authentication API with email and password, receives access and
  /// refresh tokens, stores them securely using [FlutterSecureStorage], and updates
  /// state to [Authenticated].
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(const AuthLoading());

      if (_authRepository != null) {
        // Authenticate via AuthRepository
        final tokens = await _authRepository.login(
          email: email,
          password: password,
        );
        await _secureStorage.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
      } else {
        // Call existing Supabase Auth API
        final res = await _supabase.signInWithPassword(
          email: email,
          password: password,
        );

        if (res.session != null) {
          await _secureStorage.saveTokens(
            accessToken: res.session!.accessToken,
            refreshToken: res.session!.refreshToken ?? '',
          );
        }
      }

      final user = _supabase.currentUser;
      final profile = await _fetchProfile(user?.id ?? 'custodian', email);
      emit(Authenticated(profile: profile, isAnonymous: false));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(
        e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
      ));
    }
  }

  /// Registers a new voice custodian with email, password, and metadata.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? nativeDialect,
  }) async {
    try {
      emit(const AuthLoading());
      final res = await _supabase.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName ?? 'Dialect Custodian',
          if (nativeDialect != null && nativeDialect.isNotEmpty)
            'native_dialect': nativeDialect,
        },
      );

      final user = res.user;
      if (user != null) {
        try {
          await _supabase.upsertProfile({
            'id': user.id,
            'email': user.email,
            'display_name': displayName ?? 'Dialect Custodian',
            'native_dialect': nativeDialect,
            'role': 'Custodian',
          });
        } catch (_) {}

        if (res.session != null) {
          await _secureStorage.saveTokens(
            accessToken: res.session!.accessToken,
            refreshToken: res.session!.refreshToken ?? '',
          );
          final profile = await _fetchProfile(user.id, user.email);
          emit(Authenticated(profile: profile, isAnonymous: false));
        } else {
          emit(const AuthSignUpSuccess(
            message:
                'Registration initiated! Please check your email inbox to verify your custodian account before signing in.',
            requiresEmailConfirmation: true,
          ));
        }
      } else {
        emit(const AuthError('Account creation could not be completed.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  /// Signs in anonymously so visitors can browse dialects.
  Future<void> signInAnonymously() async {
    try {
      emit(const AuthLoading());
      final res = await _supabase.signInAnonymously();
      if (res.user != null) {
        if (res.session != null) {
          await _secureStorage.saveTokens(
            accessToken: res.session!.accessToken,
            refreshToken: res.session!.refreshToken ?? '',
          );
        }
        emit(Authenticated(
          profile: UserProfile(
            id: res.user!.id,
            displayName: 'Guest Dialect Explorer',
            role: 'Explorer',
          ),
          isAnonymous: true,
        ));
      } else {
        emit(const Unauthenticated());
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Guest access error: ${e.toString()}'));
    }
  }

  /// Dispatches password recovery email.
  Future<void> resetPassword(String email) async {
    try {
      emit(const AuthLoading());
      await _supabase.resetPasswordForEmail(email);
      emit(AuthPasswordResetSent(email));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Password reset failed: ${e.toString()}'));
    }
  }

  /// Centralized logout method:
  /// 1. Calls logout API if one exists.
  /// 2. Deletes access and refresh tokens from FlutterSecureStorage.
  /// 3. Clears authentication state to Unauthenticated.
  Future<void> signOut() async {
    try {
      emit(const AuthLoading());
      if (_authRepository != null) {
        await _authRepository.logout();
      } else {
        try {
          await _apiClient?.logout();
        } catch (_) {}
        try {
          await _supabase.signOut();
        } catch (_) {}
        await _secureStorage.clearTokens();
      }
    } catch (_) {
      await _secureStorage.clearTokens();
    } finally {
      emit(const Unauthenticated());
    }
  }

  /// Alias for [signOut] matching clean architecture naming.
  Future<void> logout() => signOut();

  /// Clears any transient error or notification message.
  void clearError() {
    if (state is AuthError ||
        state is AuthSignUpSuccess ||
        state is AuthPasswordResetSent) {
      emit(const Unauthenticated());
    }
  }

  Future<UserProfile> _fetchProfile(String userId, String? email) async {
    if (_authRepository != null) {
      return await _authRepository.fetchUserProfile(userId, email);
    }
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
}
