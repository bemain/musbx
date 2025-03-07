import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/song_source.dart';
import 'package:musbx/widgets/widgets.dart';

enum SongPlayerState {
  loading,
  ready,
}

class SongPlayer {
  static final SoLoud _soloud = SoLoud.instance;

  /// Constructor used internally.
  ///
  /// Assumes the [song.source] to already be loaded.
  SongPlayer._(this.song, this.handle);

  /// Create a [SongPlayer] by loading a [song].
  ///
  /// Loads the [song.source] and retrieves a [handle] for the song from [SoLoud].
  static Future<SongPlayer> load(Song song) async {
    final AudioSource source = await song.source.load();
    final handle = await _soloud.play(source, paused: true);

    return SongPlayer._(
      song,
      handle,
    );
  }

  final Song song;

  /// Handle to the currently loaded song.
  /// TODO: Rename
  final SoundHandle handle;

  SongPlayerState get state => stateNotifier.value;
  final ValueNotifier<SongPlayerState> stateNotifier =
      ValueNotifier(SongPlayerState.loading);

  /// If true, the player is currently in a loading state.
  /// If false, the player is either idle or has loaded audio.
  bool get isLoading => state == SongPlayerState.loading;

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

  /// Stop playback, and dispose the current audio source.
  ///
  /// See [SongSource.dispose].
  Future<void> stop() async {
    await _soloud.stop(handle);
    await song.source.dispose();

    isPlayingNotifier.value = false;
  }

  /// Convenience method to get the duration of the current [song].
  ///
  /// See [SongSource.duration].
  Duration get duration => song.source.duration;

  /// The current position of the player.
  Duration get position => _soloud.getPosition(handle);

  /// Create a stream that yield the current [position] at regular [interval]s.
  ///
  /// Yields data immediately upon creation, so there is always data in the stream.
  ///
  /// The stream is efficient, and only yields the position if it has changed.
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

  /// Load song preferences from a [json] map.
  void loadPreferences(Map<String, dynamic> json) {
    int? position = tryCast<int>(json["position"]);
    seek(Duration(milliseconds: position ?? 0));

    // slowdowner.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["slowdowner"]) ?? {},
    // );
    // looper.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["looper"]) ?? {},
    // );
    // equalizer.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["equalizer"]) ?? {},
    // );
    // demixer.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["demixer"]) ?? {},
    // );
    // analyzer.loadSettingsFromJson(
    //   tryCast<Map<String, dynamic>>(json["analyzer"]) ?? {},
    // );
  }

  /// Create a json map containing the current preferences for this [song].
  Map<String, dynamic> toPreferences() {
    return {
      "position": position.inMilliseconds,
      // "slowdowner": slowdowner.saveSettingsToJson(),
      // "looper": looper.saveSettingsToJson(),
      // "equalizer": equalizer.saveSettingsToJson(),
      // "demixer": demixer.saveSettingsToJson(),
      // "analyzer": analyzer.saveSettingsToJson(),
    };
  }
}
