import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/slowdowner.dart';

class PickFileButton extends StatelessWidget {
  const PickFileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
        );

        if (result != null && result.files.single.path != null) {
          await Slowdowner.instance.setFilePath(result.files.single.path!);
          Slowdowner.instance.songTitle = result.files.single.name;
        }
      },
      child: const Icon(Icons.file_upload_rounded),
    );
  }
}
