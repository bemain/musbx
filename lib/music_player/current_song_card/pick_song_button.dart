import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/exception_dialogs.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/permission_builder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

const List<String> allowedExtensions = [
  "mp3",
  "ogg",
  "wav",
  "mp4",
  "m4a",
  "mka",
];

class PickSongButton extends StatelessWidget {
  /// Whether permission to read external storage has been given or not.
  static bool permissionGranted = false;

  /// Button for picking a song from the device and loading it to [MusicPlayer].
  PickSongButton({super.key});

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: musicPlayer.isLoading
          ? null
          : () {
              if (permissionGranted) {
                pickFile(context);
              } else {
                pushPermissionBuilder(context);
              }
            },
      child: const Icon(Icons.file_upload_rounded),
    );
  }

  Future<void> pickFile(BuildContext context) async {
    MusicPlayerState prevState = musicPlayer.state;
    musicPlayer.stateNotifier.value = MusicPlayerState.pickingAudio;

    // By some reason, setting type to FileType.audio causes the file picker to not show up on iOS.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: Platform.isIOS ? FileType.any : FileType.audio,
    );

    if (result == null || result.files.single.path == null) {
      // Restore state
      musicPlayer.stateNotifier.value = prevState;
      return;
    }
    String extension = result.files.single.path!.split(".").last;
    if (!allowedExtensions.contains(extension)) {
      showExceptionDialog(UnsupportedFileExtensionDialog(extension: extension));

      // Restore state
      musicPlayer.stateNotifier.value = prevState;
      return;
    }

    try {
      await musicPlayer.loadFile(result.files.single);
    } catch (error) {
      showExceptionDialog(const FileCouldNotBeLoadedDialog());

      // Restore state
      musicPlayer.stateNotifier.value = prevState;
      return;
    }
  }

  void pushPermissionBuilder(BuildContext context) async {
    // On Android sdk 33 or greater, use of granular permissionss is required
    final bool useGranularPermissions = !Platform.isAndroid
        ? false
        : (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33;

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
          permissionDeniedIcon: const Icon(Icons.storage_rounded, size: 128),
          permissionGrantedIcon: const Icon(Icons.storage_rounded, size: 128),
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
