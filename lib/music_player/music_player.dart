import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/audio_handler.dart';

/// Singleton for playing audio.
class MusicPlayer {
  // Should only be accessed through [instance].
  MusicPlayer.internal(this._audioHandler) {
    _listenForChanges();
  }

  /// The instance of this singleton.
  static late final MusicPlayer instance;

  /// The AudioHandler used internally to play sound.
  final JustAudioHandler _audioHandler;

  /// Start or resume playback.
  Future<void> play() async => await _audioHandler.play();

  /// Pause playback.
  Future<void> pause() async => await _audioHandler.pause();

  /// Seek to [position].
  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  /// Set the playback speed.
  Future<void> setSpeed(double speed) async {
    await _audioHandler.setSpeed(speed);
  }

  Future<void> setPitchSemitones(double pitch) async {
    await _audioHandler.player.setPitch(pow(2, pitch / 12).toDouble());
    pitchSemitonesNotifier.value = pitch;
  }

  /// Title of the current song, or `null` if no song loaded.
  final ValueNotifier<String?> songTitleNotifier = ValueNotifier<String?>(null);

  /// How much the pitch will be shifted, in semitones.
  final ValueNotifier<double> pitchSemitonesNotifier = ValueNotifier(0);

  /// The current speed of the player.
  final ValueNotifier<double> speedNotifier = ValueNotifier(1);

  /// The current position of the player.
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  /// The buffered position of the player.
  final ValueNotifier<Duration> bufferedPositionNotifier =
      ValueNotifier(Duration.zero);

  /// The duration of the current audio, or null if no audio has been loaded.
  final ValueNotifier<Duration?> durationNotifier = ValueNotifier(null);

  /// Whether the player is playing.
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Play a [PlatformFile].
  Future<void> playFile(PlatformFile file) async {
    await _audioHandler.player.setFilePath(file.path!);
    _audioHandler.mediaItem.add(MediaItem(
      id: file.path!,
      title: file.name,
      duration: _audioHandler.player.duration,
    ));
  }

  /// Listen for changes from [_audioHandler].
  void _listenForChanges() {
    // bufferedPosition & isPlaying & speed
    _audioHandler.playbackState.listen((newState) {
      bufferedPositionNotifier.value = newState.bufferedPosition;
      isPlayingNotifier.value = newState.playing;
      speedNotifier.value = newState.speed;
    });

    // position
    AudioService.position.listen((position) {
      positionNotifier.value = position;
    });

    // duration & songTitle
    _audioHandler.mediaItem.listen((mediaItem) {
      durationNotifier.value = mediaItem?.duration ?? Duration.zero;
      songTitleNotifier.value = mediaItem?.title;
    });

    // pitch
    _audioHandler.player.pitchStream.listen((pitch) {
      pitchSemitonesNotifier.value = (12 * log(pitch) / log(2)).toDouble();
    });
  }
}
