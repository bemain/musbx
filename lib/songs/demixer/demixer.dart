import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/widgets.dart';

/// The stems that can be requested from the server.
enum StemType {
  vocals,
  piano,
  guitar,
  bass,
  drums,
  other,
}

class Stem {
  /// The default [volume]
  static const double defaultVolume = 0.5;

  static final SoLoud _soloud = SoLoud.instance;

  /// A demixed stem for a song. Can be played back in sync with other stems.
  ///
  /// There should (usually) only ever be one stem of each [type].
  Stem(this.type, this.player);

  /// The player that this is a part of.
  final MultiPlayer player;

  /// The type of stem.
  final StemType type;

  /// The source of the stem with the same [type] as this.
  AudioSource? get source => player.sources[type];

  /// The handle of the stem with the same [type] as this.
  SoundHandle? get handle => player.handles[type];

  /// Whether this stem is enabled and should be played.
  ///
  /// If this is `false` the audio will be muted, regardless of the value of [volume].
  bool get enabled => enabledNotifier.value;
  set enabled(bool value) => enabledNotifier.value = value;
  late final ValueNotifier<bool> enabledNotifier = ValueNotifier(true)
    ..addListener(_updateEnabled);

  void _updateEnabled() {
    final SoundHandle? handle = this.handle;
    if (handle == null) return;

    if (enabled) {
      _soloud.setVolume(handle, volume);
    } else {
      _soloud.setVolume(handle, 0.0);
    }
  }

  /// The volume this stem is played at. The value is clamped between 0 and 1.
  double get volume => volumeNotifier.value;
  set volume(double value) => volumeNotifier.value = value.clamp(0, 1);
  late final ValueNotifier<double> volumeNotifier = ValueNotifier(
    defaultVolume,
  )..addListener(_updateVolume);

  void _updateVolume() {
    final SoundHandle? handle = this.handle;
    if (handle == null) return;

    if (enabled) {
      _soloud.setVolume(handle, volume);
    }
  }
}

class StemsNotifier extends ValueNotifier<List<Stem>> {
  /// Notifies listeners whenever [enabled] or [volume] of any of the stems provided in [value] changes.
  StemsNotifier(super.value) {
    for (Stem stem in value) {
      stem.enabledNotifier.addListener(notifyListeners);
      stem.volumeNotifier.addListener(notifyListeners);
    }
  }
}

class DemixerComponent extends SongPlayerComponent<MultiPlayer> {
  /// A component of the [MultiPlayer] that is used to separate a song into stems and change the volume of those individually.
  DemixerComponent(super.player);

  /// The stems that this song has been separated into.
  List<Stem> get stems => stemsNotifier.value;
  late final StemsNotifier stemsNotifier = StemsNotifier(
    List.unmodifiable([
      Stem(StemType.vocals, player),
      Stem(StemType.piano, player),
      Stem(StemType.guitar, player),
      Stem(StemType.bass, player),
      Stem(StemType.drums, player),
      Stem(StemType.other, player),
    ]),
  )..addListener(notifyListeners);

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following stems:
  ///  - `drums`
  ///  - `piano`
  ///  - `guitar`
  ///  - `bass`
  ///  - `vocals`
  ///  - `other`
  ///
  /// Each stem can contain the following key-value pairs:
  ///  - `enabled` [bool] Whether this stem is enabled and should be played.
  ///  - `volume` [double] The volume this stem is played back at. Must be between 0 and 1.
  @override
  void loadPreferencesFromJson(Json json) {
    super.loadPreferencesFromJson(json);

    for (Stem stem in stems) {
      Json? stemData = tryCast<Json>(
        json[stem.type.name],
      );

      bool? enabled = tryCast<bool>(stemData?['enabled']);
      stem.enabled = enabled ?? true;

      double? volume = tryCast<double>(stemData?['volume']);
      stem.volume = volume ?? 0.5;
    }

    notifyListeners();
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following stems:
  ///  - `drums`
  ///  - `piano`
  ///  - `guitar`
  ///  - `bass`
  ///  - `vocals`
  ///  - `other`
  ///
  /// Each stem contains the following key-value pairs:
  ///  - `enabled` [bool] Whether this stem is enabled and should be played.
  ///  - `volume` [double] The volume this stem is played back at. Must be between 0 and 1.
  @override
  Json savePreferencesToJson() {
    return {
      ...super.savePreferencesToJson(),
      for (Stem stem in stems)
        stem.type.name: {
          "enabled": stem.enabled,
          "volume": stem.volume,
        },
    };
  }
}
