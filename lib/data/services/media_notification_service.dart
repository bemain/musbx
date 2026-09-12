import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musbx/data/models/media_command.dart';
import 'package:musbx/data/models/media_notification_state.dart';
import 'package:musbx/data/services/service.dart';

/// The default album art.
final Uri _defaultAlbumArt = Uri.parse(
  "https://bemain.github.io/musbx/assets/album_art/default.png",
);

class MediaNotificationService extends OptionalService {
  MediaNotificationService._(this._handler) {
    _subscription = AudioService.notificationClicked.listen(
      (clicked) {
        if (clicked) _clicked.add(null);
      },
      onError: (Object error) => debugPrint(
        "[MEDIA NOTIFICATION] Audio service clicked encountered an error: $error",
      ),
    );
  }

  final _Handler? _handler;

  @override
  bool get isEnabled => _handler != null;

  static Future<MediaNotificationService> create() async {
    // Initialize audio handler
    final h = await AudioService.init<_Handler>(
      builder: () => _Handler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'se.agardh.musbx.channel.songs',
        androidNotificationChannelName: 'Music playback',
        androidNotificationIcon: "drawable/ic_notification",
        notificationColor: Colors.white,
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );

    return MediaNotificationService._(h);
  }

  static MediaNotificationService disabled() =>
      MediaNotificationService._(null);

  // TODO: Remove once we introduce `provider`.
  static late final MediaNotificationService instance;
  static Future<void> initialize() async {
    try {
      instance = await create();
    } catch (error) {
      debugPrint(
        "[MEDIA NOTIFICATION] Disabled, initialization failed: $error",
      );
      instance = disabled();
    }
  }

  late final StreamSubscription<bool> _subscription;

  final _clicked = StreamController<void>.broadcast();
  Stream<void> get notificationClicked => _clicked.stream;

  Stream<MediaCommand> get commands {
    throwIfDisabled();
    return _handler!.commands;
  }

  void update(MediaNotificationState? state) {
    throwIfDisabled();
    _handler!.update(state);
  }

  Future<void> dispose() async {
    await _handler?.dispose();
    await _subscription.cancel();
    await _clicked.close();
  }
}

class _Handler extends BaseAudioHandler with SeekHandler {
  final _commands = StreamController<MediaCommand>.broadcast();
  Stream<MediaCommand> get commands => _commands.stream;

  @override
  Future<void> play() async => _commands.add(MediaCommand.play);

  @override
  Future<void> pause() async => _commands.add(MediaCommand.pause);

  @override
  Future<void> stop() async => _commands.add(MediaCommand.stop);

  @override
  Future<void> seek(Duration position) async =>
      _commands.add(MediaCommand.seek(position));

  void update(MediaNotificationState? state) {
    if (state == null) {
      playbackState.add(PlaybackState());
      mediaItem.add(null);
    } else {
      final item = MediaItem(
        id: state.id,
        title: state.title,
        artist: state.artist,
        album: state.album,
        genre: state.genre,
        artUri: state.artUri ?? _defaultAlbumArt,
        duration: state.duration,
      );
      if (item != mediaItem.value) mediaItem.add(item);

      playbackState.add(
        PlaybackState(
          controls: [
            // TODO: Use custom icons
            if (state.isPlaying) MediaControl.pause else MediaControl.play,
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
          processingState: AudioProcessingState.ready,
          playing: state.isPlaying,
          updatePosition: state.position,
          bufferedPosition: state.duration ?? Duration.zero,
          speed: state.speed,
          repeatMode: AudioServiceRepeatMode.all,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await _commands.close();
  }
}
