import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayerAudioHandler extends BaseAudioHandler {
  /// Interface to the audio notification.
  MusicPlayerAudioHandler({
    required this.onPlay,
    required this.onPause,
    this.onStop,
    required Stream<PlaybackState> playbackStateStream,
  }) {
    // Listen to playback events from AudioPlayer.
    playbackStateStream.pipe(playbackState);
  }

  /// Called when the play action is triggered.
  final Future<void> Function() onPlay;

  /// Called when the pause action is triggered.
  final Future<void> Function() onPause;

  /// Called when the stop action is triggered.
  final Future<void> Function()? onStop;

  @override
  Future<void> play() async => await onPlay();

  @override
  Future<void> pause() async => await onPause();

  @override
  Future<void> stop() async {
    await onStop?.call();
    await super.stop();
  }

  /// Transform an event from just_audio's [AudioPlayer] to audio_service's [AudioHandler].
  static PlaybackState transformEvent(PlaybackEvent event, AudioPlayer player) {
    final isCompleted = (player.processingState == ProcessingState.completed);

    return PlaybackState(
      controls: [
        if (player.playing) MediaControl.pause else MediaControl.play,
      ],
      androidCompactActionIndices: const [0],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.ready,
      }[player.processingState]!,
      playing: player.playing && !isCompleted,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    );
  }
}
