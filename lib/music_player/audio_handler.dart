import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/music_player.dart';

class MusicPlayerAudioHandler extends BaseAudioHandler {
  /// Interface to the audio notification.
  ///
  /// Uses [MusicPlayer]'s [AudioPlayer] to handle playback.
  MusicPlayerAudioHandler() {
    // Listen to playback events from AudioPlayer.
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  /// The instance of this singleton.
  static late final MusicPlayerAudioHandler instance;

  /// The player used for playing audio.
  final AudioPlayer _player = MusicPlayer.instance.player;

  @override
  Future<void> play() async => await _player.play();

  @override
  Future<void> pause() async => await _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  /// Transform an event from just_audio's [AudioPlayer] to audio_service's [AudioHandler].
  PlaybackState _transformEvent(PlaybackEvent event) {
    final isCompleted = (_player.processingState == ProcessingState.completed);

    return PlaybackState(
      controls: [
        if (_player.playing) MediaControl.pause else MediaControl.play,
      ],
      androidCompactActionIndices: const [0],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.ready,
      }[_player.processingState]!,
      playing: _player.playing && !isCompleted,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }
}
