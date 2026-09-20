import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/datasources/native_audio_recorder.dart';
import '../../domain/models/recording.dart';
import '../../domain/repositories/recording_repository.dart';

/// Explicit discrete lifecycle states for the audio recording and submission journey.
enum RecordingStatus {
  idle,
  recording,
  recorded,
  uploading,
  uploaded,
  loading,
  error,
}

/// ViewModel coordinating the recording expedition state, native hardware recording,
/// audio playback, and Supabase cloud persistence.
class RecordingViewModel extends ChangeNotifier {
  final RecordingRepository repository;
  final NativeAudioRecorder _recorder;
  final AudioPlayer _audioPlayer;

  // Recording State
  RecordingStatus _status = RecordingStatus.idle;
  File? _recordedFile;
  Duration _recordingDuration = Duration.zero;
  double _currentAmplitude = -30.0;
  String? _errorMessage;
  Recording? _lastUploadedRecording;

  // Remote recordings catalog
  List<Recording> _recordings = [];
  bool _isLoadingRecordings = false;

  // Playback State
  String? _activeTrackId;
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  // Internal subscriptions
  Timer? _recordingTimer;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  RecordingViewModel({
    required this.repository,
    NativeAudioRecorder? recorder,
    AudioPlayer? audioPlayer,
  })  : _recorder = recorder ?? NativeAudioRecorder(),
        _audioPlayer = audioPlayer ?? AudioPlayer() {
    _initAudioPlayerListeners();
  }

  // Getters
  RecordingStatus get status => _status;
  bool get isIdle => _status == RecordingStatus.idle;
  bool get isRecording => _status == RecordingStatus.recording;
  bool get isRecorded => _status == RecordingStatus.recorded;
  bool get isUploading => _status == RecordingStatus.uploading;
  bool get isUploaded => _status == RecordingStatus.uploaded;
  bool get isError => _status == RecordingStatus.error;

  File? get recordedFile => _recordedFile;
  Duration get recordingDuration => _recordingDuration;
  double get currentAmplitude => _currentAmplitude;
  String? get errorMessage => _errorMessage;
  Recording? get lastUploadedRecording => _lastUploadedRecording;

  List<Recording> get recordings => List.unmodifiable(_recordings);
  bool get isLoadingRecordings => _isLoadingRecordings;

  String? get activeTrackId => _activeTrackId;
  bool get isPlaying => _isPlaying;
  Duration get playbackPosition => _playbackPosition;
  Duration get playbackDuration => _playbackDuration;

