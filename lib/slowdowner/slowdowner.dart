import 'dart:math';

import 'package:just_audio/just_audio.dart';

/// Singleton for playing songs.
class Slowdowner extends AudioPlayer {
  Slowdowner._internal(); // Only way to access is through [instance]
  static final Slowdowner instance = Slowdowner._internal();

  /// Title of the current song, if any has been loaded.
  String? songTitle;

  /// How much the pitch will be shifted, in semitones.
  double get pitchSemitones => (12 * log(pitch) / log(2)).toDouble();

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(final double semitones) async {
    await setPitch(pow(2, semitones / 12).toDouble());
  }
}
