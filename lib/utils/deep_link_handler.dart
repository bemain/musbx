import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/services/deep_links_service.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/use_case/check_song_access.dart';
import 'package:musbx/routing/router.dart';
import 'package:musbx/routing/routes.dart';
import 'package:musbx/utils/result.dart';
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
  DeepLinkHandler({
    required DeepLinksService deepLinks,
    required SongRepository songs,
    required CheckSongAccess checkSongAccess,
  }) {
    _subscription = deepLinks.songStream.listen((song) async {
      if (await songs.add(song) case Failure(:final error)) {
        debugPrint(
          "[Launch handler] Error occured while adding song '$song': $error",
        );
        return;
      }

      if (checkSongAccess.isRestricted) {
        await showExceptionDialog(
          const MusicPlayerAccessRestrictedDialog(),
        );
      } else {
        await navigatorKey.currentContext?.push(Routes.song(song.id));
      }
    });
  }

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
