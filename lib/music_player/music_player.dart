import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/audio_handler.dart';
import 'package:youtube_api/youtube_api.dart';

/// Singleton for playing audio.
class MusicPlayer {
  // Should only be accessed through [instance].
  MusicPlayer.internal(this._audioHandler) {
    _listenForChanges();
  }

  /// The instance of this singleton.
  static late final MusicPlayer instance;

  /// The AudioHandler used internally to play sound.
  final JustAudioHandler _audioHandler;

  /// Start or resume playback.
  Future<void> play() async => await _audioHandler.play();

  /// Pause playback.
  Future<void> pause() async => await _audioHandler.pause();

  /// Seek to [position].
  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  /// Set the playback speed.
  Future<void> setSpeed(double speed) async {
    await _audioHandler.setSpeed(speed);
    speedNotifier.value = speed;
  }

  /// Set how much the pitch will be shifted, in semitones.
  Future<void> setPitchSemitones(double pitch) async {
    await _audioHandler.player.setPitch(pow(2, pitch / 12).toDouble());
    pitchSemitonesNotifier.value = pitch;
  }

  /// Title of the current song, or `null` if no song loaded.
  String? get songTitle => songTitleNotifier.value;
  final ValueNotifier<String?> songTitleNotifier = ValueNotifier<String?>(null);

  /// How much the pitch will be shifted, in semitones.
  double get pitchSemitones => pitchSemitonesNotifier.value;
  final ValueNotifier<double> pitchSemitonesNotifier = ValueNotifier(0);

  /// The current speed of the player.
  double get speed => speedNotifier.value;
  final ValueNotifier<double> speedNotifier = ValueNotifier(1);

  /// The current position of the player.
  Duration get position => positionNotifier.value;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  /// The buffered position of the player.
  Duration get bufferedPosition => bufferedPositionNotifier.value;
  final ValueNotifier<Duration> bufferedPositionNotifier =
      ValueNotifier(Duration.zero);

  /// The duration of the current audio, or null if no audio has been loaded.
  Duration? get duration => durationNotifier.value;
  final ValueNotifier<Duration?> durationNotifier = ValueNotifier(null);

  /// Whether the player is playing.
  bool get isPlaying => isPlayingNotifier.value;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// Play a [PlatformFile].
  Future<void> playFile(PlatformFile file) async {
    await _audioHandler.player.setFilePath(file.path!);
    _audioHandler.mediaItem.add(MediaItem(
      id: file.path!,
      title: file.name,
      duration: _audioHandler.player.duration,
    ));
  }

  Future<void> playVideo(YouTubeVideo video) async {
    // TODO: Get this method to work...
    throw UnimplementedError();
    _audioHandler.player.setUrl(video.url);
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
    // bufferedPosition & isPlaying
    _audioHandler.playbackState.listen((newState) {
      bufferedPositionNotifier.value = newState.bufferedPosition;
      isPlayingNotifier.value = newState.playing;
    });

    // position
    AudioService.position.listen((position) {
      positionNotifier.value = Duration(
        milliseconds: position.inMilliseconds.clamp(
          0,
          duration?.inMilliseconds ?? 0,
        ),
      );
    });

    // duration & songTitle
    _audioHandler.mediaItem.listen((mediaItem) {
      durationNotifier.value = mediaItem?.duration ?? Duration.zero;
      songTitleNotifier.value = mediaItem?.title;
    });

    // pitch
    _audioHandler.player.pitchStream.listen((pitch) {
      pitchSemitonesNotifier.value = (12 * log(pitch) / log(2)).toDouble();
    });
  }
}
