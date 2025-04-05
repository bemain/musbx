import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// ignore: implementation_imports
import 'package:flutter_soloud/src/filters/pitchshift_filter.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/widgets/widgets.dart';

class SlowdownerComponent extends SongPlayerComponent {
  SlowdownerComponent(super.player);

  /// Modify the pitch filter for the current song.
  ///
  /// Note that this cannot be used to activate or deactivate a filter, since
  /// that has to be done before the song is loaded and [player.handle] thus
  /// isn't available at that time.
  void _modifyPitchFilter(
      void Function(PitchShiftSingle filter, {SoundHandle? handle}) modify) {
    player.playable.filters(handle: player.handle).pitchShift.modify(modify);
  }

  @override
  void initialize() {
    player.playable.filters().pitchShift.activate();
  }

  @override
  void dispose() {
    player.playable.filters().pitchShift.deactivate();
  }

  /// How much the pitch will be shifted, in semitones.
  double get pitch => pitchNotifier.value;
  set pitch(double value) => pitchNotifier.value = value;
  late final ValueNotifier<double> pitchNotifier = ValueNotifier(0)
    ..addListener(_updatePitch);

  void _updatePitch() {
    _modifyPitchFilter((filter, {SoundHandle? handle}) {
      filter.semitones(soundHandle: handle).value = pitch;
    });
  }

  /// The playback speed.
  double get speed => speedNotifier.value;
  set speed(double value) => speedNotifier.value = value;
  late final ValueNotifier<double> speedNotifier = ValueNotifier(1)
    ..addListener(_updateSpeed);

  void _updateSpeed() {
    SoLoud.instance.setRelativePlaySpeed(player.handle, speed);
    _modifyPitchFilter((filter, {SoundHandle? handle}) {
      filter.shift(soundHandle: handle).value = 1 / speed;
    });
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs:
  ///  - `pitch` [double] How much the pitch will be shifted, in semitones.
  ///  - `speed` [double] The playback speed of the audio, as a fraction.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) {
    super.loadSettingsFromJson(json);

    pitch = tryCast<double>(json["pitch"])?.clamp(-12, 12) ?? 0.0;
    speed = tryCast<double>(json["speed"])?.clamp(0.5, 2) ?? 1.0;
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs:
  ///  - `pitch` [double] How much the pitch will be shifted, in semitones.
  ///  - `speed` [double] The playback speed of the audio, as a fraction.
  @override
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
      "pitch": pitch,
      "speed": speed,
    };
  }
}
