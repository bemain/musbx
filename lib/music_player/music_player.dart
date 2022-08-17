import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Singleton for playing songs.
class MusicPlayer extends AudioPlayer {
  MusicPlayer._internal(); // Only way to access is through [instance]

  /// The instance of this singleton.
  static final MusicPlayer instance = MusicPlayer._internal();

  /// Title of the current song. If no song is loaded, will return `null`.
  String? get songTitle => songTitleNotifier.value;
  set songTitle(String? value) => songTitleNotifier.value = value;
  ValueNotifier<String?> songTitleNotifier = ValueNotifier<String?>(null);

  /// How much the pitch will be shifted, in semitones.
  double get pitchSemitones => (12 * log(pitch) / log(2)).toDouble();

  /// How much the pitch will be shifted, in semitones.
  Stream<double> get pitchSemitonesStream => pitchStream
      .map((double pitch) => (12 * log(pitch) / log(2)).roundToDouble());

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(double semitones) async {
    await setPitch(pow(2, semitones / 12).toDouble());
  }
}
