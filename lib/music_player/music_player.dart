import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Singleton for playing audio.
class MusicPlayer {
  // Only way to access is through [instance].
  MusicPlayer._() {
    _listenForChanges();
  }

  /// The instance of this singleton.
  static final MusicPlayer instance = MusicPlayer._();

  /// The [AudioPlayer] used for playback.
  final AudioPlayer player = AudioPlayer();

  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  /// Start or resume playback.
  Future<void> play() async => await player.play();

  /// Pause playback.
  Future<void> pause() async => await player.pause();

  /// Seek to [position].
  Future<void> seek(Duration position) async {
    if (position == this.position) return;
    await player.seek(position);
    await JustAudioHandler.instance.seek(position);
  }

  /// Set the playback speed.
  Future<void> setSpeed(double speed) async {
    await player.setSpeed(speed);
    await JustAudioHandler.instance.setSpeed(speed);
    speedNotifier.value = speed;
  }

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(double pitch) async {
    await player.setPitch(pow(2, pitch / 12).toDouble());
    pitchSemitonesNotifier.value = pitch;
  }

  /// Title of the current song, or `null` if no song loaded.
  String? get songTitle => songTitleNotifier.value;
  final ValueNotifier<String?> songTitleNotifier = ValueNotifier<String?>(null);

  /// How much the pitch will be shifted, in semitones.
  double get pitchSemitones => pitchSemitonesNotifier.value;
  set pitchSemitones(double value) => setPitchSemitones(value);
  final ValueNotifier<double> pitchSemitonesNotifier = ValueNotifier(0);

  /// The playback speed.
  double get speed => speedNotifier.value;
  set speed(double value) => setSpeed(value);
  final ValueNotifier<double> speedNotifier = ValueNotifier(1);

  /// The current position of the player.
  Duration get position => positionNotifier.value;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  /// The duration of the current audio, or null if no audio has been loaded.
  Duration? get duration => durationNotifier.value;
  final ValueNotifier<Duration?> durationNotifier = ValueNotifier(null);

  /// Whether we are currently looping a section of the song or not.
  bool get loopEnabled => loopEnabledNotifier.value;
  set loopEnabled(bool value) => loopEnabledNotifier.value = value;
  final ValueNotifier<bool> loopEnabledNotifier = ValueNotifier(true);

  /// The section being looped.
  LoopSection get loopSection => loopSectionNotifier.value;
  set loopSection(LoopSection section) => loopSectionNotifier.value = section;
  final ValueNotifier<LoopSection> loopSectionNotifier =
      ValueNotifier(LoopSection());

  /// Whether the player is playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? play() : pause();
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Play a [PlatformFile].
  Future<void> playFile(PlatformFile file) async {
    // Load file
    await player.setFilePath(file.path!);

    // Update songTitle
    songTitleNotifier.value = file.name;
    // Reset loopSection
    loopSection = LoopSection(end: duration!);

    // Inform notification
    JustAudioHandler.instance.mediaItem.add(MediaItem(
      id: file.path!,
      title: file.name,
      duration: player.duration,
    ));
  }

  Future<void> playVideo(YouTubeVideo video) async {
    // Get stream info
    StreamManifest manifest =
        await _youtubeExplode.videos.streams.getManifest(video.id);
    AudioOnlyStreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();

    _audioHandler.player.setUrl(streamInfo.url.toString());
    _audioHandler.mediaItem.add(MediaItem(
      id: video.id ?? "",
      title: video.title,
      duration: _parseDuration(video.duration ?? "0:0"),
    ));
  }

  Duration _parseDuration(String s) {
    List<String> parts = s.split(":");
    return Duration(
      minutes: int.parse(parts[0]),
      seconds: int.parse(parts[1]),
    );
  }

  /// Listen for changes from [_audioHandler].
  void _listenForChanges() {
    // isPlaying
    player.playingStream.listen((playing) {
      isPlayingNotifier.value = playing;
    });

    // position
    player.positionStream.listen((position) {
      // Limit upper
      if ((loopEnabled && position >= loopSection.end) ||
          position >= (duration ?? const Duration(seconds: 1))) {
        player.pause();
        seek(loopEnabled
            ? loopSection.end
            : duration ?? const Duration(seconds: 1));
      } else if (loopEnabled && position < loopSection.start) {
        // Limit lower
        player.pause();
        seek(loopSection.start);
      } else {
        // Update position
        positionNotifier.value = position;
      }
    });

    // duration
    player.durationStream.listen((duration) {
      durationNotifier.value = duration;
    });

    // When loopSection changes, clamp position
    loopSectionNotifier.addListener(() {
      seek(Duration(
        milliseconds: position.inMilliseconds.clamp(
          loopSection.start.inMilliseconds,
          loopSection.end.inMilliseconds,
        ),
      ));
    });
  }
}

class LoopSection {
  LoopSection(
      {this.start = Duration.zero, this.end = const Duration(seconds: 1)});

  final Duration start;
  final Duration end;

  /// Duration between [start] and [end].
  Duration get length => end - start;
}
