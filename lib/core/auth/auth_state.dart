import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';

/// Supported authentication statuses.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  signUpSuccess,
  resetSent,
}

/// Centralized base state for authentication in Echoes.
abstract class EchoesAuthState extends Equatable {
  const EchoesAuthState();

  /// High-level authentication status enum.
  AuthStatus get status;

  bool get isInitial => status == AuthStatus.initial;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class AuthInitial extends EchoesAuthState {
  const AuthInitial();

  @override
  AuthStatus get status => AuthStatus.initial;
}

/// State while an authentication operation (login, token refresh, startup check) is in flight.
class AuthLoading extends EchoesAuthState {
  const AuthLoading();

  @override
  AuthStatus get status => AuthStatus.loading;
}

/// State when a user or guest is successfully authenticated with verified credentials.
class Authenticated extends EchoesAuthState {
  final UserProfile profile;
  final bool isAnonymous;

  const Authenticated({
    required this.profile,
    this.isAnonymous = false,
  });

  @override
  AuthStatus get status => AuthStatus.authenticated;

  @override
  List<Object?> get props => [profile, isAnonymous];
}

/// State when no active, valid authentication session exists.
class Unauthenticated extends EchoesAuthState {
  const Unauthenticated();

  @override
  AuthStatus get status => AuthStatus.unauthenticated;
}

/// State when an authentication operation fails with an error message.
class AuthError extends EchoesAuthState {
  final String message;

  const AuthError(this.message);

  @override
  AuthStatus get status => AuthStatus.error;

  @override
  List<Object?> get props => [message];
}

/// State when sign up completes successfully.
class AuthSignUpSuccess extends EchoesAuthState {
  final String message;
  final bool requiresEmailConfirmation;

  const AuthSignUpSuccess({
    required this.message,
    this.requiresEmailConfirmation = false,
  });

  @override
  AuthStatus get status => AuthStatus.signUpSuccess;

  @override
  List<Object?> get props => [message, requiresEmailConfirmation];
}

/// State when password recovery email has been sent.
class AuthPasswordResetSent extends EchoesAuthState {
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  AuthStatus get status => AuthStatus.resetSent;

  @override
  List<Object?> get props => [email];
}
