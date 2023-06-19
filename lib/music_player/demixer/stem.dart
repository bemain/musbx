import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:musbx/music_player/music_player.dart';

class Stem {
  /// A demixed stem for a song. Can be played back in sync with other stems.
  ///
  /// There should (usually) only ever be one stem of each [type].
  Stem(this.type) {
    player.volumeStream.listen((value) => volumeNotifier.value = value);
  }

  /// The type of stem.
  final StemType type;

  /// Whether this stem is enabled and should be played.
  set enabled(bool value) {
    if (value == false) player.pause();
    if (value == true &&
        MusicPlayer.instance.demixer.enabled &&
        MusicPlayer.instance.isPlaying) player.play();
    enabledNotifier.value = value;
  }

  bool get enabled => enabledNotifier.value;
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);

  /// The volume this stem is played at. Must be between 0 and 1.
  set volume(double value) => player.setVolume(value.clamp(0, 1));
  double get volume => volumeNotifier.value;
  final ValueNotifier<double> volumeNotifier = ValueNotifier(0.5);

  /// The player used internally for playback.
  late final AudioPlayer player = AudioPlayer()..setVolume(volume);
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
