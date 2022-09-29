import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

const List<BeatSound> selectableBeatSounds = [
  BeatSound.sticks,
  BeatSound.cowbell,
  BeatSound.none,
];

enum BeatSound {
  sticks(fileName: "sticks.wav", color: Colors.blue),
  cowbell(fileName: "cowbell.mp3", color: Colors.green),
  hihat(fileName: "hihat.wav", color: Colors.orange),
  snare(fileName: "snare.wav", color: Colors.purple),
  kick(fileName: "kick.wav", color: Colors.indigo),
  none(fileName: "", color: Colors.grey);

  /// Internal AudioCache for playing sounds.
  static final AudioCache audioCache = AudioCache(
    prefix: "assets/metronome/",
    respectSilence: true,
  );

  const BeatSound({required this.fileName, required this.color});

  /// File used when playing this sound, eg. in BeatSounds.
  final String fileName;

  /// Color used when displaying this sound, eg. in BeatSoundViewer.
  final Color color;

  /// Play this sound.
  void play() async {
    if (fileName == "") return;
    await audioCache.play(
      fileName,
      mode: PlayerMode.LOW_LATENCY,
    );
  }
}
