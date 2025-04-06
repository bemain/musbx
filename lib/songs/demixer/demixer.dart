import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/widgets/widgets.dart';

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

  /// The source of the stem of the [player]'s [Playable] with the same [type] as this, if it is a [MultiPlayable].
  AudioSource? get source => player.playable.sources[type];

  /// The handle of the stem of the [player]'s [Playable] with the same [type] as this, if it is a [MultiPlayable].
  SoundHandle? get handle => player.playable.handles?[type];

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
  late final ValueNotifier<double> volumeNotifier = ValueNotifier(defaultVolume)
    ..addListener(_updateVolume);

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
  DemixerComponent(
    super.player,
  );

  /// The stems that this song has been separated into.
  List<Stem> get stems => stemsNotifier.value;
  late final StemsNotifier stemsNotifier = StemsNotifier(List.unmodifiable([
    Stem(StemType.drums, player),
    Stem(StemType.piano, player),
    Stem(StemType.guitar, player),
    Stem(StemType.bass, player),
    Stem(StemType.vocals, player),
    Stem(StemType.other, player),
  ]));

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
  void loadSettingsFromJson(Map<String, dynamic> json) {
    super.loadSettingsFromJson(json);

    for (Stem stem in stems) {
      Map<String, dynamic>? stemData =
          tryCast<Map<String, dynamic>>(json[stem.type.name]);

      bool? enabled = tryCast<bool>(stemData?["enabled"]);
      stem.enabled = enabled ?? true;

      double? volume = tryCast<double>(stemData?["volume"]);
      stem.volume = volume ?? 0.5;
    }
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
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
      for (Stem stem in stems)
        stem.type.name: {
          "enabled": stem.enabled,
          "volume": stem.volume,
        }
    };
  }
}
