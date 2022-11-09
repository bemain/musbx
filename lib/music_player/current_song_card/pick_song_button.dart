import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class PickSongButton extends StatelessWidget {
  /// Button for picking a song from the device and loading it to [MusicPlayer].
  const PickSongButton({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return OutlinedButton(
      onPressed: musicPlayer.isLoading
          ? null
          : () async {
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
            },
      child: const Icon(Icons.file_upload_rounded),
    );
  }
}
