import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../models/user_profile.dart';
import 'auth_state.dart';

/// Authentication Cubit managing Supabase user sessions, email sign-in,
/// new custodian account registration, and anonymous explorer access.
class AuthCubit extends Cubit<EchoesAuthState> {
  final SupabaseService _supabase;

  AuthCubit({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService(),
        super(AuthInitial());

  /// Checks the current Supabase session on app startup.
  Future<void> checkAuth() async {
    final user = _supabase.currentUser;
    if (user != null) {
      final profile = await _fetchProfile(user.id, user.email);
      emit(Authenticated(profile: profile, isAnonymous: user.isAnonymous));
    } else {
      emit(Unauthenticated());
    }
  }

  /// Signs in an existing custodian with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      final res = await _supabase.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final profile = await _fetchProfile(res.user!.id, res.user!.email);
        emit(Authenticated(profile: profile, isAnonymous: false));
      } else {
        emit(const AuthError('Authentication failed: No user found.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Sign in failed: ${e.toString()}'));
    }
  }

  /// Registers a new voice custodian / Echo Keeper with email, password, and profile metadata.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? nativeDialect,
  }) async {
    try {
      emit(AuthLoading());
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
        // Attempt to sync the profile record in the profiles table
        try {
          await _supabase.upsertProfile({
            'id': user.id,
            'email': user.email,
            'display_name': displayName ?? 'Dialect Custodian',
            'native_dialect': nativeDialect,
            'role': 'Custodian',
          });
        } catch (_) {
          // If RLS or trigger handles it, ignore table upsert failure
        }

        if (res.session != null) {
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

  /// Signs in anonymously so visitors can browse dialects and submit recordings.
  Future<void> signInAnonymously() async {
    try {
      emit(AuthLoading());
      final res = await _supabase.signInAnonymously();
      if (res.user != null) {
        emit(Authenticated(
          profile: UserProfile(
            id: res.user!.id,
            displayName: 'Guest Dialect Explorer',
            role: 'Explorer',
          ),
          isAnonymous: true,
        ));
      } else {
        emit(Unauthenticated());
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Guest access error: ${e.toString()}'));
    }
  }

  /// Dispatches a password recovery email.
  Future<void> resetPassword(String email) async {
    try {
      emit(AuthLoading());
      await _supabase.resetPasswordForEmail(email);
      emit(AuthPasswordResetSent(email));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Password reset failed: ${e.toString()}'));
    }
  }

  /// Signs out the active user session.
  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      await _supabase.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Sign out failed: ${e.toString()}'));
    }
  }

  /// Clears any transient error message.
  void clearError() {
    if (state is AuthError || state is AuthSignUpSuccess || state is AuthPasswordResetSent) {
      emit(Unauthenticated());
    }
  }

  Future<UserProfile> _fetchProfile(String userId, String? email) async {
    try {
      final data = await _supabase.fetchProfile(userId);
      if (data != null) {
        return UserProfile.fromMap(data);
      }
      return UserProfile(
        id: userId,
        email: email,
        displayName: email?.split('@').first ?? 'Voice Custodian',
        role: 'Custodian',
      );
    } catch (_) {
      return UserProfile(
        id: userId,
        email: email,
        displayName: email?.split('@').first ?? 'Voice Custodian',
        role: 'Custodian',
      );
    }
  }
}
