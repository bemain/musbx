import 'package:flutter/material.dart';

enum BeatSound {
  primary("sticks_low.mp3"),
  accented("sticks_high.mp3"),
  none("silence.mp3");

  const BeatSound(this.fileName);

  /// Name of the file used when playing this sound.
  final String fileName;
}

/// The color used when displaying [BeatSound], e.g. in BeatSoundViewer.
Color beatSoundColor(BuildContext context, BeatSound beatSound) {
  switch (beatSound) {
    case BeatSound.primary:
      return Theme.of(context).colorScheme.primary;
    case BeatSound.accented:
      return Theme.of(context).colorScheme.inversePrimary;
    case BeatSound.none:
      return Theme.of(context).colorScheme.background;
  }
}
