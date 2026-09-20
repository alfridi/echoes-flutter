import 'package:equatable/equatable.dart';

/// Value object representing authentication tokens.
///
/// Supports parsing standard OAuth2 (`access_token` / `refresh_token`)
/// as well as REST framework token formats (`access` / `refresh`).
class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  /// Creates an [AuthTokens] instance from a JSON payload.
  /// Handles both:
  /// ```json
  /// { "access": "...", "refresh": "..." }
  /// ```
  /// and
  /// ```json
  /// { "access_token": "...", "refresh_token": "..." }
  /// ```
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final access = (json['access'] ?? json['access_token'] ?? '').toString();
    final refresh = (json['refresh'] ?? json['refresh_token'] ?? '').toString();

    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken];

  /// Strictly redacts sensitive token strings so they are never printed in console or debug logs.
  @override
  String toString() =>
      'AuthTokens(accessToken: [REDACTED], refreshToken: [REDACTED])';
}
