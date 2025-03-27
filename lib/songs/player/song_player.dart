import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// ignore: implementation_imports
import 'package:flutter_soloud/src/filters/pitchshift_filter.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
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
  final SongPlayer player;

  /// The type of stem.
  final StemType type;

  /// The source of the stem of the [player]'s [Playable] with the same [type] as this, if it is a [DemixedAudio].
  AudioSource? get source {
    if (player.playable is! DemixedAudio) return null;

    return (player.playable as DemixedAudio).sources[type];
  }

  /// The handle of the stem of the [player]'s [Playable] with the same [type] as this, if it is a [DemixedAudio].
  SoundHandle? get handle {
    if (player.playable is! DemixedAudio) return null;

    return (player.playable as DemixedAudio).handles?[type];
  }

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

abstract class SongPlayerComponent {
  SongPlayerComponent(this.player);

  /// The player that this is a part of.
  final SongPlayer player;

  /// Initialize and activate this component.
  ///
  /// Called when the [player] is created.
  FutureOr<void> initialize() async {}

  /// Free the resources used by this component.
  ///
  /// Called when the [player] that this is part of disposed.
  FutureOr<void> dispose() async {}

  /// Load settings for a song from a [json] map.
  ///
  /// Called when a song that has preferences saved is loaded.
  ///
  /// Implementations should be able to handle a value being null,
  /// and never expect a specific key to exist.
  @mustCallSuper
  void loadSettingsFromJson(Map<String, dynamic> json) {}

  /// Save settings for a song to a json map.
  @mustCallSuper
  Map<String, dynamic> saveSettingsToJson() {
    return {};
  }
}

class SongDemixer extends SongPlayerComponent {
  /// A component of the [SongPlayer] that is used to separate a song into stems and change the volume of those individually.
  SongDemixer(
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

class SongSlowdowner extends SongPlayerComponent {
  SongSlowdowner(super.player);

  /// Modify the pitch filter of the [player]'s [Playable]'s [AudioSource] using
  /// the provided [modify].
  ///
  /// Note that some [Playable]s use multiple [AudioSource]s under the hood, so
  /// [modify] might be called multiple times.
  void _modifyPitchFilter(void Function(PitchShiftSingle filter) modify) {
    switch (player.playable) {
      case DemixedAudio playable:
        for (AudioSource source in playable.sources.values) {
          modify(source.filters.pitchShiftFilter);
        }
      case FileAudio playable:
        modify(playable.source.filters.pitchShiftFilter);
    }
  }

  @override
  void initialize() {
    _modifyPitchFilter((filter) {
      if (!filter.isActive) filter.activate();
    });
  }

  @override
  void dispose() {
    _modifyPitchFilter((filter) {
      if (filter.isActive) filter.deactivate();
    });
  }

  /// How much the pitch will be shifted, in semitones.
  double get pitch => pitchNotifier.value;
  set pitch(double value) => pitchNotifier.value = value;
  late final ValueNotifier<double> pitchNotifier = ValueNotifier(0)
    ..addListener(_updatePitch);

  void _updatePitch() {
    _modifyPitchFilter((filter) {
      filter.semitones(soundHandle: player.handle).value = pitch;
    });
  }

  /// The playback speed.
  double get speed => speedNotifier.value;
  set speed(double value) => speedNotifier.value = value;
  late final ValueNotifier<double> speedNotifier = ValueNotifier(1)
    ..addListener(_updateSpeed);

  void _updateSpeed() {
    SoLoud.instance.setRelativePlaySpeed(player.handle, speed);
    _modifyPitchFilter((filter) {
      filter.shift(soundHandle: player.handle).value = 1 / speed;
    });
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs:
  ///  - `pitch` [double] How much the pitch will be shifted, in semitones.
  ///  - `speed` [double] The playback speed of the audio, as a fraction.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) {
    super.loadSettingsFromJson(json);

    final double? pitch = tryCast<double>(json["pitch"]);
    final double? speed = tryCast<double>(json["speed"]);

    this.pitch = pitch?.clamp(-12, 12) ?? 0.0;
    this.speed = speed?.clamp(0.5, 2) ?? 1.0;
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs:
  ///  - `pitch` [double] How much the pitch will be shifted, in semitones.
  ///  - `speed` [double] The playback speed of the audio, as a fraction.
  @override
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
      "pitch": pitch,
      "speed": speed,
    };
  }
}

class SongPlayer {
  static final SoLoud _soloud = SoLoud.instance;

