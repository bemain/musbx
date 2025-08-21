import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// ignore: implementation_imports
import 'package:flutter_soloud/src/filters/equalizer_filter.dart';
import 'package:musbx/songs/player/filter.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/widgets.dart';

class EqualizerBand {
  /// The minimum value for the [gain].
  static const double minGain = 0.0;

  /// The default value for the [gain].
  static const double defaultGain = 1.0;

  /// The maximum value for the [gain].
  ///
  /// [SoLoud] technically allows values up to 4.0, but too high values makes
  /// the audio very distorted.
  static const double maxGain = 2.0;

  /// The gain for this band. Must be between [minGain] and [maxGain] (since that is the range SoLoud allows).
  double get gain => gainNotifier.value;
  set gain(double value) => gainNotifier.value = value.clamp(minGain, maxGain);
  late final ValueNotifier<double> gainNotifier = ValueNotifier(1.0);
}

class EqualizerBandsNotifier extends ValueNotifier<List<EqualizerBand>> {
  /// Notifies listeners whenever [gain] of any of the bands provided in [value] changes.
  EqualizerBandsNotifier(super.value) {
    for (EqualizerBand band in value) {
      band.gainNotifier.addListener(notifyListeners);
    }
  }
}

class EqualizerComponent extends SongPlayerComponent {
  EqualizerComponent(super.player);

  /// The equalizer filter, provided by [SoLoud].
  Filter<EqualizerSingle> get filter =>
      player.playable.filters(handle: player.handle).equalizer;

  @override
  Future<void> initialize() async {
    // Note that this activation is redundant.
    // We have to activate the filter before the sound is played, and so we
    // activate it already when the [Playable] is created.
    filter.activate();
  }

  @override
  void dispose() {
    filter.deactivate();
    super.dispose();
  }

  /// The frequency bands of the equalizer.
  List<EqualizerBand> get bands => bandsNotifier.value;
  late final EqualizerBandsNotifier bandsNotifier = EqualizerBandsNotifier(
    List.unmodifiable(
      List.generate(
        8,
        (index) =>
            EqualizerBand()
              ..gainNotifier.addListener(() => _updateBand(index)),
      ),
    ),
  )..addListener(notifyListeners);

  void _updateBand(int index) {
    filter.modify(
      (filter, {handle}) {
        [
          filter.band1,
          filter.band2,
          filter.band3,
          filter.band4,
          filter.band5,
          filter.band6,
          filter.band7,
          filter.band8,
        ][index](soundHandle: handle).value = bands[index].gain;
      },
    );
  }

  /// Reset the gain on all [bands].
  void resetGain() {
    for (var band in bands) {
      band.gain = EqualizerBand.defaultGain;
    }
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs:
  ///  - `gain` [Map<String, double>] The gain for the frequency bands, with the key being the index of the band (usually 0-4) and the value being the gain.
  @override
  Future<void> loadPreferencesFromJson(Json json) async {
    super.loadPreferencesFromJson(json);

    final Json? gains = tryCast<Json>(
      json['gain'],
    );
    for (var i = 0; i < bands.length; i++) {
      final double gain =
          tryCast<double>(gains?['$i']) ?? EqualizerBand.defaultGain;
      bands[i].gain = gain;
    }

    notifyListeners();
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs:
  ///  - `gain` [Map<String, double>] The gain for the frequency bands, with the key being the index of the band (usually 0-4) and the value being the gain.
  @override
  Json savePreferencesToJson() {
    return {
      ...super.savePreferencesToJson(),
      "gain": bands.asMap().map(
        (index, band) => MapEntry("$index", band.gain),
      ),
    };
  }
}
