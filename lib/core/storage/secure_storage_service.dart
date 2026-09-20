import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage service powered strictly by [FlutterSecureStorage].
///
/// Ensures authentication tokens are stored in platform-level secure enclaves
/// (iOS Keychain and Android Encrypted KeyStore) and NEVER in SharedPreferences,
/// plain text files, or console logs.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String keyAccessToken = 'auth_access_token';
  static const String keyRefreshToken = 'auth_refresh_token';

  /// Creates a [SecureStorageService] with optional injected [FlutterSecureStorage] for testing.
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Stores the OAuth/JWT access token in secure storage.
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: keyAccessToken, value: token);
  }

  /// Retrieves the stored access token, or null if none exists.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: keyAccessToken);
  }

  /// Deletes the access token from secure storage.
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: keyAccessToken);
  }

  /// Stores the OAuth/JWT refresh token in secure storage.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: keyRefreshToken, value: token);
  }

  /// Retrieves the stored refresh token, or null if none exists.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: keyRefreshToken);
  }

  /// Deletes the refresh token from secure storage.
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: keyRefreshToken);
  }

  /// Securely persists both access and refresh tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  /// Clears both access and refresh tokens from secure storage.
  Future<void> clearTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }

  /// Checks whether an access token is currently stored.
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Checks whether a refresh token is currently stored.
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }
}
