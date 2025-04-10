import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/analyzer/analyzer.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/equalizer/equalizer.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/slowdowner/slowdowner.dart';
import 'package:musbx/widgets/widgets.dart';

abstract class SongPlayerComponent<T extends SongPlayer> {
  SongPlayerComponent(this.player);

  /// The player that this is a part of.
  final T player;

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

abstract class SongPlayer<P extends Playable> {
  static final SoLoud _soloud = SoLoud.instance;

  SongPlayer._(this.song, this.playable, this.handle);

  /// Create a [SongPlayer] by loading a [song].
  ///
  /// This delegates the loading process to the correct implementation of this
  /// abstract class, depending on the type of the `Playable` ([P]).
  ///
  /// The workflow is as follows:
  ///  - Load the [song.source], to obtain a [playable].
  ///  - Play the [playable], to obtain a sound [handle].
  ///  - Initialize [components].
  static Future<SongPlayer<P>> load<P extends Playable>(
    SongNew<P> song,
  ) async {
    if (song.source is SongSourceNew<SinglePlayable>) {
      return await SinglePlayer.load(song as SongNew<SinglePlayable>)
          as SongPlayer<P>;
    } else if (song.source is SongSourceNew<MultiPlayable>) {
      return await MultiPlayer.load(song as SongNew<MultiPlayable>)
          as SongPlayer<P>;
    }

    throw ("No player exists for the given source ${song.source}");
  }

  /// The song that this player plays.
  final SongNew<P> song;

  /// The object created from [song.source], that in turn created the current song [handle].
  final P playable;

  /// Handle for the sound that is playing.
  final SoundHandle handle;

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
    _soloud.seek(handle, position);
  }

  /// The components that extend the functionality of this player.
  @mustCallSuper
  List<SongPlayerComponent> get components =>
      List.unmodifiable([slowdowner, equalizer, analyzer]);

  /// Component for changing the pitch and speed of the song.
  late final SlowdownerComponent slowdowner = SlowdownerComponent(this);

  /// Component for adjusting the gain for different frequency bands of the song.
  late final EqualizerComponent equalizer = EqualizerComponent(this);

  /// Component for analyzing the current song, including chord identification and waveform extraction.
  late final AnalyzerComponent analyzer = AnalyzerComponent(this);

  /// Load song preferences from a [json] map.
  @mustCallSuper
  void loadPreferences(Map<String, dynamic> json) {
    int? position = tryCast<int>(json["position"]);
    seek(Duration(milliseconds: position ?? 0));

    slowdowner.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["slowdowner"]) ?? {},
    );
    // looper.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["looper"]) ?? {},
    // );
    equalizer.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["equalizer"]) ?? {},
    );
    analyzer.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["analyzer"]) ?? {},
    );
  }

  /// Create a json map containing the current preferences for this [song].
  @mustCallSuper
  Map<String, dynamic> toPreferences() {
    return {
      "position": position.inMilliseconds,
      "slowdowner": slowdowner.saveSettingsToJson(),
      // "looper": looper.saveSettingsToJson(),
      "equalizer": equalizer.saveSettingsToJson(),
      "analyzer": analyzer.saveSettingsToJson(),
    };
  }
}

class SinglePlayer extends SongPlayer<SinglePlayable> {
  /// An implementation of [SongPlayer] that plays a single audio clip.
  SinglePlayer._(super.song, super.playable, super.handle) : super._();

  static Future<SinglePlayer> load(SongNew<SinglePlayable> song) async {
    final SinglePlayable playable = await song.source.load(
      cacheDirectory: Directory("${(await song.cacheDirectory).path}/source/"),
    );
    final SoundHandle handle = await playable.play();
    final SinglePlayer player = SinglePlayer._(song, playable, handle);

    for (final SongPlayerComponent component in player.components) {
      await component.initialize();
    }

    return player;
  }
}

class MultiPlayer extends SongPlayer<MultiPlayable> {
  static final SoLoud _soloud = SoLoud.instance;

  /// An implementation of [SongPlayer] that plays multiple audio clips simultaneously.
  ///
  /// The [demixer] component allows the volume of each audio clip to be controlled separately.
  MultiPlayer._(super.song, super.playable, super.handle) : super._();

  /// The handles of the individual sounds that are played simultaneously.
  ///
  /// Forwarded from the [playable].
  Iterable<SoundHandle> get handles => playable.handles!.values;

  static Future<MultiPlayer> load(SongNew<MultiPlayable> song) async {
    final MultiPlayable playable = await song.source.load(
      cacheDirectory: Directory("${(await song.cacheDirectory).path}/source/"),
    );
    final SoundHandle handle = await playable.play();
    final MultiPlayer player = MultiPlayer._(song, playable, handle);

    for (final SongPlayerComponent component in player.components) {
      await component.initialize();
    }

    return player;
  }

  @override
  void seek(Duration position) {
    for (SoundHandle handle in handles) {
      _soloud.seek(handle, position);
    }
  }

  @override
  List<SongPlayerComponent> get components =>
      List.unmodifiable([...super.components, demixer]);

  /// Component for isolating or muting specific instruments in the song.
  late final DemixerComponent demixer = DemixerComponent(this);

  @override
  void loadPreferences(Map<String, dynamic> json) {
    super.loadPreferences(json);

    demixer.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["demixer"]) ?? {},
    );
  }

  @override
  Map<String, dynamic> toPreferences() {
    return {
      ...super.toPreferences(),
      "demixer": demixer.saveSettingsToJson(),
    };
  }
}
