import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:musbx/songs/analyzer/chord_identification_process.dart';
import 'package:musbx/songs/analyzer/waveform_extraction_process.dart';
import 'package:musbx/model/chord.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/widgets.dart';

class AnalyzerComponent extends SongPlayerComponent {
  static const Duration minDurationShown = Duration(seconds: 7);
  static const Duration maxDurationShown = Duration(seconds: 10);
  static const Duration defaultDurationShown = Duration(seconds: 8);

  AnalyzerComponent(super.player);

  @override
  void initialize() {
    player.slowdowner.pitchNotifier.addListener(_updateChords);
    waveformProcess.future;
    chordsProcess.future;
  }

  @override
  void dispose() {
    chordsProcess.cancel();
    waveformProcess.cancel();

    player.slowdowner.pitchNotifier.removeListener(_updateChords);
    super.dispose();
  }

  /// The duration window around the current position shown by widgets.
  Duration get durationShown => durationShownNotifier.value;
  set durationShown(Duration value) => durationShownNotifier.value =
      value.clamp(minDurationShown, maxDurationShown);
  late final ValueNotifier<Duration> durationShownNotifier =
      ValueNotifier(defaultDurationShown)..addListener(notifyListeners);

  /// The process analyzing the chords of the current song.
  late final ChordIdentificationProcess chordsProcess =
      ChordIdentificationProcess(player.song)
        ..resultNotifier.addListener(_updateChords);

  /// The transposed chords of the current song,
  /// or `null` if no song has been loaded.
  Map<Duration, Chord?>? get chords => chordsNotifier.value;
  final ValueNotifier<Map<Duration, Chord?>?> chordsNotifier =
      ValueNotifier(null);

  /// The process extracting the waveform from the current song,
  /// or `null` if no song has been loaded.
  ///
  /// TODO: Try reimplementing this using SoLoud.
  late final WaveformExtractionProcess waveformProcess =
      WaveformExtractionProcess(player.song)
        ..resultNotifier.addListener(() {
          waveformNotifier.value = waveformProcess.result;
        });

  /// The waveform extracted from the current song,
  /// or `null` if no song has been loaded.
  Waveform? get waveform => waveformNotifier.value;
  final ValueNotifier<Waveform?> waveformNotifier = ValueNotifier(null);

  void _updateChords() {
    chordsNotifier.value = chordsProcess.result?.map(
      (key, value) => MapEntry(
        key,
        value?.transposed(player.slowdowner.pitch.round()),
      ),
    );
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs:
  ///  - `durationShown` [int] The duration window around the current position shown by widgets, in milliseconds.
  @override
  void loadPreferencesFromJson(Map<String, dynamic> json) {
    super.loadPreferencesFromJson(json);

    int? durationShown = tryCast<int>(json["durationShown"]);
    this.durationShown = Duration(
      milliseconds: durationShown ?? defaultDurationShown.inMilliseconds,
    ).clamp(minDurationShown, maxDurationShown);

    notifyListeners();
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs:
  ///  - `durationShown` [int] The duration window around the current position shown by widgets, in milliseconds.
  @override
  Map<String, dynamic> savePreferencesToJson() {
    return {
      ...super.savePreferencesToJson(),
      "durationShown": durationShown.inMilliseconds,
    };
  }
}
