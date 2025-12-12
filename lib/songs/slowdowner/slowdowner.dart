import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// ignore: implementation_imports
import 'package:flutter_soloud/src/filters/pitchshift_filter.dart';
import 'package:musbx/songs/player/filter.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/widgets.dart';

class SlowdownerComponent extends SongPlayerComponent {
  SlowdownerComponent(super.player);

  /// The  pitch shift filter, provided by [SoLoud].
  Filter<PitchShiftSingle> get filter => player.filters.pitchShift;

  @override
  Future<void> initialize() async {
    // Note that this activation is redundant.
    // We have to activate the filter before the sound is played, and so we
    // activate it already when the [SongPlayer] is created.
    filter.activate();
  }

  @override
  void dispose() {
    filter.deactivate();
    super.dispose();
  }

  /// How much the pitch will be shifted, in semitones.
  double get pitch => pitchNotifier.value;
  set pitch(double value) => pitchNotifier.value = value;
  late final ValueNotifier<double> pitchNotifier = ValueNotifier(0.0)
    ..addListener(_updatePitch)
    ..addListener(notifyListeners);

  void _updatePitch() {
    filter.modify((filter, {handle}) {
      // Adjust pitch shift based on playback speed. The formula `pow(2, pitch / 12)`
      // converts semitone shifts to frequency ratios, and dividing by `speed` compensates
      // for changes in playback speed that affect perceived pitch.
      filter.shift(soundHandle: handle).value = pow(2, pitch / 12) / speed;
    });
  }

  /// The playback speed.
  double get speed => speedNotifier.value;
  set speed(double value) => speedNotifier.value = value;
  late final ValueNotifier<double> speedNotifier = ValueNotifier(1.0)
    ..addListener(_updateSpeed)
    ..addListener(notifyListeners);

  void _updateSpeed() {
    SoLoud.instance.setRelativePlaySpeed(player.handle, speed);
    _updatePitch();
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs:
  ///  - `pitch` [double] How much the pitch will be shifted, in semitones.
  ///  - `speed` [double] The playback speed of the audio, as a fraction.
  @override
  void loadPreferencesFromJson(Json json) {
    super.loadPreferencesFromJson(json);

    pitch = tryCast<double>(json['pitch'])?.clamp(-12, 12) ?? 0.0;
    speed = tryCast<double>(json['speed'])?.clamp(0.5, 2) ?? 1.0;

    notifyListeners();
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs:
  ///  - `pitch` [double] How much the pitch will be shifted, in semitones.
  ///  - `speed` [double] The playback speed of the audio, as a fraction.
  @override
  Json savePreferencesToJson() {
    return {
      ...super.savePreferencesToJson(),
      "pitch": pitch,
      "speed": speed,
    };
  }
}
