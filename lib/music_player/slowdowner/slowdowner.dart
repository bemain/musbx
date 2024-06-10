import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/widgets.dart';

/// A component for [MusicPlayer] that is used to change the speed and pitch of a song.
class Slowdowner extends MusicPlayerComponent {
  /// The audio player used by [MusicPlayer], set during [initialize].
  late final AudioPlayer audioPlayer;

  /// The audio handler used by [MusicPlayer], set during [initialize].
  late final MusicPlayerAudioHandler audioHandler;

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(double pitch) async {
    // TODO: Implement pitch-changing on iOS
    if (enabled && !Platform.isIOS) {
      await audioPlayer.setPitch(pow(2, pitch / 12).toDouble());
    }
    pitchSemitonesNotifier.value = pitch;
  }

  /// Set the playback speed.
  Future<void> setSpeed(double speed) async {
    if (enabled) {
      await audioPlayer.setSpeed(speed);
      await audioHandler.setSpeed(speed);
    }
    speedNotifier.value = speed;
  }

  /// How much the pitch will be shifted, in semitones.
  double get pitchSemitones => pitchSemitonesNotifier.value;
  set pitchSemitones(double value) => setPitchSemitones(value);
  final ValueNotifier<double> pitchSemitonesNotifier = ValueNotifier(0);

  /// The playback speed.
  double get speed => speedNotifier.value;
  set speed(double value) => setSpeed(value);
  final ValueNotifier<double> speedNotifier = ValueNotifier(1);

  @override
  void initialize(MusicPlayer musicPlayer) {
    audioPlayer = musicPlayer.player;
    audioHandler = musicPlayer.audioHandler;

    enabledNotifier.addListener(() {
      if (!enabled) {
        // Silently reset [MusicPlayer]'s pitch and speed
        if (!Platform.isIOS) audioPlayer.setPitch(1.0);
        audioPlayer.setSpeed(1.0);
        musicPlayer.audioHandler.setSpeed(1.0);
      } else {
        // Restore pitch and speed
        setPitchSemitones(pitchSemitones);
        setSpeed(speed);
      }
    });
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond `enabled`):
  ///  - `pitchSemitones` [double] How much the pitch will be shifted, in semitones.
  ///  - `speed` [double] The playback speed of the audio, as a fraction.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) {
    super.loadSettingsFromJson(json);

    final double? pitch = tryCast<double>(json["pitchSemitones"]);
    final double? speed = tryCast<double>(json["speed"]);

    pitchSemitones = pitch?.clamp(-12, 12) ?? 0.0;
    this.speed = speed?.clamp(0.5, 2) ?? 1.0;
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs (beyond `enabled`):
  ///  - `pitchSemitones` [double] How much the pitch will be shifted, in semitones.
  ///  - `speed` [double] The playback speed of the audio, as a fraction.
  @override
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
      "pitchSemitones": pitchSemitones,
      "speed": speed,
    };
  }
}
