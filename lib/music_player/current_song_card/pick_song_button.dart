import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/permission_builder.dart';
import 'package:permission_handler/permission_handler.dart';

class PickSongButton extends StatelessWidget {
  /// Button for picking a song from the device and loading it to [MusicPlayer].
  PickSongButton({super.key});

  /// Whether permission to read external storage has been given or not.
  static bool permissionGranted = false;

  final MusicPlayer musicPlayer = MusicPlayer.instance;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: musicPlayer.isLoading
          ? null
          : () {
              if (permissionGranted) {
                pickFile();
                return;
              }
              pushPermissionBuilder(context);
            },
      child: const Icon(Icons.file_upload_rounded),
    );
  }

  Future<void> pickFile() async {
    MusicPlayerState prevState = musicPlayer.state;
    musicPlayer.stateNotifier.value = MusicPlayerState.pickingAudio;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      await musicPlayer.playFile(result.files.single);
    } else {
      // Restore state
      musicPlayer.stateNotifier.value = prevState;
    }
  }

  void pushPermissionBuilder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        body: PermissionBuilder(
          permission: Permission.storage,
          permissionName: "external storage",
          permissionText:
              "To load audio from the device, give the app permission to access external storage.",
          permissionDeniedIcon: const Icon(Icons.storage_rounded, size: 128),
          permissionGrantedIcon: const Icon(Icons.storage_rounded, size: 128),
          onPermissionGranted: () {
            permissionGranted = true;

            Navigator.of(context).pop();
            pickFile();
          },
        ),
      ),
    ));
  }
}
