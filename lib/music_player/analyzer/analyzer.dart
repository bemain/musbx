import 'package:musbx/music_player/analyzer/chord_identification_process.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/music_player/song.dart';

/// A component for [MusicPlayer] that is used to analyze the current song,
/// including chord identification and waveform analysis.
class Analyzer extends MusicPlayerComponent {
  /// The chords of the current song,
  /// or `null` if no song has been loaded or the song hasn't been analyzed yet.
  ChordIdentificationProcess? chordsProcess;

  @override
  void initialize(MusicPlayer musicPlayer) {
    // When the song changes, begin chord identification.
    musicPlayer.songNotifier.addListener(() async {
      chordsProcess = null;
      final Song? song = musicPlayer.song;
      if (song == null) return;

      chordsProcess = ChordIdentificationProcess(song);
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
