import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer_api.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/music_player/song.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wav/wav.dart';

final DemixerApi _api = DemixerApi();

class Stem {
  Stem(this.type);

  final StemType type;

  /// Whether this stem is enabled and should be played.
  set enabled(bool value) => enabledNotifier.value = value;
  bool get enabled => enabledNotifier.value;
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(false);

  /// The volume this stem is played at. Must be between 0 and 1.
  set volume(double value) => volumeNotifier.value = value.clamp(0, 1);
  double get volume => volumeNotifier.value;
  final ValueNotifier<double> volumeNotifier = ValueNotifier(1.0);

  /// Download and return the file for this stem.
  Future<File?> getStemFile(String song) => _api.downloadStem(song, type);
}

enum LoadingState {
  /// Loading hasn't started. E.g. the user hasn't selected a song yet.
  inactive,

  /// The song is being uploaded to the server.
  uploading,

  /// The server has begun separating the song into stems.
  separating,

  /// The stems are being mixed into a single file.
  mixing,

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

  Directory? _outDirectory;

  /// Mix the stem files for [song] into a single file.
  Future<File?> mixStemFiles(String song) async {
    print("DEMIXER: Mixing stems for $song");
    List<Wav> wavs = [];
    for (Stem stem in stems) {
      File? file = await stem.getStemFile(song);
      if (file != null) wavs.add(await Wav.readFile(file.path));
    }

    // Make sure all [wavs] are uniform.
    if (!wavs.every((wav) => wav.duration == wavs.first.duration) ||
        !wavs.every(
            (wav) => wav.samplesPerSecond == wavs.first.samplesPerSecond) ||
        !wavs.every((wav) => wav.format == wavs.first.format)) {
      debugPrint("ERROR: The stem files are not uniform.");
      return null;
    }

    List<Float64List> monos = wavs.map((wav) => wav.toMono()).toList();
    Float64List mix = Float64List(monos.first.length);

    // Mix all stems.
    for (int i = 0; i < mix.length; i++) {
      mix[i] = List.generate(stems.length, (j) => j).fold(
              0.0, (previous, j) => previous + monos[j][i] * stems[j].volume) /
          stems.fold(0.0, (previous, stem) => previous + stem.volume);
    }

    _outDirectory ??=
        Directory("${(await getTemporaryDirectory()).path}/demixer/")..create();
    File outFile = File("${_outDirectory!.path}/mix.wav");

    await Wav([mix], wavs.first.samplesPerSecond, wavs.first.format)
        .writeFile(outFile.path);
    return outFile;
  }

  /// Separate, mix and load a [song] for [MusicPlayer] to play.
  Future<void> loadSong(Song song) async {
    if (song.source != SongSource.youtube) {
      return; // TODO: Implement separating files
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

    loadingStateNotifier.value = LoadingState.mixing;

    File? mix = await mixStemFiles(songName);
    if (mix == null) return;

    await MusicPlayer.instance.player.setFilePath(mix.path);

    loadingStateNotifier.value = LoadingState.done;
  }

  @override
  void initialize(MusicPlayer musicPlayer) {
    musicPlayer.songNotifier.addListener(onMusicPlayerSongLoaded);
  }

  Future<void> onMusicPlayerSongLoaded() async {
    Song? song = MusicPlayer.instance.song;
    if (song == null) return;

    await loadSong(song);
  }
}
