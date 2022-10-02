import 'package:flutter/material.dart';
import 'package:musbx/metronome/beat_sound.dart';

class MetronomeBeats extends ChangeNotifier {
  MetronomeBeats() {
    // Preload sounds to avoid latency when first sound is played.
    List<String> beatPaths =
        BeatSound.values.map((BeatSound sound) => sound.fileName).toList();
    beatPaths.remove("");
    BeatSound.audioCache.loadAll(beatPaths);
  }

  /// Number of sounds.
  int get length => _sounds.length;
  set length(int value) {
    _sounds.length = value;
    notifyListeners();
  }

  /// Sounds to play at each beat.
  List<BeatSound> get sounds => _sounds;
  final List<BeatSound> _sounds = List.generate(4, ((i) => BeatSound.primary));

  /// Get sound at [index].
  BeatSound operator [](int index) {
    return _sounds[index];
  }

  /// Set sound at [index].
  void operator []=(int index, BeatSound value) {
    _sounds[index] = value;
    notifyListeners();
  }

  void add(BeatSound value) {
    _sounds.add(value);
    notifyListeners();
  }

  BeatSound removeAt(int index) {
    if (sounds.length <= 1) {
      debugPrint(
          "BeatSounds.removeAt($index) ignored! BeatSounds must always contain at least one sound!");
      return _sounds[0];
    }
    var res = _sounds.removeAt(index);
    notifyListeners();
    return res;
  }
}
