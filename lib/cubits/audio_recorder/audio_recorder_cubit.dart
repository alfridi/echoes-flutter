import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../repositories/recording_repository.dart';
import 'audio_recorder_state.dart';

class AudioRecorderCubit extends Cubit<AudioRecorderState> {
  final AudioRecorder _recorder;
  final RecordingRepository recordingRepository;
  Timer? _ticker;
  int _seconds = 0;
  String? _capturedPath;

  AudioRecorderCubit({
    AudioRecorder? recorder,
    required this.recordingRepository,
  })  : _recorder = recorder ?? AudioRecorder(),
        super(const RecorderInitial());

  Future<void> startRecording({int maxDurationSeconds = 5}) async {
    try {
      if (!await _recorder.hasPermission()) {
        emit(const RecorderFailure('Microphone permission denied'));
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/echo_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _capturedPath = path;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 48000,
        ),
        path: path,
      );

      _seconds = 0;
      emit(RecorderRecording(
        elapsedSeconds: _seconds,
        maxSeconds: maxDurationSeconds,
      ));

      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
        _seconds++;
        final amp = await _recorder.getAmplitude();
        if (_seconds >= maxDurationSeconds) {
          timer.cancel();
          await stopLocalCapture();
        } else {
          emit(RecorderRecording(
            elapsedSeconds: _seconds,
            maxSeconds: maxDurationSeconds,
            currentAmplitude: amp.current,
          ));
        }
      });
    } catch (e) {
      emit(RecorderFailure('Failed to start recording: $e'));
    }
  }

  Future<void> stopLocalCapture() async {
    _ticker?.cancel();
    try {
      final path = await _recorder.stop();
      final finalPath = path ?? _capturedPath;
      if (finalPath != null && File(finalPath).existsSync()) {
        emit(RecorderCaptured(
          file: File(finalPath),
          duration: Duration(seconds: _seconds > 0 ? _seconds : 1),
        ));
      } else {
        emit(const RecorderFailure('Audio file could not be finalized'));
      }
    } catch (e) {
      emit(RecorderFailure('Error stopping recording: $e'));
    }
  }

  /// Uploads local recording to Supabase Storage and creates record in PostgreSQL.
  Future<void> uploadToSupabase({
    required String wordId,
    required String languageId,
    required String accentTerritory,
    required String contributorName,
    required String contributorAvatarUrl,
  }) async {
    final currentState = state;
    if (currentState is! RecorderCaptured) return;

    try {
      emit(const RecorderUploading());
      final recording = await recordingRepository.uploadAndCreateRecording(
        audioFile: currentState.file,
        wordId: wordId,
        languageId: languageId,
        duration: currentState.duration,
        accentTerritory: accentTerritory,
        contributorName: contributorName,
        contributorAvatarUrl: contributorAvatarUrl,
      );
      emit(RecorderUploadedSuccess(recording));
    } catch (e) {
      emit(RecorderFailure('Supabase upload failed: $e'));
    }
  }

  void reset() {
    _ticker?.cancel();
    emit(const RecorderInitial());
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _recorder.dispose();
    return super.close();
  }
}
