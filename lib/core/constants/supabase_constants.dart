import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Constants for Supabase Backend configuration, database tables, and storage buckets.
/// Derived from FLUTTER_IMPLEMENTATION 2.md.
abstract class SupabaseConstants {
  /// Supabase Project URL loaded from .env (dotenv) or compile-time --dart-define with fallback.
  static String get url {
    String rawUrl = '';
    if (dotenv.isInitialized) {
      rawUrl = dotenv.maybeGet('SUPABASE_URL') ?? '';
    }
    if (rawUrl.isEmpty) {
      rawUrl = const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://xyzcompany.supabase.co',
      );
    }
    return _sanitizeUrl(rawUrl);
  }

  /// Supabase Publishable Key loaded from .env (dotenv) or compile-time --dart-define.
  /// Supports both SUPABASE_PUBLISHABLE_KEY and SUPABASE_ANON_KEY.
  static String get publishableKey {
    if (dotenv.isInitialized) {
      final key = dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ??
          dotenv.maybeGet('SUPABASE_ANON_KEY');
      if (key != null && key.isNotEmpty) {
        return key.trim();
      }
    }
    const envPublishable =
        String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (envPublishable.isNotEmpty) {
      return envPublishable;
    }
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    );
  }

  /// Supabase Anon Public API Key provided as an alias for [publishableKey].
  static String get anonKey => publishableKey;

  /// Helper to sanitize Supabase URL (strips trailing slashes and /rest/v1 if included).
  static String _sanitizeUrl(String url) {
    var sanitized = url.trim();
    if (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    if (sanitized.endsWith('/rest/v1')) {
      sanitized = sanitized.substring(0, sanitized.length - '/rest/v1'.length);
    }
    return sanitized;
  }

  /// Supabase Storage bucket dedicated to lossless archival audio recordings (.m4a / AAC).
  static const String audioBucket = 'echoes-audio';

  /// Storage subfolder prefix for audio recordings.
  static const String recordingsFolder = 'recordings';

  // ---------------------------------------------------------------------------
  // Database Tables
  // ---------------------------------------------------------------------------

  /// Profiles table extending Supabase auth.users.
  static const String tableProfiles = 'profiles';

  /// Dialect languages catalog table.
  static const String tableLanguages = 'languages';

  /// Preserved vocabulary and dialect phrases table.
  static const String tableWords = 'words';

  /// Community and custodian voice recordings table.
  static const String tableEchoRecordings = 'echo_recordings';

  /// Dialect map pins and geo-coordinates table.
  static const String tableDialectPins = 'dialect_pins';

  // ---------------------------------------------------------------------------
  // Database Stored Procedures (RPC)
  // ---------------------------------------------------------------------------

  /// RPC function to atomically increment the recording counter for a word.
  static const String rpcIncrementWordRecordings = 'increment_word_recordings';
}
