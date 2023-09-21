import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/host.dart';

class Stem {
  /// The default [volume]
  static const defaultVolume = 1.0;

  /// A demixed stem for a song. Can be played back in sync with other stems.
  ///
  /// There should (usually) only ever be one stem of each [type].
  Stem(this.type);

  /// The type of stem.
  final StemType type;

  /// Whether this stem is enabled and should be played.
  set enabled(bool value) => enabledNotifier.value = value;
  bool get enabled => enabledNotifier.value;
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);

  /// The volume this stem is played at. Must be between 0 and 1.
  set volume(double value) => volumeNotifier.value = value;
  double get volume => volumeNotifier.value;
  final ValueNotifier<double> volumeNotifier = ValueNotifier(defaultVolume);
}

class StemsNotifier extends ValueNotifier<List<Stem>> {
  /// Notifies listeners whenever [enabled] or [volume] of any of the stems provided in [value] changes.
  StemsNotifier(super.value) {
    for (Stem stem in value) {
      stem.enabledNotifier.addListener(notifyListeners);
      stem.volumeNotifier.addListener(notifyListeners);
    }
  }
}
