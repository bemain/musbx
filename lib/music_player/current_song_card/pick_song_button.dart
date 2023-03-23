import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/permission_builder.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// Required to show dialog. Probably not the best way to do this...
  late final BuildContext _navigatorContext;

  @override
  Widget build(BuildContext context) {
    _navigatorContext = Navigator.of(context).context;
    return OutlinedButton(
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

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null || result.files.single.path == null) {
      // Restore state
      musicPlayer.stateNotifier.value = prevState;
      return;
    }
    String extension = result.files.single.path!.split(".").last;
    if (!allowedExtensions.contains(extension)) {
      showUnsupportedFileExtensionDialog(extension);
      // Restore state
      musicPlayer.stateNotifier.value = prevState;
      return;
    }

    await musicPlayer.loadFile(result.files.single);
  }

  Future<void> showUnsupportedFileExtensionDialog(String extension) async {
    await showDialog(
      context: _navigatorContext,
      builder: (context) => AlertDialog(
        title: const Text("Unsupported file type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_present_rounded, size: 128),
            const SizedBox(height: 15),
            Text(
                "The file type '.$extension' is not supported. Try loading a different file.")
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Dismiss"),
          )
        ],
      ),
    );
  }

  void pushPermissionBuilder(BuildContext context) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (newContext) => Scaffold(
        body: PermissionBuilder(
          permission: (androidInfo.version.sdkInt <= 32)
              ? Permission.storage
              : Permission.audio,
          permissionName: (androidInfo.version.sdkInt <= 32)
              ? "external storage"
              : "audio files",
          permissionText:
              "To load audio from the device, give the app permission to access ${(androidInfo.version.sdkInt <= 32) ? "external storage" : "audio files"}.",
          permissionDeniedIcon: const Icon(Icons.storage_rounded, size: 128),
          permissionGrantedIcon: const Icon(Icons.storage_rounded, size: 128),
          onPermissionGranted: () {
            permissionGranted = true;

            Navigator.of(newContext).pop();
            pickFile(context);
          },
        ),
      ),
    ));
  }
}
