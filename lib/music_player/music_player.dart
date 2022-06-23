import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Singleton for playing songs.
class MusicPlayer extends AudioPlayer {
  MusicPlayer._internal(); // Only way to access is through [instance]
  static final MusicPlayer instance = MusicPlayer._internal();

  /// Title of the current song, if any has been loaded.
  String? get songTitle => songTitleNotifier.value;
  set songTitle(String? value) => songTitleNotifier.value = value;
  ValueNotifier<String?> songTitleNotifier = ValueNotifier<String?>(null);

  /// How much the pitch will be shifted, in semitones.
  double get pitchSemitones => (12 * log(pitch) / log(2)).toDouble();

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(final double semitones) async {
    await setPitch(pow(2, semitones / 12).toDouble());
  }
}
