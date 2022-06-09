import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum SoundType {
  sticks,
  pop1,
  pop2,
}

class BeatSounds extends ChangeNotifier {
  /// Number of sounds.
  int get length => _sounds.length;
  set length(int value) {
    _sounds.length = value;
    notifyListeners();
  }

  /// Sounds to play at each beat.
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

  /// Internal AudioCache for playing sounds.
  final AudioCache _audioCache = AudioCache();

  /// AudioPlayer that played the last sound, if any.
  AudioPlayer? audioPlayer;

  /// Play the sound corresponding with beat number [count].
  ///
  /// [count] must be between `0` and `sounds.length`.
  void playBeat(int count) async {
    assert(0 <= count && count < _sounds.length,
        "No sound defined for beat $count");

    audioPlayer = await _audioCache.play(
      "${_sounds[count].index}.mp3",
      mode: PlayerMode.LOW_LATENCY,
    );
  }
}
