import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/music_player.dart';

/// Uses just_audio to handle playback.
/// Inherit to override getMediaItem, if you want to get metadata from a media id.
class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  // Only way to access is through [instance]
  MyAudioHandler._internal() {
    // Notify AudioHandler about playback events from AudioPlayer.
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  /// The instance of this singleton.
  static final MyAudioHandler instance = MyAudioHandler._internal();

  final MusicPlayer player = MusicPlayer.instance;

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() async {
    await player.pause();
  }

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await player.setSpeed(speed);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final isCompleted = (player.processingState == ProcessingState.completed);

    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekBackward,
        MediaAction.seekForward,
      },
      androidCompactActionIndices: const [0, 1],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.ready,
      }[player.processingState]!,
      // If completed, audioPlayer might say playing, but really we aren't.
      playing: player.playing && !isCompleted,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    );
  }
}
