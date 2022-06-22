import 'package:flutter/material.dart';
import 'package:musbx/slowdowner/pick_file_button.dart';
import 'package:musbx/slowdowner/slowdowner.dart';

class CurrentSongPanel extends StatelessWidget {
  /// Panel displaying the currently loaded song, with buttons to load a new song,
  /// from a local file or from YouTube (WIP)
  const CurrentSongPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Currently playing:",
                style: Theme.of(context).textTheme.caption,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  Slowdowner.instance.songTitle ?? "Test",
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const PickFileButton(),
      ],
    );
  }
}
