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
    speedNotifier.value = speed;
  }

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(double pitch) async {
    await _audioHandler.player.setPitch(pow(2, pitch / 12).toDouble());
    pitchSemitonesNotifier.value = pitch;
  }

  /// Title of the current song, or `null` if no song loaded.
  String? get songTitle => songTitleNotifier.value;
  final ValueNotifier<String?> songTitleNotifier = ValueNotifier<String?>(null);

  /// How much the pitch will be shifted, in semitones.
  double get pitchSemitones => pitchSemitonesNotifier.value;
  final ValueNotifier<double> pitchSemitonesNotifier = ValueNotifier(0);

  /// The current speed of the player.
  double get speed => speedNotifier.value;
  final ValueNotifier<double> speedNotifier = ValueNotifier(1);

  /// The current position of the player.
  Duration get position => positionNotifier.value;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  /// The buffered position of the player.
  Duration get bufferedPosition => bufferedPositionNotifier.value;
  final ValueNotifier<Duration> bufferedPositionNotifier =
      ValueNotifier(Duration.zero);

  /// The duration of the current audio, or null if no audio has been loaded.
  Duration? get duration => durationNotifier.value;
  final ValueNotifier<Duration?> durationNotifier = ValueNotifier(null);

  /// Whether we are currently looping a section of the song or not.
  bool get loopEnabled => loopEnabledNotifier.value;
  set loopEnabled(bool value) => loopEnabledNotifier.value = value;
  final ValueNotifier<bool> loopEnabledNotifier = ValueNotifier(true);

  /// The section being
  LoopSection get loopSection => loopSectionNotifier.value;
  set loopSection(LoopSection section) => loopSectionNotifier.value = section;
  final ValueNotifier<LoopSection> loopSectionNotifier =
      ValueNotifier(LoopSection());

  /// Whether the player is playing.
  bool get isPlaying => isPlayingNotifier.value;
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
    // bufferedPosition & isPlaying
    _audioHandler.playbackState.listen((newState) {
      bufferedPositionNotifier.value = newState.bufferedPosition;
      isPlayingNotifier.value = newState.playing;
    });

    // position
    AudioService.position.listen((position) {
      // Limit upper
      if ((loopEnabled && position >= loopSection.end) ||
          position >= (duration ?? const Duration(seconds: 1))) {
        _audioHandler.pause();
        seek(loopEnabled
            ? loopSection.end
            : duration ?? const Duration(seconds: 1));
      } else if (loopEnabled && position < loopSection.start) {
        // Limit lower
        seek(loopSection.start);
      } else {
        // Update position
        positionNotifier.value = Duration(
          milliseconds: position.inMilliseconds.clamp(
            0,
            duration?.inMilliseconds ?? 0,
          ),
        );
      }
    });

    // duration & songTitle
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem?.duration != duration) {
        // Update duration
        durationNotifier.value =
            mediaItem?.duration ?? const Duration(seconds: 1);
        // Reset loopSection
        loopSection = LoopSection(end: duration!);
      }

      // Update songTitle
      songTitleNotifier.value = mediaItem?.title;
    });

    // pitch
    _audioHandler.player.pitchStream.listen((pitch) {
      pitchSemitonesNotifier.value = (12 * log(pitch) / log(2)).toDouble();
    });

    // When loopSection changes, clamp position
    loopSectionNotifier.addListener(() {
      seek(Duration(
        milliseconds: position.inMilliseconds.clamp(
          loopSection.start.inMilliseconds,
          loopSection.end.inMilliseconds,
        ),
      ));
    });
  }
}

class LoopSection {
  LoopSection(
      {this.start = Duration.zero, this.end = const Duration(seconds: 1)});

  final Duration start;
  final Duration end;

  /// Duration between [start] and [end].
  Duration get length => end - start;
}
