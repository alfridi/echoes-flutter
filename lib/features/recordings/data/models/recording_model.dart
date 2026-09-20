import '../../domain/models/recording.dart';

/// Data Model representing database and network serialization for [Recording].
class RecordingModel extends Recording {
  const RecordingModel({
    required super.id,
    required super.userId,
    required super.storagePath,
    super.durationSeconds,
    super.mimeType,
    super.fileSize,
    required super.createdAt,
  });

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      mimeType: json['mime_type'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'storage_path': storagePath,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecordingModel.fromDomain(Recording recording) {
    return RecordingModel(
      id: recording.id,
      userId: recording.userId,
      storagePath: recording.storagePath,
      durationSeconds: recording.durationSeconds,
      mimeType: recording.mimeType,
      fileSize: recording.fileSize,
      createdAt: recording.createdAt,
    );
  }
}
