import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// ignore: implementation_imports
import 'package:flutter_soloud/src/filters/equalizer_filter.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/widgets/widgets.dart';

class EqualizerBand {
  /// The minimum value for the [gain].
  static const double minGain = 0.0;

  /// The maximum value for the [gain].
  static const double maxGain = 4.0;

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
  static const double defaultGain = 1.0;

  /// TODO: Simply activating this causes lots of artifacts at the moment, not sure why
  EqualizerComponent(super.player);

  /// Modify the equalizer filter for the current song.
  ///
  /// Note that this cannot be used to activate or deactivate the filter, since
  /// that has to be done before the song is loaded and [player.handle] thus
  /// isn't available at that time.
  void _modifyEqualizerFilter(
      void Function(EqualizerSingle filter, {SoundHandle? handle}) modify) {
    player.playable.filters(handle: player.handle).equalizer.modify(modify);
  }

  @override
  void initialize() {
    // TODO: Activate the equalizer once we find out what is causing the noise
    // player.playable.filters().pitchShift.activate();
  }

  @override
  void dispose() {
    player.playable.filters().pitchShift.deactivate();
  }

  /// The frequency bands of the equalizer.
  List<EqualizerBand> get bands => bandsNotifier.value;
  late final EqualizerBandsNotifier bandsNotifier = EqualizerBandsNotifier(
      List.unmodifiable(List.generate(8, (index) => EqualizerBand())))
    ..addListener(_updateBands);

  void _updateBands() {
    _modifyEqualizerFilter((filter, {SoundHandle? handle}) {
      for (int i = 0; i < bands.length; i++) {
        [
          filter.band1,
          filter.band2,
          filter.band3,
          filter.band4,
          filter.band5,
          filter.band6,
          filter.band7,
          filter.band8,
        ][i](soundHandle: handle)
            .value = bands[i].gain;
      }
    });
  }

  /// Reset the gain on all [bands].
  void resetGain() {
    for (var band in bands) {
      band.gain = defaultGain;
    }
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond `enabled`):
  ///  - `gain` [Map<String, double>] The gain for the frequency bands, with the key being the index of the band (usually 0-4) and the value being the gain.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) async {
    super.loadSettingsFromJson(json);

    final Map? gains = tryCast<Map>(json["gain"]);
    for (var i = 0; i < bands.length; i++) {
      final double gain = tryCast<double>(gains?["$i"]) ?? defaultGain;
      bands[i].gain = gain;
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
      "gain": bands.asMap().map((index, band) => MapEntry("$index", band.gain)),
    };
  }
}
