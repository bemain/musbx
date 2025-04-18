import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:musbx/songs/player/songs.dart';

/// An [AudioHandler] that wraps around [Songs.player] and interacts with the
/// media notification and provides standard system callbacks to handle media
/// playback requests from different sources in a uniform way.
class SongsAudioHandler extends BaseAudioHandler with SeekHandler {
  SongsAudioHandler._();

  static late final AudioSession session;

  /// Create a [SongsAudioHandler] and register it using [AudioService.init].
  static Future<SongsAudioHandler> initialize() async {
    // Configure audio session
    session = await AudioSession.instance;
    await SongsAudioHandler.session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.allowBluetoothA2dp |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
          // Another app started playing audio and we should duck. For now just pausing.
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            Songs.player?.pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
          // The interruption ended and we should unduck. For now just resuming.
          case AudioInterruptionType.pause:
            Songs.player?.resume();
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
    session.becomingNoisyEventStream.listen((_) {
      // The user unplugged the headphones, so we should pause or lower the volume.
      Songs.player?.pause();
    });

    // Initialize audio handler
    return await AudioService.init<SongsAudioHandler>(
      builder: () => SongsAudioHandler._(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'se.agardh.musbx.channel.songs',
        androidNotificationChannelName: 'Music playback',
        androidNotificationIcon: "drawable/ic_notification",
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
        const MediaControl(
          androidIcon: "drawable/ic_replay_10",
          label: "Rewind",
          action: MediaAction.rewind,
        ),
        const MediaControl(
          androidIcon: "drawable/ic_forward_10",
          label: "Fast Forward",
          action: MediaAction.fastForward,
        ),
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
      repeatMode: AudioServiceRepeatMode.all,
    ));
  }
}
