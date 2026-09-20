import 'package:equatable/equatable.dart';

enum AudioPlayerStatus { idle, loading, playing, paused, completed, error }

class AudioPlaybackState extends Equatable {
  final AudioPlayerStatus status;
  final String? activeTrackId;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;
  final bool isLooping;
  final String? errorMessage;

  const AudioPlaybackState({
    this.status = AudioPlayerStatus.idle,
    this.activeTrackId,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.isLooping = false,
    this.errorMessage,
  });

  bool get isPlaying => status == AudioPlayerStatus.playing;

  double get progress => totalDuration.inMilliseconds > 0
      ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
          .clamp(0.0, 1.0)
      : 0.0;

  AudioPlaybackState copyWith({
    AudioPlayerStatus? status,
    String? activeTrackId,
    Duration? currentPosition,
    Duration? totalDuration,
    double? playbackSpeed,
    bool? isLooping,
    String? errorMessage,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      activeTrackId: activeTrackId ?? this.activeTrackId,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isLooping: isLooping ?? this.isLooping,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeTrackId,
        currentPosition,
        totalDuration,
        playbackSpeed,
        isLooping,
        errorMessage,
      ];
}
