import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

/// Base class for all components that alter the audio being played by [MusicPlayer].
abstract class MusicPlayerComponent {
  /// Whether we are currently looping a section of the song or not.
  bool get enabled => enabledNotifier.value;
  set enabled(bool value) => enabledNotifier.value = value;
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);

  /// Called when [MusicPlayer] is created.
  ///
  /// During initialization, the component is responsible for setting up all the
  /// communication needed between itself and [MusicPlayer].
  /// This includes listening to any of [MusicPlayer]'s ValueNotifiers that the
  /// component needs to respond to, and adding triggers for updating values on [MusicPlayer].
  void initialize(MusicPlayer musicPlayer);
}
