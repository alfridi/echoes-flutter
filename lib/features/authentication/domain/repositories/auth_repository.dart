import '../../../../models/user_profile.dart';
import '../models/auth_tokens.dart';

/// Contract defining authentication operations for custodian login, session
/// validation, token refresh, and secure sign out.
abstract class AuthRepository {
  /// Authenticates with email and password, returning the access and refresh tokens.
  Future<AuthTokens> login({
    required String email,
    required String password,
  });

  /// Calls the refresh token API endpoint to exchange [refreshToken] for a new [AuthTokens] pair.
  Future<AuthTokens?> refreshToken(String refreshToken);

  /// Validates whether the provided [accessToken] represents an active session.
  Future<bool> validateSession(String accessToken);

  /// Signs out of the backend and invalidates the session.
  Future<void> logout();

  /// Retrieves the user profile associated with the session.
  Future<UserProfile> fetchUserProfile(String userId, String? email);

  /// Reads stored access and refresh tokens from secure storage.
  Future<AuthTokens?> getSavedTokens();

  /// Persists tokens to secure storage.
  Future<void> saveTokens(AuthTokens tokens);

  /// Removes tokens from secure storage.
  Future<void> clearTokens();
}
