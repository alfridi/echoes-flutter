/// Constants for Supabase Backend configuration, database tables, and storage buckets.
/// Derived from FLUTTER_IMPLEMENTATION 2.md.
abstract class SupabaseConstants {
  /// Supabase Project URL provided via compile-time --dart-define or fallback default.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  /// Supabase Anon Public API Key provided via compile-time --dart-define or fallback default.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  );

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
