import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';

/// Base state for authentication in Echoes Living Dialect Archive.
abstract class EchoesAuthState extends Equatable {
  const EchoesAuthState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class AuthInitial extends EchoesAuthState {}

/// State while an authentication operation (login, signup, guest access, etc.) is in-flight.
class AuthLoading extends EchoesAuthState {}

/// State when a user or guest is successfully authenticated with Supabase.
class Authenticated extends EchoesAuthState {
  final UserProfile profile;
  final bool isAnonymous;

  const Authenticated({
    required this.profile,
    this.isAnonymous = false,
  });

  @override
  List<Object?> get props => [profile, isAnonymous];
}

/// State when no user session is active.
class Unauthenticated extends EchoesAuthState {}

/// State when an authentication operation fails with an error message.
class AuthError extends EchoesAuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when a sign up completes successfully (especially if email verification is required).
class AuthSignUpSuccess extends EchoesAuthState {
  final String message;
  final bool requiresEmailConfirmation;

  const AuthSignUpSuccess({
    required this.message,
    this.requiresEmailConfirmation = false,
  });

  @override
  List<Object?> get props => [message, requiresEmailConfirmation];
}

/// State when a password reset instructions email has been dispatched.
class AuthPasswordResetSent extends EchoesAuthState {
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}
