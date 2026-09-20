import 'dart:io';
import '../core/services/supabase_service.dart';
import '../models/echo_recording.dart';

/// Repository interface defining audio uploads and community dialect recording queries.
abstract class RecordingRepository {
  Future<List<EchoRecording>> getRecordingsForWord(String wordId);
  Future<EchoRecording> uploadAndCreateRecording({
    required File audioFile,
    required String wordId,
    required String languageId,
    required Duration duration,
    required String accentTerritory,
    required String contributorName,
    required String contributorAvatarUrl,
  });
}

/// Supabase PostgreSQL & Storage implementation of [RecordingRepository].
class SupabaseRecordingRepository implements RecordingRepository {
  final SupabaseService _supabase;

  SupabaseRecordingRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService();

  @override
  Future<List<EchoRecording>> getRecordingsForWord(String wordId) async {
    final response = await _supabase.client
        .from('echo_recordings')
        .select()
        .eq('word_id', wordId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((e) => EchoRecording.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EchoRecording> uploadAndCreateRecording({
    required File audioFile,
    required String wordId,
    required String languageId,
    required Duration duration,
    required String accentTerritory,
    required String contributorName,
    required String contributorAvatarUrl,
  }) async {
    // 1. Upload lossless audio to Supabase Storage
    final publicAudioUrl = await _supabase.uploadAudioFile(
      file: audioFile,
      wordId: wordId,
    );

    // 2. Insert record into Postgres echo_recordings table
    final currentUser = _supabase.client.auth.currentUser;
    final row = {
      'word_id': wordId,
      'language_id': languageId,
      if (currentUser?.id != null) 'contributor_id': currentUser!.id,
      'contributor_name': contributorName,
      'contributor_avatar_url': contributorAvatarUrl,
      'audio_url': publicAudioUrl,
      'duration_ms': duration.inMilliseconds,
      'accent_territory': accentTerritory,
      'acoustic_fidelity': 'Pristine',
    };

    final inserted = await _supabase.client
        .from('echo_recordings')
        .insert(row)
        .select()
        .single();

    // 3. Increment word recording counter via RPC
    try {
      await _supabase.client
          .rpc('increment_word_recordings', params: {'p_word_id': wordId});
    } catch (_) {}

    return EchoRecording.fromMap(inserted);
  }
}
