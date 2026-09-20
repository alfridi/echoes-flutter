import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_state.dart';

class AudioPlayerCubit extends Cubit<AudioPlaybackState> {
  final AudioPlayer _player;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  AudioPlayerCubit({AudioPlayer? player})
      : _player = player ?? AudioPlayer(),
        super(const AudioPlaybackState()) {
    _bindStreams();
  }

  void _bindStreams() {
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        emit(state.copyWith(
          status: AudioPlayerStatus.completed,
          currentPosition: state.totalDuration,
        ));
      } else if (playerState.playing) {
        emit(state.copyWith(status: AudioPlayerStatus.playing));
      } else if (playerState.processingState == ProcessingState.ready) {
        emit(state.copyWith(status: AudioPlayerStatus.paused));
      }
    });

    _positionSub = _player.positionStream.listen((pos) {
      emit(state.copyWith(currentPosition: pos));
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null) {
        emit(state.copyWith(totalDuration: dur));
      }
    });
  }

  /// Plays an audio URL (e.g. from Supabase Storage or public preview).
  Future<void> playTrack({
    required String audioUrl,
    required String trackId,
  }) async {
    try {
      if (state.activeTrackId == trackId && state.isPlaying) {
        await _player.pause();
        return;
      }
      if (state.activeTrackId == trackId &&
          state.status == AudioPlayerStatus.paused) {
        await _player.play();
        return;
      }

      emit(state.copyWith(
        status: AudioPlayerStatus.loading,
        activeTrackId: trackId,
        currentPosition: Duration.zero,
      ));

      await _player.setUrl(audioUrl);
      await _player.setSpeed(state.playbackSpeed);
      await _player.setLoopMode(state.isLooping ? LoopMode.one : LoopMode.off);
      await _player.play();
    } catch (e) {
      emit(state.copyWith(
        status: AudioPlayerStatus.error,
        errorMessage: 'Playback error: $e',
      ));
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> togglePhoneticSpeed() async {
    final nextSpeed = state.playbackSpeed == 1.0 ? 0.8 : 1.0;
    await _player.setSpeed(nextSpeed);
    emit(state.copyWith(playbackSpeed: nextSpeed));
  }

  Future<void> toggleLoop() async {
    final nextLoop = !state.isLooping;
    await _player.setLoopMode(nextLoop ? LoopMode.one : LoopMode.off);
    emit(state.copyWith(isLooping: nextLoop));
  }

  @override
  Future<void> close() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    return super.close();
  }
}
