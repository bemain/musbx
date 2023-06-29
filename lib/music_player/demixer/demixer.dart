import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';
import 'package:musbx/music_player/demixer/demixing_process.dart';
import 'package:musbx/music_player/demixer/host.dart';
import 'package:musbx/music_player/demixer/stem.dart';
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
    Stem(StemType.drums),
    Stem(StemType.bass),
    Stem(StemType.vocals),
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
    musicPlayer.songNotifier.addListener(onNewSongLoaded);
    musicPlayer.isPlayingNotifier.addListener(onIsPlayingChanged);
    musicPlayer.positionNotifier.addListener(onPositionChanged);
    musicPlayer.player.speedStream.listen(onSpeedChanged);
    musicPlayer.player.pitchStream.listen(onPitchChanged);
    musicPlayer.equalizer.parametersNotifier.addListener(onEqualizerChanged);
    enabledNotifier.addListener(onEnabledToggle);

    musicPlayer.equalizer.enabledNotifier.addListener(() {
      // For now, disable when demixer is enabled since they don't work together.
      // TODO: Get the Demixer to work with the Equalizer.
      if (musicPlayer.equalizer.enabled) enabled = false;
    });

    // Check if the host is up to date
    try {
      DemixerApi.findHost().then((_) {});
    } on OutOfDateException {
      stateNotifier.value = DemixerState.outOfDate;
    } catch (error) {
      stateNotifier.value = DemixerState.error;
    }
  }

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

      for (Stem stem in stems) {
        if (stemFiles.containsKey(stem.type) && stemFiles[stem.type] != null) {
          await stem.player
              .setAudioSource(AudioSource.file(stemFiles[stem.type]!.path));
        }
      }

      // Make sure all players have the same duration
      assert(stems.every(
          (stem) => stem.player.duration == stems.first.player.duration));
    } on OutOfDateException {
      debugPrint(
          "DEMIXER: Out of date. Try upgrading the app to the latest version");
      stateNotifier.value = DemixerState.outOfDate;
      return;
    } catch (error) {
      debugPrint("DEMIXER: Error demixing song: $error");
      stateNotifier.value = DemixerState.error;
      return;
    }

    stateNotifier.value = DemixerState.done;
  }

  Future<void> onNewSongLoaded() async {
    if (await isOnCellular()) enabled = false;

    if (!enabled) return;

    await demixCurrentSong();

    // Trigger enable
    await onEnabledToggle();
  }

  void onIsPlayingChanged() {
    if (!isReady) return;
    MusicPlayer musicPlayer = MusicPlayer.instance;

    for (Stem stem in stems) {
      if (musicPlayer.isPlaying) {
        if (stem.enabled) stem.player.play();
      } else {
        stem.player.pause();
      }
    }
  }

  void onPositionChanged() {
    MusicPlayer musicPlayer = MusicPlayer.instance;
    if (!isReady || !musicPlayer.isPlaying) return;

    final Duration minAllowedPositionError = const Duration(milliseconds: 30) *
        (musicPlayer.slowdowner.enabled ? musicPlayer.slowdowner.speed : 1);

    for (Stem stem in stems) {
      Duration error = (musicPlayer.position - stem.player.position).abs();
      if (stem.enabled && error > minAllowedPositionError) {
        debugPrint(
            "DEMIXER: Correcting position for stem ${stem.type.name}. Error: ${error.inMilliseconds}ms");
        stem.player.seek(musicPlayer.position);
      }
    }
  }

  void onSpeedChanged(double speed) {
    for (Stem stem in stems) {
      stem.player.setSpeed(speed);
    }
  }

  void onPitchChanged(double pitch) async {
    for (Stem stem in stems) {
      stem.player.setPitch(pitch);
    }
  }

  Future<void> onEqualizerChanged() async {
    // TODO: Get this to work. Currently, there is no trigger for when the Equalizer's parameters changes.
    // var musicPlayerBands = MusicPlayer.instance.equalizer.parameters?.bands;
    // if (musicPlayerBands == null) return;

    // for (Stem stem in stems) {
    //   var bands = (await stem.equalizer.parameters).bands;
    //   for (int i = 0; i < bands.length; i++) {
    //     await bands[i].setGain(musicPlayerBands[i].gain);
    //   }
    // }
  }

  Future<void> onEnabledToggle() async {
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
    Song? song = musicPlayer.song;
    if (song == null) return;

    Duration position = musicPlayer.position;
    bool wasPlaying = musicPlayer.isPlaying;

    for (Stem stem in stems) {
      await stem.player.pause();
    }
    await musicPlayer.pause();

    if (enabled) {
      // Disable "normal" audio
      await musicPlayer.player.setAudioSource(
        SilenceAudioSource(duration: stems.first.player.duration!),
        initialPosition: position,
      );
    } else {
      // Restore "normal" audio
      await musicPlayer.player.setAudioSource(
        song.audioSource,
        initialPosition: position,
      );
    }
    await musicPlayer.seek(position);
    if (wasPlaying) musicPlayer.play();
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following stems (beyond "enabled"):
  ///  - "drums"
  ///  - "bass"
  ///  - "vocals"
  ///  - "other"
  ///
  /// Each stem can contain the following key-value pairs:
  ///  - "enabled": [bool] Whether this stem is enabled and should be played.
  ///  - "volume": [double] The volume this stem is played back at. Must be between 0 and 1.
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
  ///  - "drums"
  ///  - "bass"
  ///  - "vocals"
  ///  - "other"
  ///
  /// Each stem contains the following key-value pairs:
  ///  - "enabled": [bool] Whether this stem is enabled and should be played.
  ///  - "volume": [double] The volume this stem is played back at. Must be between 0 and 1.
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
