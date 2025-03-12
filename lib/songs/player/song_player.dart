import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// ignore: implementation_imports
import 'package:flutter_soloud/src/filters/pitchshift_filter.dart';
import 'package:musbx/songs/demixer/demixing_process_new.dart';
import 'package:musbx/songs/musbx_api/demixer_api.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_source.dart';
import 'package:musbx/widgets/widgets.dart';

class Stem {
  /// The default [volume]
  static const double defaultVolume = 0.5;

  static final SoLoud _soLoud = SoLoud.instance;

  /// A demixed stem for a song. Can be played back in sync with other stems.
  ///
  /// There should (usually) only ever be one stem of each [type].
  Stem(this.type);

  /// The type of stem.
  final StemType type;

  /// Whether the audio for this stem has been loaded.
  ///
  /// If this is `true`, [source] and [handle] have been set.
  bool isAudioLoaded = false;

  /// Whether this stem is enabled and should be played.
  ///
  /// If this is `false` the audio will be muted, regardless of the value of [volume].
  bool get enabled => enabledNotifier.value;
  set enabled(bool value) => enabledNotifier.value = value;
  late final ValueNotifier<bool> enabledNotifier = ValueNotifier(true)
    ..addListener(_updateEnabled);

  void _updateEnabled() {
    if (!isAudioLoaded) return;

    if (enabled) {
      _soLoud.setVolume(handle, volume);
    } else {
      _soLoud.setVolume(handle, 0.0);
    }
  }

  /// The volume this stem is played at. The value is clamped between 0 and 1.
  double get volume => volumeNotifier.value;
  set volume(double value) => volumeNotifier.value = value.clamp(0, 1);
  late final ValueNotifier<double> volumeNotifier = ValueNotifier(defaultVolume)
    ..addListener(_updateVolume);

  void _updateVolume() {
    if (!isAudioLoaded) return;

    if (enabled) {
      _soLoud.setVolume(handle, volume);
    }
  }

  /// The source of the audio for this stem, playable by [SoLoud].
  ///
  /// Before accessing this, make sure [isAudioLoaded] is true by calling [loadAudio].
  late final AudioSource source;

  /// Handle to the sound that is played by this stem.
  ///
  /// Before accessing this, make sure [isAudioLoaded] is true by calling [loadAudio].
  late final SoundHandle handle;

  /// Load the audio for this stem from a [file].
  ///
  /// If [isAudioLoaded] is `true`, does nothing.
  Future<void> loadAudio(File file) async {
    if (isAudioLoaded) return;
    isAudioLoaded = true;

    source = await SoLoud.instance.loadFile(file.path);
    handle = await SoLoud.instance.play(source, paused: true);
  }

  /// Free the resources used by this stem.
  ///
  /// If [isAudioLoaded] is `false`, does nothing.
  Future<void> dispose() async {
    if (!isAudioLoaded) return;

    await SoLoud.instance.stop(handle);
    await SoLoud.instance.disposeSource(source);

    isAudioLoaded = false;
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
  static final SoLoud _soLoud = SoLoud.instance;

  /// A component of the [SongPlayer] that is used to separate a song into stems and change the volume of those individually.
  SongDemixer(super.player);

  /// The stems that this song has been separated into.
  List<Stem> get stems => stemsNotifier.value;
  final StemsNotifier stemsNotifier = StemsNotifier(List.unmodifiable([
    Stem(StemType.drums),
    Stem(StemType.piano),
    Stem(StemType.guitar),
    Stem(StemType.bass),
    Stem(StemType.vocals),
    Stem(StemType.other),
  ]));

  /// TODO: Make it possible to pause this.
  late final DemixingProcess process = DemixingProcess(player.song)
    ..resultNotifier.addListener(() async {
      if (!process.hasResult) return;

      for (final Stem stem in stems) {
        await stem.loadAudio(process.result![stem.type]!);
      }
      _soLoud.addVoicesToGroup(
        groupHandle,
        [for (final Stem stem in stems) stem.handle],
      );
    });

  final SoundHandle groupHandle = _soLoud.createVoiceGroup();

  @override
  Future<void> dispose() async {
    process.cancel();

    await _soLoud.stop(groupHandle);
    _soLoud.destroyVoiceGroup(groupHandle);

    for (final Stem stem in stems) {
      await stem.dispose();
    }
  }

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
  static final SoLoud _soLoud = SoLoud.instance;

  SongSlowdowner(super.player);

  @override
  void initialize() {
    // FIXME: This is called after the audio has begin playing, so it will have no effect (probably)
    _pitchShiftFilter.activate();
  }

  @override
  void dispose() {
    // _pitchShiftFilter.deactivate();
  }

  PitchShiftSingle get _pitchShiftFilter =>
      player._source.filters.pitchShiftFilter;

  /// How much the pitch will be shifted, in semitones.
  double get pitch => pitchNotifier.value;
  set pitch(double value) => pitchNotifier.value = value;
  late final ValueNotifier<double> pitchNotifier = ValueNotifier(0)
    ..addListener(_updatePitch);

  void _updatePitch() {
    _pitchShiftFilter.semitones().value = pitch;
  }

  /// The playback speed.
  double get speed => speedNotifier.value;
  set speed(double value) => speedNotifier.value = value;
  late final ValueNotifier<double> speedNotifier = ValueNotifier(1)
    ..addListener(_updateSpeed);

  void _updateSpeed() {
    _soLoud.setRelativePlaySpeed(player._handle, speed);
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond `enabled`):
  ///  - `pitchSemitones` [double] How much the pitch will be shifted, in semitones.
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
  /// Saves the following key-value pairs (beyond `enabled`):
  ///  - `pitchSemitones` [double] How much the pitch will be shifted, in semitones.
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

  /// Constructor used internally.
  ///
  /// Assumes the [song.source] to already be loaded.
  SongPlayer._(this.song, this._handle, this._source);

  /// Create a [SongPlayer] by loading a [song].
  ///
  /// Loads the [song.source] and retrieves a [_handle] for the song from [SoLoud].
  static Future<SongPlayer> load(Song song) async {
    final AudioSource source = await song.source.load();
    final SoundHandle handle = await _soloud.play(source, paused: true);

    final SongPlayer player = SongPlayer._(song, handle, source);

    for (final SongPlayerComponent component in player.components) {
      await component.initialize();
    }

    return player;
  }

  /// The song that this player plays.
  final Song song;

  /// Handle to the loaded song.
  final SoundHandle _handle;

  /// The source of the loaded song.
  final AudioSource _source;

  /// Whether the player is currently playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? resume() : pause();
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Pause playback.
  void pause() {
    _soloud.setPause(_handle, true);
    isPlayingNotifier.value = false;
  }

  /// Resume playback.
  void resume() {
    _soloud.setPause(_handle, false);
    isPlayingNotifier.value = true;
  }

  /// Stop playback, and free the resources used by this player.
  ///
  /// See also:
  ///  - [SongSource.dispose]
  ///  - [SongPlayerComponent.dispose]
  Future<void> dispose() async {
    await _soloud.stop(_handle);
    isPlayingNotifier.value = false;

    for (SongPlayerComponent component in components) {
      await component.dispose();
    }

    await _soloud.disposeSource(_source);
  }

  /// The duration of the audio.
  Duration get duration => SoLoud.instance.getLength(_source);

  /// The current position of the player.
  Duration get position => _soloud.getPosition(_handle);

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
    if (_handle != null) _soloud.seek(_handle!, position);
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
