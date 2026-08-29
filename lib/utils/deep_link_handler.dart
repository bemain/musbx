import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:musbx/data/services/deep_links_service.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/library.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

/// Opens the songs the operating system hands the app.
///
/// [DeepLinksService] stops at turning a URI into a [Song]; this is the half
/// that acts on one — storing it in the library, then either navigating to it or
/// explaining why it cannot be opened. Those are app-level decisions rather than
/// data ones, which is why they live here and not in the service.
///
/// Only one may exist at a time. [DeepLinksService.songStream] takes a single
/// listener and throws on a second, which would add the same song twice.
///
/// Listening starts in the constructor and runs until [dispose], so constructing
/// one is the whole of using it. Build it only once there is a navigator to push
/// onto: the operating system announces a launch file before there is an app to
/// show it in, and the song is held until this listener attaches, so a handler
/// built any earlier adds the song to the library and then silently fails to
/// navigate to it.
class DeepLinkHandler {
  DeepLinkHandler({required DeepLinksService deepLinksService})
    : _deepLinksService = deepLinksService {
    _subscription = _deepLinksService.songStream.listen((song) async {
      try {
        song = await SongLibrary.add(song);
      } catch (error) {
        debugPrint(
          "[Launch handler] Error occured while adding song '$song': $error",
        );
        return;
      }

      if (Songs.isAccessRestricted) {
        await showExceptionDialog(
          const MusicPlayerAccessRestrictedDialog(),
        );
      } else {
        await Navigation.navigatorKey.currentContext?.push(
          Routes.song(song.id),
        );
      }
    });
  }

  final DeepLinksService _deepLinksService;

  /// Carries the songs the service resolves, for as long as this handler lives.
  late final StreamSubscription<Song> _subscription;

  /// Stop opening incoming songs.
  ///
  /// Songs the service resolves after this reach nothing, so this belongs to the
  /// app shutting down rather than to a screen going away.
  Future<void> dispose() async {
    await _subscription.cancel();
  }
}
