import 'dart:io';
import '../models/recording.dart';

/// Contract defining audio recording persistence and retrieval operations.
abstract class RecordingRepository {
  /// Validates and uploads local audio file to Supabase Storage and inserts metadata into PostgreSQL.
  Future<Recording> uploadRecording(File file, {int? durationSeconds});

  /// Retrieves recordings for the currently authenticated user.
  Future<List<Recording>> getRecordings();

  /// Resolves an audio stream URL (or signed URL for private buckets) for playback.
  Future<String> getPlaybackUrl(String storagePath);

  /// Deletes a recording record and removes its backing storage object.
  Future<void> deleteRecording(String recordingId, {String? storagePath});
}
