import 'package:flutter/material.dart';

/// Base class for all components that alter the audio being played by [MusicPlayer].
abstract class MusicPlayerComponent {
  /// Whether we are currently looping a section of the song or not.
  bool get enabled => enabledNotifier.value;
  set enabled(bool value) => enabledNotifier.value = value;
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);
}
