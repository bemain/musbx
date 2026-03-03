import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/library.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:uri_to_file/uri_to_file.dart';

class Links {
  /// Whether this has been initialized by calling [initialize].
  static bool isInitialized = false;

  static late final StreamSubscription<Uri> subscription;

  static void initialize() {
    if (isInitialized) return;
    isInitialized = true;

    subscription = AppLinks().uriLinkStream.listen((uri) async {
      switch (uri.scheme) {
        case "content" || "file":
          File? file = await _getFile(uri);
          if (file == null) return;

          if (Songs.isAccessRestricted) {
            await showExceptionDialog(
              const MusicPlayerAccessRestrictedDialog(),
            );
            return;
          }

          final Song song = await SongLibrary.addFile(file);
          await Navigation.navigatorKey.currentContext?.push(
            Routes.song(song.id),
          );
      }
    });
  }

  /// Try to get the file that the [uri] points to.
  static Future<File?> _getFile(Uri uri) async {
    try {
      // Handle Android Content URIs
      if (Platform.isAndroid && uri.scheme == 'content') {
        return await toFile(uri.toString());
      }

      // Handle standard file:// URIs
      if (uri.isScheme('file')) {
        return File(uri.toFilePath());
      }
    } catch (e) {
      debugPrint("Error resolving file URI: $e");
    }

    return null;
  }

  static void dispose() {
    if (!isInitialized) return;

    subscription.cancel();
  }
}
