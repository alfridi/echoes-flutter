import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../models/recording_model.dart';

/// Datasource executing direct Supabase Storage and PostgreSQL database queries
/// for the voice recording expedition feature.
class RecordingSupabaseDatasource {
  final SupabaseClient _client;
  final String bucketName;

  RecordingSupabaseDatasource({
    SupabaseClient? client,
    String? bucketName,
  })  : _client = client ?? Supabase.instance.client,
        bucketName = bucketName ?? 'recordings';

  SupabaseClient get client => _client;

  /// Validates local audio file properties before initiating upload.
  void validateAudioFile(File file) {
    if (!file.existsSync()) {
      throw const FileSystemException('Audio recording file does not exist.');
    }
    final size = file.lengthSync();
    if (size <= 0) {
      throw const FileSystemException('Recorded audio file is empty (0 bytes).');
    }

    final lowerPath = file.path.toLowerCase();
    final hasValidExt = lowerPath.endsWith('.m4a') ||
        lowerPath.endsWith('.aac') ||
        lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.wav') ||
        lowerPath.endsWith('.mp3');

    if (!hasValidExt) {
      throw const FormatException(
        'Invalid audio format. Expected .m4a, .aac, or compatible audio container.',
      );
    }
  }

  /// Uploads audio binary to Supabase Storage.
  Future<String> uploadAudioFile({
    required File file,
    required String storagePath,
    String contentType = 'audio/mp4',
  }) async {
    validateAudioFile(file);

    try {
      await _client.storage.from(bucketName).upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
      return storagePath;
    } on StorageException {
      // If primary bucket failed, attempt fallback to archival bucket if different
      if (bucketName != SupabaseConstants.audioBucket) {
        await _client.storage.from(SupabaseConstants.audioBucket).upload(
              storagePath,
              file,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: true,
              ),
            );
        return storagePath;
      }
      rethrow;
    }
  }

  /// Removes an audio file from Supabase Storage.
  Future<void> deleteAudioFile(String storagePath) async {
    try {
      await _client.storage.from(bucketName).remove([storagePath]);
    } catch (_) {
      try {
        await _client.storage
            .from(SupabaseConstants.audioBucket)
            .remove([storagePath]);
      } catch (_) {}
    }
  }

  /// Inserts recording metadata record into the `recordings` table.
  Future<RecordingModel> insertRecording(
      Map<String, dynamic> recordingData) async {
    final response = await _client
        .from('recordings')
        .insert(recordingData)
        .select()
        .single();
    return RecordingModel.fromJson(response);
  }

  /// Fetches recordings for the specified [userId] ordered by newest first.
  Future<List<RecordingModel>> fetchRecordings(String userId) async {
    final response = await _client
        .from('recordings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => RecordingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a recording metadata row from the `recordings` table.
  Future<void> deleteRecordingRow(String recordingId) async {
    await _client.from('recordings').delete().eq('id', recordingId);
  }

  /// Resolves an audio stream URL (generates signed URL if private, fallback to public).
  Future<String> getPlaybackUrl(String storagePath) async {
    // 1. Try signed URL on primary bucket
    try {
      final signedUrl = await _client.storage
          .from(bucketName)
          .createSignedUrl(storagePath, 3600);
      return signedUrl;
    } catch (_) {}

    // 2. Try signed URL on fallback bucket
    if (bucketName != SupabaseConstants.audioBucket) {
      try {
        final signedUrl = await _client.storage
            .from(SupabaseConstants.audioBucket)
            .createSignedUrl(storagePath, 3600);
        return signedUrl;
      } catch (_) {}
    }

    // 3. Fallback to public URL
    try {
      return _client.storage.from(bucketName).getPublicUrl(storagePath);
    } catch (_) {
      return _client.storage
          .from(SupabaseConstants.audioBucket)
          .getPublicUrl(storagePath);
    }
  }

  /// Complete end-to-end upload sequence with strict compensation logic:
  /// 1. Validate local recording
  /// 2. Validate current authenticated user session
  /// 3. Generate UUID identifier
  /// 4. Upload to Supabase Storage
  /// 5. Insert into PostgreSQL database
  /// 6. If DB insert fails, rollback Storage object
  Future<RecordingModel> uploadAndSaveRecording({
    required File file,
    int? durationSeconds,
  }) async {
    // Step 1: Validate recording file
    validateAudioFile(file);

    // Step 2: Get authenticated user
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException(
        'User must be authenticated to upload voice recordings.',
      );
    }

    // Step 3: Generate unique UUID & path
    final recordingId = const Uuid().v4();
    final storagePath = 'recordings/${currentUser.id}/$recordingId.m4a';
    final fileSize = file.lengthSync();

    // Step 4: Upload audio to Supabase Storage
    String uploadedPath;
    try {
      uploadedPath = await uploadAudioFile(
        file: file,
        storagePath: storagePath,
        contentType: 'audio/mp4',
      );
    } catch (storageError) {
      // Storage upload failed -> Do NOT insert DB record, rethrow
      throw Exception('Storage upload failed: $storageError');
    }

    // Step 5: Insert metadata into recordings table
    try {
      final rowData = {
        'id': recordingId,
        'user_id': currentUser.id,
        'storage_path': uploadedPath,
        'duration_seconds': durationSeconds ?? 0,
        'mime_type': 'audio/mp4',
        'file_size': fileSize,
      };

      return await insertRecording(rowData);
    } catch (dbError) {
      // Compensation: Database insert failed after storage succeeded -> delete storage object
      try {
        await deleteAudioFile(uploadedPath);
      } catch (_) {
        // Silently capture compensation deletion errors
      }
      throw Exception(
        'Database record creation failed. Uploaded audio was cleaned up: $dbError',
      );
    }
  }
}
