import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musbx/songs/player/songs.dart';

/// An [AudioHandler] that wraps around [Songs.player] and interacts with the
/// media notification and provides standard system callbacks to handle media
/// playback requests from different sources in a uniform way.
class SongsAudioHandler extends BaseAudioHandler with SeekHandler {
  SongsAudioHandler._();

  /// Create a [SongsAudioHandler] and register it using [AudioService.init].
  static Future<SongsAudioHandler> initialize() async {
    return await AudioService.init<SongsAudioHandler>(
      builder: () => SongsAudioHandler._(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'se.agardh.musbx.channel.songs',
        androidNotificationChannelName: 'Music playback',
        androidNotificationIcon: "drawable/ic_notification",
        androidNotificationOngoing: true,
        notificationColor: Colors.white,
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );
  }

  @override
  Future<void> play() async => Songs.player?.resume();

  @override
  Future<void> pause() async => Songs.player?.pause();

  @override
  Future<void> seek(Duration position) async => Songs.player?.seek(position);

  @override
  Future<void> stop() async => await Songs.player?.dispose();

  void updateState() {
    playbackState.add(PlaybackState(
      controls: [
        // TODO: Use custom icons
        if (Songs.player?.isPlaying ?? true)
          MediaControl.pause
        else
          MediaControl.play,
        MediaControl.rewind,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.playPause,
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: Songs.player == null
          ? AudioProcessingState.idle
          : AudioProcessingState.ready,
      playing: Songs.player?.isPlaying ?? false,
      updatePosition: Songs.player?.position ?? Duration.zero,
      bufferedPosition: Songs.player?.duration ?? Duration.zero,
      speed: Songs.player?.slowdowner.speed ?? 1.0,
    ));
  }
}
