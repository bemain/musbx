import 'dart:math';

import 'package:just_audio/just_audio.dart';

class Slowdowner {
  static final AudioPlayer audioPlayer = AudioPlayer();

  static double get pitchSemitones =>
      (12 * log(audioPlayer.pitch) / log(2)).toDouble();
  static setPitchSemitones(double value) {
    audioPlayer.setPitch(pow(2, value / 12).toDouble());
  }
}
