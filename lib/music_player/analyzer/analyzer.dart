import 'dart:io';

import 'package:musbx/music_player/analyzer/chord_identification_process.dart';
import 'package:musbx/music_player/analyzer/waveform_extraction_process.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/widgets.dart';

/// A component for [MusicPlayer] that is used to analyze the current song,
/// including chord identification and waveform extraction.
class Analyzer extends MusicPlayerComponent {
  /// The chords of the current song,
  /// or `null` if no song has been loaded.
  ChordIdentificationProcess? chordsProcess;

  /// The waveform extracted from the current song,
  /// or `null` if no song has been loaded.
  WaveformExtractionProcess? waveformProcess;

  /// The directory where files are saved.
  static final Future<Directory> analyzerDirectory =
      createTempDirectory("analyzer");

  @override
  void initialize(MusicPlayer musicPlayer) {
    // When the song changes, begin analyzing.
    musicPlayer.songNotifier.addListener(() {
      chordsProcess = null;
      final Song? song = musicPlayer.song;
      if (song == null) return;

      chordsProcess = ChordIdentificationProcess(song);
      waveformProcess = WaveformExtractionProcess(song);
    });
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond `enabled`):
  ///  - `start` [int] The start position of the section being looped, in milliseconds.
  ///  - `end` [int] The end position of the section being looped, in milliseconds.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) {
    super.loadSettingsFromJson(json);
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs (beyond `enabled`):
  ///  - `start` [int] The start position of the section being looped, in milliseconds.
  ///  - `end` [int] The end position of the section being looped, in milliseconds.
  @override
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
    };
  }
}
