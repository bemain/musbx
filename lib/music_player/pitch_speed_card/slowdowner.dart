import 'dart:math';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/widgets.dart';

/// A component for [MusicPlayer] that is used to change the speed and pitch of a song.
class Slowdowner extends MusicPlayerComponent {
  /// [MusicPlayer.player]'s method for setting pitch, set during [initialize].
  late final Future<void> Function(double) musicPlayerSetPitch;

  /// [MusicPlayer.player]'s method for setting speed, set during [initialize].
  late final Future<void> Function(double) musicPlayerSetSpeed;

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(double pitch) async {
    if (enabled) {
      await musicPlayerSetPitch(pow(2, pitch / 12).toDouble());
    }
    pitchSemitonesNotifier.value = pitch;
  }

  /// Set the playback speed.
  Future<void> setSpeed(double speed) async {
    if (enabled) {
      await musicPlayerSetSpeed(speed);
      await MusicPlayerAudioHandler.instance.setSpeed(speed);
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
    musicPlayerSetPitch = musicPlayer.player.setPitch;
    musicPlayerSetSpeed = musicPlayer.player.setSpeed;

    enabledNotifier.addListener(() {
      if (!enabled) {
        // Silently reset [MusicPlayer]'s pitch and speed
        musicPlayerSetPitch(1.0);
        musicPlayerSetSpeed(1.0);
        MusicPlayerAudioHandler.instance.setSpeed(1.0);
      } else {
        // Restore pitch and speed
        setPitchSemitones(pitchSemitones);
        setSpeed(speed);
      }
    });
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond "enabled"):
  ///  - "pitchSemitones": [double] How much the pitch will be shifted, in semitones..
  ///  - "speed": [double] The playback speed of the audio, as a fraction.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) {
    super.loadSettingsFromJson(json);

    double? newPitch = tryCast<double>(json["pitchSemitones"]);
    double? newSpeed = tryCast<double>(json["speed"]);

    pitchSemitones = newPitch?.clamp(-12, 12) ?? pitchSemitones;
    speed = newSpeed?.clamp(0.5, 2) ?? speed;
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs (beyond "enabled"):
  ///  - "pitchSemitones": [double] How much the pitch will be shifted, in semitones..
  ///  - "speed": [double] The playback speed of the audio, as a fraction.
  @override
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
      "pitchSemitones": pitchSemitones,
      "speed": speed,
    };
  }
}
