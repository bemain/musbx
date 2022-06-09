import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum SoundType {
  sticks(fileName: "sticks.mp3", color: Colors.blue),
  cowbell(fileName: "cowbell.mp3", color: Colors.green);

  const SoundType({required this.fileName, required this.color});

  /// File used when playing this sound, eg. in BeatSounds.
  final String fileName;

  /// Color used when displaying this sound, eg. in BeatSoundViewer.
  final Color color;
}

class BeatSounds extends ChangeNotifier {
  BeatSounds() {
    // Preload sounds
    _audioCache.loadAll(
        SoundType.values.map((SoundType sound) => sound.fileName).toList());
  }

  /// Number of sounds.
  int get length => _sounds.length;
  set length(int value) {
    _sounds.length = value;
    notifyListeners();
  }

  /// Sounds to play at each beat.
  List<SoundType> get sounds => _sounds;
  final List<SoundType> _sounds = List.generate(4, ((i) => SoundType.sticks));

  /// Get sound at [index].
  SoundType operator [](int index) {
    return _sounds[index];
  }

  /// Set sound at [index].
  void operator []=(int index, SoundType value) {
    _sounds[index] = value;
    notifyListeners();
  }

  void add(SoundType value) {
    _sounds.add(value);
    notifyListeners();
  }

  SoundType removeAt(int index) {
    if (sounds.length <= 1) {
      debugPrint(
          "BeatSounds.removeAt($index) ignored! BeatSounds must always contain at least one sound!");
      return _sounds[0];
    }
    var res = _sounds.removeAt(index);
    notifyListeners();
    return res;
  }

  /// Internal AudioCache for playing sounds.
  final AudioCache _audioCache = AudioCache(prefix: "assets/metronome/");

  /// AudioPlayer that played the last sound, if any.
  AudioPlayer? audioPlayer;

  /// Play the sound corresponding with beat number [count].
  ///
  /// [count] must be between `0` and `sounds.length`.
  void playBeat(int count) async {
    assert(0 <= count && count < _sounds.length,
        "No sound defined for beat $count");

    audioPlayer = await _audioCache.play(
      _sounds[count].fileName,
      mode: PlayerMode.LOW_LATENCY,
    );
  }
}
