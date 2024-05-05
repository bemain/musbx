enum BeatSound {
  primary("sticks_low.mp3"),
  accented("sticks_high.mp3"),
  none("silence.mp3");

  const BeatSound(this.fileName);

  /// Name of the file used when playing this sound.
  final String fileName;
}