  SongPlayer._(this.song, this.playable);

  /// Create a [SongPlayer] by loading a [song].
  ///
  /// The workflow is as follows:
  ///  - Load the [song.source], to obtain a [playable].
  ///  - Play the [playable], to obtain a sound [handle].
  ///  - Initialize [components].
  static Future<SongPlayer> load(SongNew song) async {
    final Playable playable = await song.source.load();

    final SongPlayer player = SongPlayer._(song, playable);

    for (final SongPlayerComponent component in player.components) {
      await component.initialize();
    }

    player.handle = await playable.play();

    return player;
  }

  /// The song that this player plays.
  final SongNew song;

  /// The object created from [song.source], that in turn created the current song [handle].
  final Playable playable;

  /// Handle for the sound that is playing.
  ///
  /// Currently this is set after creation, so that the [components] can be
  /// initialized before the sound starts playing. Otherwise filters won't be applied.
  /// This is ugly though, and we should find a better solution.
  late final SoundHandle handle;

  /// Whether the player is currently playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? resume() : pause();
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Pause playback.
  void pause() {
    _soloud.setPause(handle, true);
    isPlayingNotifier.value = false;
  }

  /// Resume playback.
  void resume() {
    _soloud.setPause(handle, false);
    isPlayingNotifier.value = true;
  }

  /// Stop playback, and free the resources used by this player.
  ///
  /// See also:
  ///  - [Playable.dispose]
  ///  - [SongPlayerComponent.dispose]
  Future<void> dispose() async {
    pause();
    isPlayingNotifier.value = false;

    for (SongPlayerComponent component in components) {
      await component.dispose();
    }

    await playable.dispose();
  }

  /// The duration of the audio that is playing.
  Duration get duration => playable.duration;

  /// The current position of the player.
  Duration get position => _soloud.getPosition(handle);

  /// Create a stream that yield the current [position] at regular [interval]s.
  ///
  /// Yields data immediately upon creation, so there is always data in the stream.
  ///
  /// The stream is efficient, and only yields the position if it has changed.
  /// TODO: Check that this stops when the subscription is cancelled.
  Stream<Duration> createPositionStream([
    Duration interval = const Duration(milliseconds: 100),
  ]) async* {
    Duration lastPosition = position;
    yield lastPosition;

    while (true) {
      if (lastPosition != position) {
        lastPosition = position;
        yield position;
      }
      await Future.delayed(interval);
    }
  }

  /// Seek to a [position] in the current song.
  void seek(Duration position) {
    if (handle != null) _soloud.seek(handle!, position);
  }

  /// The components that extend the functionality of this player.
  late final List<SongPlayerComponent> components = [demixer, slowdowner];

  /// Component for isolating or muting specific instruments in the song.
  late final SongDemixer demixer = SongDemixer(this);

  late final SongSlowdowner slowdowner = SongSlowdowner(this);

  /// Load song preferences from a [json] map.
  void loadPreferences(Map<String, dynamic> json) {
    int? position = tryCast<int>(json["position"]);
    seek(Duration(milliseconds: position ?? 0));

    slowdowner.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["slowdowner"]) ?? {},
    );
    // looper.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["looper"]) ?? {},
    // );
    // equalizer.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["equalizer"]) ?? {},
    // );
    demixer.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["demixer"]) ?? {},
    );
    // analyzer.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["analyzer"]) ?? {},
    // );
  }

  /// Create a json map containing the current preferences for this [song].
  Map<String, dynamic> toPreferences() {
    return {
      "position": position.inMilliseconds,
      "slowdowner": slowdowner.saveSettingsToJson(),
      // "looper": looper.saveSettingsToJson(),
      // "equalizer": equalizer.saveSettingsToJson(),
      "demixer": demixer.saveSettingsToJson(),
      // "analyzer": analyzer.saveSettingsToJson(),
    };
  }
}
