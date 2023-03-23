import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/widgets.dart';

/// Base class for all components that alter the audio being played by [MusicPlayer].
///
/// The component is responsible for all communication between itself and MusicPlayer.
abstract class MusicPlayerComponent {
  /// Whether we are currently looping a section of the song or not.
  bool get enabled => enabledNotifier.value;
  set enabled(bool value) => enabledNotifier.value = value;
  final ValueNotifier<bool> enabledNotifier = ValueNotifier(true);

  /// Called by [MusicPlayer] during initialization.
  ///
  /// When this method is called, the component should set up all the
  /// communication needed between itself and [MusicPlayer].
  /// This includes listening to any of [MusicPlayer]'s ValueNotifiers that the
  /// component needs to respond to, and adding triggers for updating values on [MusicPlayer].
  void initialize(MusicPlayer musicPlayer);

  /// Load settings from a [json] map.
  ///
  /// Called when a song that has preferences saved is loaded.
  ///
  /// By default, handles the following key-value pair:
  ///   "enabled": [bool] Whether this component is enabled or not.
  ///
  /// Implementations should be able to handle a value being null,
  /// and never expect a specific key to exist in [json].
  @mustCallSuper
  void loadSettingsFromJson(Map<String, dynamic> json) {
    enabled = tryCast<bool>(json["enabled"]) ?? enabled;
  }
}
