import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/recording.dart';
import '../../domain/repositories/recording_repository.dart';
import '../datasources/recording_supabase_datasource.dart';

/// Implementation of [RecordingRepository] coordinating between data source and domain layer.
class RecordingRepositoryImpl implements RecordingRepository {
  final RecordingSupabaseDatasource _datasource;

  RecordingRepositoryImpl({
    RecordingSupabaseDatasource? datasource,
  }) : _datasource = datasource ?? RecordingSupabaseDatasource();

  @override
  Future<Recording> uploadRecording(File file, {int? durationSeconds}) async {
    final model = await _datasource.uploadAndSaveRecording(
      file: file,
      durationSeconds: durationSeconds,
    );
    return model;
  }

  @override
  Future<List<Recording>> getRecordings() async {
    final user = _datasource.client.auth.currentUser;
    if (user == null) {
      throw const AuthException(
        'Cannot retrieve recordings: user is not authenticated.',
      );
    }
    final models = await _datasource.fetchRecordings(user.id);
    return models;
  }

  @override
  Future<String> getPlaybackUrl(String storagePath) async {
    return await _datasource.getPlaybackUrl(storagePath);
  }

  @override
  Future<void> deleteRecording(String recordingId, {String? storagePath}) async {
    await _datasource.deleteRecordingRow(recordingId);
    if (storagePath != null && storagePath.isNotEmpty) {
      await _datasource.deleteAudioFile(storagePath);
    }
  }
}