  double get playbackProgress {
    if (_playbackDuration.inMilliseconds <= 0) return 0.0;
    return (_playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  void _initAudioPlayerListeners() {
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
        _activeTrackId = null;
      }
      notifyListeners();
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      _playbackPosition = pos;
      notifyListeners();
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _playbackDuration = dur;
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Audio Recording Flow
  // ---------------------------------------------------------------------------

  /// Initiates microphone recording expedition.
  Future<void> startRecording() async {
    try {
      // 1. Check microphone permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _status = RecordingStatus.error;
        _errorMessage =
            'Microphone permission denied. Please grant permission in settings.';
        notifyListeners();
        return;
      }

      // 2. Stop any active playback
      await stopPlayback();

      // 3. Start native recorder
      _recordingDuration = Duration.zero;
      _errorMessage = null;
      _recordedFile = null;

      await _recorder.startRecording();
      _status = RecordingStatus.recording;
      notifyListeners();

      // 4. Start ticker for duration and live amplitude meter
      _recordingTimer?.cancel();
      _recordingTimer =
          Timer.periodic(const Duration(milliseconds: 200), (timer) async {
        _recordingDuration += const Duration(milliseconds: 200);
        final amp = await _recorder.getAmplitude();
        _currentAmplitude = amp;
        notifyListeners();
      });
    } catch (e) {
      _recordingTimer?.cancel();
      _status = RecordingStatus.error;
      _errorMessage = 'Recording initialization failure: $e';
      notifyListeners();
    }
  }

  /// Concludes active audio recording and verifies local file integrity.
  Future<void> stopRecording() async {
    if (_status != RecordingStatus.recording) return;

    _recordingTimer?.cancel();

    try {
      final file = await _recorder.stopRecording();

      // Verification steps
      if (file == null || !file.existsSync() || file.lengthSync() <= 0) {
        _status = RecordingStatus.error;
        _errorMessage =
            'Empty or invalid recording. Please try speaking again.';
        notifyListeners();
        return;
      }

      _recordedFile = file;
      _status = RecordingStatus.recorded;
      _errorMessage = null;

      // Prepare player for preview
      try {
        await _audioPlayer.setFilePath(file.path);
        _playbackDuration = _audioPlayer.duration ?? _recordingDuration;
      } catch (_) {}

      notifyListeners();
    } catch (e) {
      _status = RecordingStatus.error;
      _errorMessage = 'Recording finalization failure: $e';
      notifyListeners();
    }
  }

  /// Discards current recording and resets to idle state for re-recording.
  Future<void> deleteRecording() async {
    await stopPlayback();

    if (_recordedFile != null) {
      try {
        if (_recordedFile!.existsSync()) {
          await _recordedFile!.delete();
        }
      } catch (_) {}
      _recordedFile = null;
    }

    _recordingDuration = Duration.zero;
    _playbackPosition = Duration.zero;
    _playbackDuration = Duration.zero;
    _status = RecordingStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Preview & Remote Playback Controls
  // ---------------------------------------------------------------------------

  /// Toggles playback of the locally captured preview audio file.
  Future<void> togglePlayPausePreview() async {
    if (_recordedFile == null) return;

    const previewId = 'preview_local_audio';

    if (_activeTrackId == previewId && _isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    try {
      if (_activeTrackId != previewId) {
        _activeTrackId = previewId;
        await _audioPlayer.setFilePath(_recordedFile!.path);
      }
      await _audioPlayer.play();
    } catch (e) {
      _errorMessage = 'Playback error: $e';
      notifyListeners();
    }
  }

  /// Plays a remote recording fetched from Supabase Storage.
  Future<void> playRemoteRecording(Recording recording) async {
    if (_activeTrackId == recording.id && _isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    try {
      if (_activeTrackId == recording.id &&
          _audioPlayer.processingState == ProcessingState.ready) {
        await _audioPlayer.play();
        return;
      }

      _activeTrackId = recording.id;
      notifyListeners();

      final playbackUrl =
          await repository.getPlaybackUrl(recording.storagePath);

      if (playbackUrl.startsWith('http')) {
        await _audioPlayer.setUrl(playbackUrl);
      } else {
        await _audioPlayer.setFilePath(playbackUrl);
      }
      await _audioPlayer.play();
    } catch (e) {
      _errorMessage = 'Playback error: $e';
      _activeTrackId = null;
      notifyListeners();
    }
  }

  /// Pauses any active playback.
  Future<void> pausePlayback() async {
    await _audioPlayer.pause();
  }

  /// Stops any active playback and resets position.
  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _activeTrackId = null;
    _playbackPosition = Duration.zero;
    notifyListeners();
  }

  /// Seeks to a specific timestamp in the active playback stream.
  Future<void> seekPlayback(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // ---------------------------------------------------------------------------
  // Supabase Upload & Persistence Flow
  // ---------------------------------------------------------------------------

  /// Submits the captured audio recording to Supabase Storage and PostgreSQL.
  Future<void> submitRecording() async {
    if (_recordedFile == null) {
      _status = RecordingStatus.error;
      _errorMessage = 'No recording file available to submit.';
      notifyListeners();
      return;
    }

    await stopPlayback();

    _status = RecordingStatus.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      final recording = await repository.uploadRecording(
        _recordedFile!,
        durationSeconds: _recordingDuration.inSeconds,
      );

      _lastUploadedRecording = recording;
      _status = RecordingStatus.uploaded;

      // Add to list and reload catalog
      _recordings.insert(0, recording);
      notifyListeners();
    } catch (e) {
      // Keep local recording intact to allow retry
      _status = RecordingStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Retries submission if upload previously failed.
  Future<void> retryUpload() async {
    await submitRecording();
  }

  // ---------------------------------------------------------------------------
  // Remote Catalog Management
  // ---------------------------------------------------------------------------

  /// Retrieves recordings for the authenticated user from Supabase Database.
  Future<void> loadRecordings() async {
    _isLoadingRecordings = true;
    notifyListeners();

    try {
      final list = await repository.getRecordings();
      _recordings = list;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load recordings: $e';
    } finally {
      _isLoadingRecordings = false;
      notifyListeners();
    }
  }

  /// Deletes a recording from Supabase Database and Storage.
  Future<void> deleteRemoteRecording(Recording recording) async {
    try {
      if (_activeTrackId == recording.id) {
        await stopPlayback();
      }
      await repository.deleteRecording(
        recording.id,
        storagePath: recording.storagePath,
      );
      _recordings.removeWhere((item) => item.id == recording.id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete recording: $e';
      notifyListeners();
    }
  }

  /// Clears error messages.
  void clearError() {
    _errorMessage = null;
    if (_status == RecordingStatus.error) {
      _status = _recordedFile != null
          ? RecordingStatus.recorded
          : RecordingStatus.idle;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }
}
