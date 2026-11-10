import 'dart:io' show Platform, File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/domain/models/permission.dart';
import 'package:musbx/routing/router.dart';
import 'package:musbx/routing/routes.dart';
import 'package:musbx/utils/result.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/widgets/permission_builder.dart';
import 'package:provider/provider.dart';

/// The audio file formats a song can be uploaded from.
const List<String> allowedExtensions = [
  "mp3",
  "ogg",
  "wav",
];

/// A child of [SpeedDial] that looks similar to a [SpeedDialAction] but with a
/// primary color.
///
/// When pressed, lets the user pick an audio file from their device, adds it to
/// the library and opens it. Asks for file access first if it has not been
/// granted.
class UploadSongButton extends SpeedDialChild {
  /// Whether permission to read external storage has been given or not.
  static bool permissionGranted = Platform.isAndroid || Platform.isIOS
      ? false
      : true;

  @override
  Widget assemble(BuildContext context, Animation<double> animation) {
    final SpeedDialAction action = SpeedDialAction(
      // The speed dial closes on tap, unmounting [context], so everything
      // needed from it is read before the first await.
      onPressed: (event) {
        final SongRepository songs = context.read<SongRepository>();
        if (permissionGranted) {
          pickFile(songs);
        } else {
          pushPermissionBuilder(Navigator.of(context), songs);
        }
      },
      label: const Text("Upload"),
      child: const Icon(Symbols.upload),
    );

    return action.assemble(context, animation);
  }

  Future<void> pickFile(SongRepository songs) async {
    // By some reason, setting type to FileType.audio causes the file picker to not show up on iOS.
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: Platform.isIOS ? FileType.any : FileType.audio,
    );
    final PlatformFile? file = result?.files.single;

    if (file?.path == null) return;

    final String extension = file!.path!.split(".").last;
    if (!allowedExtensions.contains(extension)) {
      await showExceptionDialog(
        UnsupportedFileExtensionDialog(extension: extension),
      );

      return;
    }

    switch (await songs.addFile(File(file.path!))) {
      case Ok(value: final song):
        navigatorKey.currentContext?.go(Routes.song(song.id));
      case Failure(:final error):
        debugPrint("[Library] Uploading file failed; $error");
      // TODO: Show error snackbar
    }
  }

  Future<void> pushPermissionBuilder(
    NavigatorState navigator,
    SongRepository songs,
  ) async {
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: PermissionBuilder(
            permission: Permission.audioFiles,
            permissionName: "audio files",
            permissionText:
                "To load audio from the device, give the app permission to access audio files.",
            permissionDeniedIcon: const Icon(
              Symbols.storage_rounded,
              size: 128,
            ),
            permissionGrantedIcon: const Icon(
              Symbols.storage_rounded,
              size: 128,
            ),
            onPermissionGranted: () {
              permissionGranted = true;

              navigator.pop();
              pickFile(songs);
            },
          ),
        ),
      ),
    );
  }
}
