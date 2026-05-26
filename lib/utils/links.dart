import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/audio_provider.dart';
import 'package:musbx/songs/player/library.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:uri_content/uri_content.dart';
import 'package:uuid/uuid.dart';

class Links {
  /// Whether this has been initialized by calling [initialize].
  static bool isInitialized = false;

  static late final StreamSubscription<Uri> subscription;

  static void initialize() {
    if (isInitialized) return;
    isInitialized = true;

    subscription = AppLinks().uriLinkStream.listen((uri) async {
      final Song song;
      try {
        switch (uri.scheme) {
          case "file":
            song = await SongLibrary.addFile(File(uri.toFilePath()));

          case "content" || "data":
            final Uint8List content = await uri.getContent();
            final String id = Uuid().v4();
            song = await SongLibrary.add(
              Song(
                id: id,
                title: id,
                audio: BytesAudio(content),
              ),
            );

          case _:
            return;
        }
      } catch (e) {
        debugPrint("Error resolving file URI: $e");
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

  static void dispose() {
    if (!isInitialized) return;

    subscription.cancel();
  }
}
