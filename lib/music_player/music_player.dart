import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:musbx/music_player/current_song_card/youtube_api/video.dart';
import 'package:musbx/music_player/loop_card/looper.dart';
import 'package:musbx/music_player/pitch_speed_card/slowdowner.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// The state of [MusicPlayer].
enum MusicPlayerState {
  /// The player has been initialized, but no audio has been loaded.
  idle,

  /// The user is picking audio to load.
  pickingAudio,

  /// The player has been initialized, and is loading audio.
  loadingAudio,

  /// The player has loaded audio.
  ready,
}

/// Singleton for playing audio.
class MusicPlayer {
  // Only way to access is through [instance].
  MusicPlayer._() {
    _init();
  }

  /// The instance of this singleton.
  static final MusicPlayer instance = MusicPlayer._();

  MusicPlayerState get state => stateNotifier.value;
  final ValueNotifier<MusicPlayerState> stateNotifier =
      ValueNotifier(MusicPlayerState.idle);

  /// The [AudioPlayer] used for playback.
  final AudioPlayer player = AudioPlayer();

  /// Used internally to get audio from YouTube.
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  /// Start or resume playback.
  Future<void> play() async => await player.play();

  /// Pause playback.
  Future<void> pause() async => await player.pause();

  /// Seek to [position].
  Future<void> seek(Duration position) async {
    await player.seek(looper.clampPosition(position, duration: duration));
    await MusicPlayerAudioHandler.instance.seek(position);
  }

  /// Title of the current song, or `null` if no song loaded.
  String? get songTitle => songTitleNotifier.value;
  final ValueNotifier<String?> songTitleNotifier = ValueNotifier<String?>(null);

  /// Returns `null` if no song loaded, value otherwise.
  T? nullIfNoSongElse<T>(T? value) =>
      (isLoading || state == MusicPlayerState.idle) ? null : value;

  /// If true, the player is currently in a loading state.
  /// If false, the player is either idle or have loaded audio.
  bool get isLoading => (state == MusicPlayerState.loadingAudio ||
      state == MusicPlayerState.pickingAudio);

  /// The current position of the player.
  Duration get position => positionNotifier.value;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  /// The duration of the current audio, or null if no audio has been loaded.
  Duration get duration => durationNotifier.value;
  final ValueNotifier<Duration> durationNotifier =
      ValueNotifier(const Duration(seconds: 1));

  /// Whether the player is playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? play() : pause();
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Whether the player is buffering audio.
  bool get isBuffering => isBufferingNotifier.value;
  final ValueNotifier<bool> isBufferingNotifier = ValueNotifier(false);

  /// Component for changing the pitch and speed of the song.
  final Slowdowner slowdowner = Slowdowner();

  /// Component for looping a section of the song.
  final Looper looper = Looper();

  /// Play a [PlatformFile].
  Future<void> playFile(PlatformFile file) async {
    await pause();
    stateNotifier.value = MusicPlayerState.loadingAudio;

    // Load file
    await player.setFilePath(file.path!);

    // Update songTitle
    songTitleNotifier.value = file.name;
    // Reset loopSection
    looper.section = LoopSection(end: duration);

    // Inform notification
    MusicPlayerAudioHandler.instance.mediaItem.add(MediaItem(
      id: file.path!,
      title: file.name,
      duration: player.duration,
    ));

    stateNotifier.value = MusicPlayerState.ready;
  }

  Future<void> playVideo(YoutubeVideo video) async {
    await pause();
    stateNotifier.value = MusicPlayerState.loadingAudio;

    // Get stream info
    StreamManifest manifest =
        await _youtubeExplode.videos.streams.getManifest(video.id);
    AudioOnlyStreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();

    HtmlUnescape htmlUnescape = HtmlUnescape();

    // Set URL
    await player.setUrl(streamInfo.url.toString());

    // Update songTitle
    songTitleNotifier.value = htmlUnescape.convert(video.title);
    // Reset loopSection
    looper.section = LoopSection(end: duration);

    // Inform notification
    MusicPlayerAudioHandler.instance.mediaItem.add(MediaItem(
      id: video.id,
      title: htmlUnescape.convert(video.title),
      duration: duration,
      artist: htmlUnescape.convert(video.channelTitle),
      artUri: Uri.tryParse(video.thumbnails.high.url),
    ));

    stateNotifier.value = MusicPlayerState.ready;
  }

  /// Listen for changes from [player].
  void _init() {
    // isPlaying
    player.playingStream.listen((playing) {
      isPlayingNotifier.value = playing;
    });

    // position
    player.positionStream.listen((position) async {
      // If we have reached the end of the loop section while looping, seek to the start.
      if ((isPlaying && looper.enabled && position >= looper.section.end)) {
        await seek(Duration.zero);
        return;
      }

      // If we have reached the end of the song, pause.
      if (isPlaying && !looper.enabled && position >= duration) {
        await player.pause();
        await seek(duration);
        return;
      }

      // Update position
      positionNotifier.value = position;
    });

    // duration
    player.durationStream.listen((duration) {
      durationNotifier.value = duration ?? const Duration(seconds: 1);
    });

    // buffering
    player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.buffering) {
        isBufferingNotifier.value = true;
      }

      if (processingState == ProcessingState.ready) {
        isBufferingNotifier.value = false;
      }
    });

    slowdowner.initialize(this);
    looper.initialize(this);
  }
}
