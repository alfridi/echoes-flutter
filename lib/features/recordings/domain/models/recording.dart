import 'package:equatable/equatable.dart';

/// Domain Model representing a persisted voice recording archive item.
class Recording extends Equatable {
  final String id;
  final String userId;
  final String storagePath;
  final int? durationSeconds;
  final String? mimeType;
  final int? fileSize;
  final DateTime createdAt;

  const Recording({
    required this.id,
    required this.userId,
    required this.storagePath,
    this.durationSeconds,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
  });

  Recording copyWith({
    String? id,
    String? userId,
    String? storagePath,
    int? durationSeconds,
    String? mimeType,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return Recording(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storagePath: storagePath ?? this.storagePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        storagePath,
        durationSeconds,
        mimeType,
        fileSize,
        createdAt,
      ];
}
