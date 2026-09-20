import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

/// Centralized service layer encapsulating Supabase client operations,
/// authentication helpers, and archival audio storage upload pipelines.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  /// Default singleton factory, allowing optional injection of [SupabaseClient] for testing.
  factory SupabaseService({SupabaseClient? client}) {
    if (client != null) {
      return SupabaseService._withClient(client);
    }
    return _instance;
  }

  SupabaseService._internal() : _customClient = null;
  SupabaseService._withClient(SupabaseClient client) : _customClient = client;

  final SupabaseClient? _customClient;

  /// Returns the underlying [SupabaseClient].
  /// Uses the injected client or falls back to [Supabase.instance.client].
  SupabaseClient get client => _customClient ?? Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Supabase Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the Supabase SDK with application configuration.
  /// Typically called in `main()` before `runApp()`.
  static Future<Supabase> initialize({
    String? url,
    String? anonKey,
    bool? debug,
  }) async {
    return await Supabase.initialize(
      url: url ?? SupabaseConstants.url,
      // ignore: deprecated_member_use
      anonKey: anonKey ?? SupabaseConstants.anonKey,
      debug: debug ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // Authentication Helpers
  // ---------------------------------------------------------------------------

  /// Current authenticated user session (guest explorer or custodian), if any.
  User? get currentUser => client.auth.currentUser;

  /// Current active auth session details, if any.
  Session? get currentSession => client.auth.currentSession;

  /// Stream of Supabase auth state change events.
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Returns `true` if an active session exists.
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Signs in anonymously to enable guest dialect browsing and recording sessions.
  Future<AuthResponse> signInAnonymously({Map<String, dynamic>? data}) async {
    return await client.auth.signInAnonymously(data: data);
  }

  /// Signs out the active user session.
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Database Query Helpers
  // ---------------------------------------------------------------------------

  /// Returns a query builder for the given table.
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Executes a PostgreSQL stored procedure / RPC function.
  PostgrestFilterBuilder rpc(String fn, {Map<String, dynamic>? params}) =>
      client.rpc(fn, params: params);

  // ---------------------------------------------------------------------------
  // Audio Storage Pipeline
  // ---------------------------------------------------------------------------

  /// Reference to the `echoes-audio` storage bucket.
  StorageFileApi get audioStorage =>
      client.storage.from(SupabaseConstants.audioBucket);

  /// Uploads audio recording file to the Supabase Storage bucket (`echoes-audio`)
  /// in high-fidelity `.m4a` / AAC format and returns the public stream URL.
  Future<String> uploadAudioFile({
    required File file,
    required String wordId,
  }) async {
    final fileName =
        '${SupabaseConstants.recordingsFolder}/${wordId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await client.storage.from(SupabaseConstants.audioBucket).upload(
          fileName,
          file,
          fileOptions: const FileOptions(contentType: 'audio/mp4'),
        );

    return client.storage
        .from(SupabaseConstants.audioBucket)
        .getPublicUrl(fileName);
  }

  /// Retrieves the public URL for a given storage path within the audio bucket.
  String getAudioPublicUrl(String path) {
    return client.storage.from(SupabaseConstants.audioBucket).getPublicUrl(path);
  }

  /// Deletes an audio file from the storage bucket.
  Future<List<FileObject>> deleteAudioFile(String path) async {
    return await client.storage
        .from(SupabaseConstants.audioBucket)
        .remove([path]);
  }
}
