import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// ignore: implementation_imports
import 'package:flutter_soloud/src/filters/parametric_eq.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/songs/player/filter.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/utils/utils.dart';

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
  /// The minimum number of frequency bands.
  static const int minNumBands = 4;

  /// The default number of frequency bands.
  static const int defaultNumBands = 5;

  /// The maximum number of frequency bands.
  static const int maxNumBands = 15;

  EqualizerComponent(super.player) {
    numBands = defaultNumBands;
  }

  /// The equalizer filter, provided by [SoLoud].
  Filter<ParametricEqSingle> get filter => player.filters.equalizer;

  @override
  Future<void> initialize() async {
    // Note that this activation is redundant.
    // We have to activate the filter before the sound is played, and so we
    // activate it already when the [SongPlayer] is created.
    filter.activate();
  }

  @override
  void dispose() {
    filter.deactivate();
    super.dispose();
  }

  /// The number of frequency bands used.
  int get numBands => bands.length;
  set numBands(int value) {
    value = value.clamp(minNumBands, maxNumBands);
    filter.modify(
      (filter, {handle}) {
        filter.numBands(soundHandle: handle).value = numBands.toDouble();
      },
    );

    var newBands = bands.sublist(0, min(value, bands.length));
    while (newBands.length < value) {
      final int index = newBands.length;
      newBands.add(
        EqualizerBand()..gainNotifier.addListener(() => _updateBand(index)),
      );
    }
    bandsNotifier.value = List.unmodifiable(newBands);
  }

  /// The frequency bands of the equalizer.
  List<EqualizerBand> get bands => bandsNotifier.value;
  late final ValueNotifier<List<EqualizerBand>> bandsNotifier = ValueNotifier(
    List.unmodifiable([]),
  )..addListener(notifyListeners);

  void _updateBand(int index) {
    filter.modify(
      (filter, {handle}) {
        filter.bandGain(index, soundHandle: handle).value = bands[index].gain;
      },
    );

    notifyListeners();
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
  ///  - `bands` [int] The number of frequency bands.
  ///  - `gain` [Map<String, double>] The gain for the frequency bands, with the key being the index of the band (usually 0-4) and the value being the gain.
  @override
  Future<void> loadPreferencesFromJson(Json json) async {
    super.loadPreferencesFromJson(json);

    final int? numBands = tryCast<int>(json['bands']);
    this.numBands = numBands ?? defaultNumBands;

    final Json? gains = tryCast<Json>(json['gain']);
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
      "bands": numBands,
      "gain": bands.asMap().map(
        (index, band) => MapEntry("$index", band.gain),
      ),
    };
  }
}
