import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musbx/metronome/beat_sound.dart';
import 'package:soundpool/soundpool.dart';

class MetronomeBeats extends ChangeNotifier {
  MetronomeBeats() {
    // Preload sounds
    Future.wait(BeatSound.values
            .map((beatSound) async => MapEntry(
                beatSound,
                (beatSound.fileName == "")
                    ? null
                    : await rootBundle
                        .load("assets/metronome/${beatSound.fileName}")
                        .then((ByteData soundData) => pool.load(soundData))))
            .toList())
        .then((entries) => soundIds = Map.fromEntries(entries));
  }

  /// IDs for [BeatSound]s, used by [pool] for playing sound.
  Map<BeatSound, int?>? soundIds;

  /// The [Soundpool] used for playing sound.
  final Soundpool pool = Soundpool.fromOptions(
    options: const SoundpoolOptions(streamType: StreamType.music),
  );

  /// Play the sound at [count].
  void playBeat(int count) async {
    if (soundIds == null) {
      debugPrint("playBeat($count) skipped; soundIDs haven't been loaded yet.");
      return;
    }
    if (soundIds![sounds[count]] == null) return;

    await pool.play(soundIds![sounds[count]]!);
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
