import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/songs/player/playable.dart';
import 'package:musbx/songs/player/song.dart';
import 'package:musbx/songs/player/songs.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:musbx/widgets/speed_dial/speed_dial.dart';
import 'package:musbx/widgets/speed_dial/action.dart';
import 'package:musbx/widgets/permission_builder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show File, Platform;

const List<String> allowedExtensions = [
  "mp3",
  "ogg",
  "wav",
];

/// A child of [SpeedDial] that looks similar to a [SpeedDialAction] but with a primary color.
///
/// When pressed, allows the user to upload a song from their devices and loads that song to [MusicPlayer].
class UploadSongButton extends SpeedDialChild {
  /// Whether permission to read external storage has been given or not.
  static bool permissionGranted = false;

  @override
  Widget assemble(BuildContext context, Animation<double> animation) {
    final SpeedDialAction action = SpeedDialAction(
      onPressed: (event) {
        if (permissionGranted) {
          pickFile(context);
        } else {
          pushPermissionBuilder(context);
        }
      },
      label: const Text("Upload"),
      child: const Icon(Symbols.upload),
    );

    return action.assemble(context, animation);
  }

  Future<void> pickFile(BuildContext context) async {
    // By some reason, setting type to FileType.audio causes the file picker to not show up on iOS.
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: Platform.isIOS ? FileType.any : FileType.audio,
    );
    final PlatformFile? file = result?.files.single;

    if (file?.path == null) return;

    final String extension = file!.path!.split(".").last;
    if (!allowedExtensions.contains(extension)) {
      showExceptionDialog(UnsupportedFileExtensionDialog(extension: extension));

      return;
    }

    final String id = file.path!.hashCode.toString();

    await Songs.history.add(SongNew<SinglePlayable>(
      id: id,
      title: file.name.split(".").first,
      source: FileSource(File(file.path!)),
    ));

    Navigation.navigatorKey.currentContext?.go(Navigation.songRoute(id));
  }

  void pushPermissionBuilder(BuildContext context) async {
    // On Android sdk 33 or greater, use of granular permissions is required
    final bool useGranularPermissions = !Platform.isAndroid
        ? false
        : (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33;

    if (!context.mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        body: PermissionBuilder(
          permission:
              (useGranularPermissions) ? Permission.audio : Permission.storage,
          permissionName: (useGranularPermissions || Platform.isIOS)
              ? "audio files"
              : "external storage",
          permissionText:
              "To load audio from the device, give the app permission to access ${(useGranularPermissions || Platform.isIOS) ? "external storage" : "audio files"}.",
          permissionDeniedIcon: const Icon(Symbols.storage_rounded, size: 128),
          permissionGrantedIcon: const Icon(Symbols.storage_rounded, size: 128),
          onPermissionGranted: () {
            permissionGranted = true;

            Navigator.of(context).pop();
            pickFile(context);
          },
        ),
      ),
    ));
  }
}
