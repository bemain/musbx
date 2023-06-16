import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/music_player/song.dart';

final DemixerApi _api = DemixerApi();

class Stem {
  Stem(this.type) {
    player.volumeStream.listen((value) => volumeNotifier.value = value);
  }

  final StemType type;

  /// Whether this stem is enabled and should be played.
  set enabled(bool value) {
    if (value == false) player.pause();
    if (value == true &&
        MusicPlayer.instance.demixer.enabled &&
        MusicPlayer.instance.isPlaying) player.play();
    enabledNotifier.value = value;
  }

  bool get enabled => enabledNotifier.value;
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);

  /// The volume this stem is played at. Must be between 0 and 1.
  set volume(double value) => player.setVolume(value.clamp(0, 1));
  double get volume => volumeNotifier.value;
  final ValueNotifier<double> volumeNotifier = ValueNotifier(1.0);

  late final AudioPlayer player = AudioPlayer(
      // audioPipeline: AudioPipeline(androidAudioEffects: [
      //   if (Platform.isAndroid) MusicPlayer.instance.equalizer.androidEqualizer
      // ]),
      );

  /// Download and prepare [player] for playing this stem of [song].
  Future<void> loadStemFile(String song) async {
    File? file = await _api.downloadStem(song, type);
    if (file == null) return;
    await player.setAudioSource(AudioSource.file(file.path));
  }
}

enum LoadingState {
  /// Loading hasn't started. E.g. the user hasn't selected a song yet.
  inactive,

  /// The song is being uploaded to the server.
  uploading,

  /// The server has begun separating the song into stems.
  separating,

  /// The stem files are being loaded to the AudioPlayers.
  preparingPlayback,

  /// The song has been separated and mixed and is ready to be played.
  done,
}

class Demixer extends MusicPlayerComponent {
  final Stem drums = Stem(StemType.drums);
  final Stem bass = Stem(StemType.bass);
  final Stem vocals = Stem(StemType.vocals);
  final Stem other = Stem(StemType.other);

  late final List<Stem> stems = [drums, bass, vocals, other];

  LoadingState get loadingState => loadingStateNotifier.value;
  final ValueNotifier<LoadingState> loadingStateNotifier =
      ValueNotifier(LoadingState.done);

  /// Whether the Demixer is ready to play the current song.
  ///
  /// If `true`, the current song has been separated and mixed, and the Demixer is ready to use.
  bool get isLoaded => loadingState == LoadingState.done;

  /// The progress of the loading action.
  ///
  /// This is `null` if [loadingState] is not [LoadingState.separating].
  int? get loadingProgress => loadingProgressNotifier.value;
  ValueNotifier<int?> loadingProgressNotifier = ValueNotifier(null);

  /// Separate, mix and load a [song] for [MusicPlayer] to play.
  Future<String?> separateSong(Song song) async {
    if (song.source != SongSource.youtube) {
      return null; // TODO: Implement separating files
    }

    loadingStateNotifier.value = LoadingState.uploading;

    UploadResponse response = await _api.uploadYoutubeSong(song.id);
    String songName = response.songName;

    if (response.jobId != null) {
      loadingStateNotifier.value = LoadingState.separating;
      var subscription = _api.jobProgress(response.jobId!).listen((response) {
        loadingProgressNotifier.value = response.progress;
      });

      await subscription.asFuture();
      loadingProgressNotifier.value = null;
    }

    return songName;
  }

  @override
  void initialize(MusicPlayer musicPlayer) {
    musicPlayer.songNotifier.addListener(onSongLoaded);
    musicPlayer.isPlayingNotifier.addListener(onIsPlayingChanged);
    musicPlayer.positionNotifier.addListener(onPositionChanged);
    musicPlayer.player.speedStream.listen(onSpeedChanged);
    musicPlayer.player.pitchStream.listen(onPitchChanged);
    enabledNotifier.addListener(onEnabledToggle);
  }

  AudioSource? originalAudioSource;

  Future<void> onSongLoaded() async {
    MusicPlayer musicPlayer = MusicPlayer.instance;
    Song? song = musicPlayer.song;
    if (song == null) return;

    originalAudioSource = song.audioSource;

    String? songName = await separateSong(song);
    if (songName == null) return;

    loadingStateNotifier.value = LoadingState.preparingPlayback;

    for (Stem stem in stems) {
      await stem.loadStemFile(songName);
    }

    // Make sure all players have the same duration
    assert(stems
        .every((stem) => stem.player.duration == stems.first.player.duration));

    // Trigger enable
    await onEnabledToggle();

    loadingStateNotifier.value = LoadingState.done;
  }

  void onIsPlayingChanged() {
    if (!isLoaded || !enabled) return;
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
    if (!isLoaded || !enabled) return;
    MusicPlayer musicPlayer = MusicPlayer.instance;

    final Duration minAllowedPositionError =
        const Duration(milliseconds: 20) * musicPlayer.slowdowner.speed;

    for (Stem stem in stems) {
      if (stem.enabled &&
          (musicPlayer.position - stem.player.position).abs() >
              minAllowedPositionError) {
        print(
            "DEMIXER: Correcting position for stem ${stem.type.name}. Error: ${(musicPlayer.position - stem.player.position).abs().inMilliseconds}ms");
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

  Future<void> onEnabledToggle() async {
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
      if (originalAudioSource == null) return;
      await musicPlayer.player.setAudioSource(
        originalAudioSource!,
        initialPosition: position,
      );
    }
    await musicPlayer.seek(position);
    if (wasPlaying) musicPlayer.play();
  }
}
