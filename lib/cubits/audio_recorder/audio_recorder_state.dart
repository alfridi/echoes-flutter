import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../models/echo_recording.dart';

abstract class AudioRecorderState extends Equatable {
  const AudioRecorderState();

  @override
  List<Object?> get props => [];
}

class RecorderInitial extends AudioRecorderState {
  const RecorderInitial();
}

class RecorderRecording extends AudioRecorderState {
  final int elapsedSeconds;
  final int maxSeconds;
  final double currentAmplitude; // -60.0 to 0.0 dB

  const RecorderRecording({
    required this.elapsedSeconds,
    this.maxSeconds = 5,
    this.currentAmplitude = -30.0,
  });

  double get progress => (elapsedSeconds / maxSeconds).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [elapsedSeconds, maxSeconds, currentAmplitude];
}

class RecorderCaptured extends AudioRecorderState {
  final File file;
  final Duration duration;

  const RecorderCaptured({required this.file, required this.duration});

  @override
  List<Object?> get props => [file.path, duration];
}

class RecorderUploading extends AudioRecorderState {
  final double uploadProgress;
  const RecorderUploading({this.uploadProgress = 0.5});

  @override
  List<Object?> get props => [uploadProgress];
}

class RecorderUploadedSuccess extends AudioRecorderState {
  final EchoRecording recording;
  const RecorderUploadedSuccess(this.recording);

  @override
  List<Object?> get props => [recording];
}

class RecorderFailure extends AudioRecorderState {
  final String error;
  const RecorderFailure(this.error);

  @override
  List<Object?> get props => [error];
}
