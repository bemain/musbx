import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum SoundType {
  sticks(fileName: "sticks.mp3", color: Colors.blue),
  cowbell(fileName: "cowbell.mp3", color: Colors.green);

  /// Internal AudioPlayer for controlling the sound that is currently playing.
  static final AudioPlayer audioPlayer = AudioPlayer(
    mode: PlayerMode.LOW_LATENCY,
  );

  /// Internal AudioCache for playing sounds.
  static final AudioCache audioCache = AudioCache(
    prefix: "assets/metronome/",
    fixedPlayer: audioPlayer,
  );

  const SoundType({required this.fileName, required this.color});

  /// File used when playing this sound, eg. in BeatSounds.
  final String fileName;

  /// Color used when displaying this sound, eg. in BeatSoundViewer.
  final Color color;

  /// Play this sound.
  void play() async {
    await audioCache.play(
      fileName,
      mode: PlayerMode.LOW_LATENCY,
    );
  }
}

class BeatSounds extends ChangeNotifier {
  BeatSounds() {
    // Preload sounds to avoid latency when first sound is played.
    SoundType.audioCache.loadAll(
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
}
