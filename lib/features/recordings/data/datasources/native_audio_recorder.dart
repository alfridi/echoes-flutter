import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service interfacing with native Android / iOS audio recording implementations
/// via Flutter [MethodChannel], with graceful fallback to the `record` package.
class NativeAudioRecorder {
  static const MethodChannel _channel =
      MethodChannel('com.example.echoes_flutter/audio_recorder');

  final AudioRecorder _fallbackRecorder = AudioRecorder();
  bool _useFallback = false;
  String? _currentPath;

  /// Checks if microphone permission has been granted by the user.
  Future<bool> hasPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('hasPermission');
      if (granted != null) return granted;
    } on MissingPluginException {
      _useFallback = true;
    } on PlatformException {
      _useFallback = true;
    } catch (_) {
      _useFallback = true;
    }

    return await _fallbackRecorder.hasPermission();
  }

  /// Begins audio capture in high-fidelity AAC (.m4a) container.
  Future<String> startRecording({String? customPath}) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = customPath ??
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentPath = path;

    if (!_useFallback) {
      try {
        final resultPath = await _channel.invokeMethod<String>(
          'startRecording',
          {'path': path},
        );
        if (resultPath != null && resultPath.isNotEmpty) {
          return resultPath;
        }
      } on MissingPluginException {
        _useFallback = true;
      } on PlatformException {
        _useFallback = true;
      } catch (_) {
        _useFallback = true;
      }
    }

    // Fallback path using package:record
    await _fallbackRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    return path;
  }

  /// Stops the recording session and returns the verified local file.
  Future<File?> stopRecording() async {
    String? path;

    if (!_useFallback) {
      try {
        path = await _channel.invokeMethod<String>('stopRecording');
      } on MissingPluginException {
        _useFallback = true;
      } on PlatformException {
        _useFallback = true;
      } catch (_) {
        _useFallback = true;
      }
    }

    if (_useFallback || path == null || path.isEmpty) {
      path = await _fallbackRecorder.stop();
    }

    final finalPath = path ?? _currentPath;
    if (finalPath != null && finalPath.isNotEmpty) {
      final file = File(finalPath);
      if (file.existsSync() && file.lengthSync() > 0) {
        return file;
      }
    }

    return null;
  }

  /// Queries real-time microphone decibel or amplitude reading.
  Future<double> getAmplitude() async {
    if (!_useFallback) {
      try {
        final amp = await _channel.invokeMethod<double>('getAmplitude');
        if (amp != null) return amp;
      } catch (_) {}
    }

    try {
      final amp = await _fallbackRecorder.getAmplitude();
      return amp.current;
    } catch (_) {
      return -30.0;
    }
  }

  /// Returns true if actively recording.
  Future<bool> isRecording() async {
    if (!_useFallback) {
      try {
        final rec = await _channel.invokeMethod<bool>('isRecording');
        if (rec != null) return rec;
      } catch (_) {}
    }

    return await _fallbackRecorder.isRecording();
  }

  /// Releases resources.
  Future<void> dispose() async {
    try {
      await _fallbackRecorder.dispose();
    } catch (_) {}
  }
}
