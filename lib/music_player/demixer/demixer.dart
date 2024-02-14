import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/musbx_api/demixer_api.dart';
import 'package:musbx/music_player/musbx_api/exceptions.dart';
import 'package:musbx/music_player/demixer/demixing_process.dart';
import 'package:musbx/music_player/demixer/mixed_audio_source.dart';
import 'package:musbx/music_player/demixer/stem.dart';
import 'package:musbx/music_player/looper/looper.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/widgets.dart';

enum DemixerState {
  /// Demixing hasn't started. E.g. the user hasn't selected a song yet.
  inactive,

  /// The song is being demixed.
  demixing,

  /// The song has been demixed and is ready to be played.
  done,

  /// The Demixer isn't up to date with the server.
  /// The app has to be updated to the latest version.
  outOfDate,

  /// Something went wrong while demixing the song.
  error,
}

/// A component for [MusicPlayer] that is used to separate a song into stems and change the volume of those individually.
class Demixer extends MusicPlayerComponent {
  /// The stems that songs are being separated into.
  List<Stem> get stems => stemsNotifier.value;
  late final StemsNotifier stemsNotifier = StemsNotifier([
    Stem(StemType.vocals),
    Stem(StemType.bass),
    Stem(StemType.drums),
    Stem(StemType.other)
  ]);

  /// The state of the Demixer.
  DemixerState get state => stateNotifier.value;
  final ValueNotifier<DemixerState> stateNotifier =
      ValueNotifier(DemixerState.inactive);

  /// Whether the Demixer is ready to play the current song.
  ///
  /// If `true`, the current song has been separated and mixed, and the Demixer is enabled.
  bool get isReady => state == DemixerState.done && enabled;

  /// The process demxing the current song, or `null` if no song has been selected.
  DemixingProcess? process;

  @override
  void initialize(MusicPlayer musicPlayer) {
    musicPlayer.songNotifier.addListener(_onNewSongLoaded);
    enabledNotifier.addListener(_onEnabledToggle);
    stemsNotifier.addListener(_onStemsChanged);
  }

  /// Demix [MusicPlayer]'s current song.
  ///
  /// Starts a [process] demixing the song, and catches any error encountered.
  ///
  /// Does nothing if no song has been loaded to [MusicPlayer].
  Future<void> demixCurrentSong() async {
    MusicPlayer musicPlayer = MusicPlayer.instance;
    Song? song = musicPlayer.song;
    if (song == null) return;

    stateNotifier.value = DemixerState.demixing;

    try {
      process?.cancel();
      process = DemixingProcess(song);

      Map<StemType, File>? stemFiles = await process?.future;
      if (stemFiles == null) return;
    } on OutOfDateException {
      debugPrint(
          "[DEMIXER] Out of date. Try upgrading the app to the latest version");
      stateNotifier.value = DemixerState.outOfDate;
      return;
    } catch (error) {
      debugPrint("[DEMIXER] Error demixing song: $error");
      stateNotifier.value = DemixerState.error;
      return;
    }

    stateNotifier.value = DemixerState.done;

    _onEnabledToggle();
  }

  Future<void> _onStemsChanged() async {
    if (!isReady) return;

    MusicPlayer musicPlayer = MusicPlayer.instance;
    Song? song = musicPlayer.song;
    if (song == null) return;

    if (Platform.isIOS) {
      // On iOS segments of the audio source are cached, so a full reload is required.
      await _onEnabledToggle();
      return;
    }

    // Ugly way to force just_audio to perform a new request to MixedAudioSource, so that changes to stems are detected.
    Duration position = musicPlayer.position;
    await musicPlayer.seek(position - const Duration(seconds: 1));
    await musicPlayer.seek(position);
  }

  Future<void> _onNewSongLoaded() async {
    stateNotifier.value = DemixerState.inactive;

    if (await isOnCellular()) enabled = false;

    if (!enabled) return;

    await demixCurrentSong();
  }

  Future<void> _onEnabledToggle() async {
    if (state != DemixerState.done) {
      if (enabled) {
        await demixCurrentSong();
      } else {
        process?.cancel();
        stateNotifier.value = DemixerState.inactive;
      }
      return;
    }

    MusicPlayer musicPlayer = MusicPlayer.instance;
    if (musicPlayer.song == null) return;

    // Make sure no other process is currently setting the audio source
    Future<void>? awaitBeforeLoading = musicPlayer.loadSongLock;
    musicPlayer.loadSongLock = _loadAudioSource(
      awaitBeforeLoading: awaitBeforeLoading,
    );
    await musicPlayer.loadSongLock;
  }

  /// Awaits [awaitBeforeLoading] and enables/disables demixed audio.
  /// See [MusicPlayer.loadSongLock] for more info why this is required.
  Future<void> _loadAudioSource({
    Future<void>? awaitBeforeLoading,
  }) async {
    await awaitBeforeLoading;

    MusicPlayer musicPlayer = MusicPlayer.instance;
    Duration position = musicPlayer.position;

    if (enabled) {
      // Load wav files
      Directory directory = await DemixerApiHost.demixerDirectory;
      Map<StemType, File> files = Map.fromEntries(StemType.values.map((stem) =>
          MapEntry(stem, File("${directory.path}/${stem.name}.wav"))));

      // Enable mixed audio
      await musicPlayer.player.setAudioSource(
        MixedAudioSource(files),
        initialPosition: position,
      );
      await musicPlayer.player.setVolume(1.0);
    } else {
      // Restore "normal" audio
      if (musicPlayer.song == null) return;
      await musicPlayer.player.setAudioSource(
        await musicPlayer.song!.source.toAudioSource(),
        initialPosition: position,
      );
      await musicPlayer.player.setVolume(0.5);
    }

    // Update loopSection to avoid error if new audio source isn't exectly as long as the previous.
    if (musicPlayer.song == null) return;
    Duration newDuration = musicPlayer.player.duration!;
    if (musicPlayer.looper.section.end.compareTo(newDuration) > 0) {
      // Section end is greater than new duration
      musicPlayer.looper.section = LoopSection(end: newDuration);
    }
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following stems (beyond `enabled`):
  ///  - `drums`
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
      Map<String, dynamic> stemData = json[stem.type.name];

      bool? enabled = tryCast<bool>(stemData["enabled"]);
      if (enabled != null) stem.enabled = enabled;

      double? volume = tryCast<double>(stemData["volume"]);
      if (volume != null) stem.volume = volume;
    }
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following stems:
  ///  - `drums`
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
