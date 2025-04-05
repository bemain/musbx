import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/equalizer/equalizer.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/slowdowner/slowdowner.dart';
import 'package:musbx/widgets/widgets.dart';

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
    final Playable playable = await song.source.load(
      cacheDirectory: Directory("${(await song.cacheDirectory).path}/source/"),
    );

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
    _soloud.seek(handle, position);
  }

  /// The components that extend the functionality of this player.
  late final List<SongPlayerComponent> components = [
    demixer,
    slowdowner,
    equalizer,
  ];

  /// Component for isolating or muting specific instruments in the song.
  late final DemixerComponent demixer = DemixerComponent(this);

  /// Component for changing the pitch and speed of the song.
  late final SlowdownerComponent slowdowner = SlowdownerComponent(this);

  /// Component for adjusting the gain for different frequency bands of the song.
  late final EqualizerComponent equalizer = EqualizerComponent(this);

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
    equalizer.loadSettingsFromJson(
      tryCast<Map<String, dynamic>>(json["equalizer"]) ?? {},
    );
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
      "equalizer": equalizer.saveSettingsToJson(),
      "demixer": demixer.saveSettingsToJson(),
      // "analyzer": analyzer.saveSettingsToJson(),
    };
  }
}
