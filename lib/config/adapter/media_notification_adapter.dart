import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/models/media_command.dart';
import 'package:musbx/data/models/media_notification_state.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/services/media_notification_service.dart';
import 'package:musbx/domain/use_case/unload_song.dart';

class MediaNotificationAdapter {
  MediaNotificationAdapter({
    required ServiceLoader<MediaNotificationService> mediaNotification,
    required PlaybackRepository playback,
    required UnloadSong unloadSong,
  }) : _playback = playback,
       _mediaNotification = mediaNotification,
       _unloadSong = unloadSong {
    _unbind = mediaNotification.bind(_attach);
  }

  final PlaybackRepository _playback;
  final ServiceLoader<MediaNotificationService> _mediaNotification;
  final UnloadSong _unloadSong;
  late final VoidCallback _unbind;
  StreamSubscription<MediaCommand>? _subscription;

  void _attach(MediaNotificationService service) {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _playback.removeListener(_updateState);

    if (!service.isEnabled) return;

    _subscription = service.commands.listen(
      (command) => switch (command) {
        Play() => _playback.resume(),
        Pause() => _playback.pause(),
        Stop() => _unloadSong.call(),
        Seek(:final position) => _playback.seek(position),
      },
    );

    _playback.addListener(_updateState);
  }

  void _updateState() {
    final song = _playback.song;
    _mediaNotification.value.update(
      song == null
          ? null
          : MediaNotificationState(
              id: song.id,
              title: song.title,
              artist: song.artist,
              album: song.album,
              genre: song.genre,
              artUri: song.artUri,
              duration: _playback.duration,
              isPlaying: _playback.isPlaying,
              position: _playback.position,
              speed: _playback.speed ?? 1.0,
            ),
    );
  }

  Future<void> dispose() async {
    _unbind();
    await _subscription?.cancel();
    _playback.removeListener(_updateState);
  }
}
