import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/audio_handler.dart';

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

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(double semitones) async {
    await setPitch(pow(2, semitones / 12).toDouble());
  }

  Future<void> playFile(PlatformFile file) async {
    songTitle = file.name;
    await setFilePath(file.path!);
    MyAudioHandler.instance.mediaItem.add(MediaItem(
      id: file.path!,
      title: file.name,
      duration: duration,
    ));
  }
}
