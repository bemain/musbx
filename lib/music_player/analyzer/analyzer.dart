import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/music_player/analyzer/chord_identification_process.dart';
import 'package:musbx/music_player/analyzer/waveform_extraction_process.dart';
import 'package:musbx/model/chord.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/widgets.dart';

/// A component for [MusicPlayer] that is used to analyze the current song,
/// including chord identification and waveform extraction.
class Analyzer extends MusicPlayerComponent {
  static const Duration minDurationShown = Duration(seconds: 5);
  static const Duration maxDurationShown = Duration(seconds: 10);

  /// The duration window around the current position shown by widgets.
  Duration get durationShown => durationShownNotifier.value;
  set durationShown(Duration value) => durationShownNotifier.value =
      value.clamp(minDurationShown, maxDurationShown);
  final ValueNotifier<Duration> durationShownNotifier =
      ValueNotifier(const Duration(seconds: 5));

  /// The process analyzing the chords of the current song,
  /// or `null` if no song has been loaded.
  ChordIdentificationProcess? chordsProcess;

  /// The transposed chords of the current song,
  /// or `null` if no song has been loaded.
  Map<Duration, Chord?>? get chords => chordsNotifier.value;
  final ValueNotifier<Map<Duration, Chord?>?> chordsNotifier =
      ValueNotifier(null);

  /// The process extracting the waveform from the current song,
  /// or `null` if no song has been loaded.
  WaveformExtractionProcess? waveformProcess;

  /// The waveform extracted from the current song,
  /// or `null` if no song has been loaded.
  Waveform? get waveform => waveformNotifier.value;
  final ValueNotifier<Waveform?> waveformNotifier = ValueNotifier(null);

  @override
  void initialize(MusicPlayer musicPlayer) {
    // When the song changes, begin analyzing.
    musicPlayer.songNotifier.addListener(() {
      chordsNotifier.value = null;
      waveformNotifier.value = null;

      final Song? song = musicPlayer.song;
      if (song == null) return;

      chordsProcess = ChordIdentificationProcess(song)
        ..addListener(_updateChords);
      waveformProcess = WaveformExtractionProcess(song)
        ..addListener(() {
          waveformNotifier.value = waveformProcess?.result;
        });
    });

    musicPlayer.slowdowner.pitchSemitonesNotifier.addListener(_updateChords);
  }

  void _updateChords() {
    chordsNotifier.value = chordsProcess?.result?.map(
      (key, value) => MapEntry(
        key,
        value?.transposed(
          MusicPlayer.instance.slowdowner.pitchSemitones.round(),
        ),
      ),
    );
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond `enabled`):
  ///  - `durationShown` [int] The duration window around the current position shown by widgets, in milliseconds.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) {
    super.loadSettingsFromJson(json);

    int? durationShown = tryCast<int>(json["durationShown"]);
    if (durationShown != null) {
      this.durationShown = Duration(milliseconds: durationShown);
    }
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs (beyond `enabled`):
  ///  - `durationShown` [int] The duration window around the current position shown by widgets, in milliseconds.
  @override
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
      "durationShown": durationShown.inMilliseconds,
    };
  }
}
