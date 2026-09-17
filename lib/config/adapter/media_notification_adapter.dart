import 'dart:async';

import 'package:musbx/data/models/media_command.dart';
import 'package:musbx/data/models/media_notification_state.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/services/media_notification_service.dart';
import 'package:musbx/domain/use_case/unload_song.dart';

class MediaNotificationAdapter {
  MediaNotificationAdapter({
    required MediaNotificationService mediaNotification,
    required PlaybackRepository playback,
    required UnloadSong unloadSong,
  }) : _playback = playback,
       _mediaNotification = mediaNotification {
    if (mediaNotification.isEnabled) {
      _subscription = mediaNotification.commands.listen(
        (command) => switch (command) {
          Play() => playback.resume(),
          Pause() => playback.pause(),
          Stop() => unloadSong.call(),
          Seek(:final position) => playback.seek(position),
        },
      );

      playback.addListener(_updateState);
    }
  }

  final PlaybackRepository _playback;
  final MediaNotificationService _mediaNotification;
  StreamSubscription<MediaCommand>? _subscription;

  void _updateState() {
    final song = _playback.song;
    _mediaNotification.update(
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
              speed: _playback.speed,
            ),
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _playback.removeListener(_updateState);
  }
}
