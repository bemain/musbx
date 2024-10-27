import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/songs/player/music_player.dart';
import 'package:musbx/songs/player/music_player_component.dart';
import 'package:musbx/widgets/widgets.dart';

/// A component for [MusicPlayer] that is used to adjust the gain for different frequency bands.
class Equalizer extends MusicPlayerComponent {
  /// The [AndroidEqualizer] used internally.
  final AndroidEqualizer androidEqualizer = AndroidEqualizer();

  /// The parameters of this equalizer, or null if no song has been loaded.
  AndroidEqualizerParameters? get parameters => parametersNotifier.value;
  final ValueNotifier<AndroidEqualizerParameters?> parametersNotifier =
      ValueNotifier(null);

  /// Reset the gain on all bands in [parameters].
  ///
  /// If [parameters] is null, does nothing.
  void resetGain() {
    if (parameters == null) return;

    for (var band in parameters!.bands) {
      band.setGain((parameters!.maxDecibels + parameters!.minDecibels) / 2);
    }
  }

  @override
  void initialize(MusicPlayer musicPlayer) {
    if (Platform.isIOS) return; // TODO: Implement Equalizer on iOS

    enabledNotifier.addListener(() {
      androidEqualizer.setEnabled(enabled);
    });
    androidEqualizer.setEnabled(enabled); // Trigger initial enable

    androidEqualizer.parameters.then(
      (value) {
        parametersNotifier.value = value;
        resetGain();
      },
    );
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond `enabled`):
  ///  - `gain` [Map<String, double>] The gain for the frequency bands, with the key being the index of the band (usually 0-4) and the value being the gain.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) async {
    super.loadSettingsFromJson(json);

    if (Platform.isIOS) return;

    final double defaultGain =
        (parameters!.minDecibels + parameters!.maxDecibels) / 2;

    final Map? gains = tryCast<Map>(json["gain"]);
    for (var i = 0; i < parameters!.bands.length; i++) {
      final double gain = tryCast<double>(gains?["$i"]) ?? defaultGain;
      parameters!.bands[i].setGain(gain.clamp(
        parameters!.minDecibels,
        parameters!.maxDecibels,
      ));
    }
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs (beyond `enabled`):
  ///  - `gain` [Map<String, double>] The gain for the frequency bands, with the key being the index of the band (usually 0-4) and the value being the gain.
  @override
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
      "gain": parameters?.bands
          .asMap()
          .map((index, band) => MapEntry("$index", band.gain)),
    };
  }
}
