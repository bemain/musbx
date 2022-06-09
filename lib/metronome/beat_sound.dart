import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum BeatSound {
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

  const BeatSound({required this.fileName, required this.color});

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
