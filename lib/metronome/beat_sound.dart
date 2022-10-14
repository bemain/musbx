import 'package:flutter/material.dart';

enum BeatSound {
  primary(fileName: "sticks.wav"),
  accented(fileName: "cowbell.mp3"),
  none(fileName: "");

  const BeatSound({required this.fileName});

  /// File used when playing this sound, e.g. in BeatSounds.
  final String fileName;
}

/// The color used when displaying [BeatSound], e.g. in BeatSoundViewer.
Color beatSoundColor(BuildContext context, BeatSound beatSound) {
  switch (beatSound) {
    case BeatSound.primary:
      return Theme.of(context).colorScheme.primary;
    case BeatSound.accented:
      return Theme.of(context).colorScheme.secondary;
    case BeatSound.none:
      return Theme.of(context).colorScheme.background;
  }
}
