import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';
import 'package:musbx/widgets.dart';

/// A component for [MusicPlayer] that is used to loop a section of a song.
class Looper extends MusicPlayerComponent {
  /// The section being looped.
  LoopSection get section => sectionNotifier.value;
  set section(LoopSection section) => sectionNotifier.value = section;
  late final ValueNotifier<LoopSection> sectionNotifier =
      ValueNotifier(LoopSection())..addListener(_setClip);

  @override
  void initialize(MusicPlayer musicPlayer) {
    enabledNotifier.addListener(_setClip);
  }

  /// Set the [MusicPlayer]'s clip to the currently looped [section],
  /// or reset it if this component is disabled.
  Future<void> _setClip() async {
    final MusicPlayer musicPlayer = MusicPlayer.instance;
    if (musicPlayer.state != MusicPlayerState.ready) return;

    if (enabled) {
      await musicPlayer.player.setClip(start: section.start, end: section.end);
    } else {
      // Reset
      await musicPlayer.player.setClip();
    }
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond `enabled`):
  ///  - `start` [int] The start position of the section being looped, in milliseconds.
  ///  - `end` [int] The end position of the section being looped, in milliseconds.
  ///
  /// If start and end don't make a valid LoopSection (e.g. if start > end) the looped [section] is not set.
  @override
  void loadSettingsFromJson(Map<String, dynamic> json) {
    super.loadSettingsFromJson(json);

    Duration start = Duration(milliseconds: tryCast<int>(json["start"]) ?? 0);
    Duration end = Duration(
      milliseconds: tryCast<int>(json["end"]) ??
          MusicPlayer.instance.duration.inMilliseconds,
    );

    if (end < start) {
      debugPrint("[LOOPER] Invalid LoopSection, start ($start) > end ($end)");
      return;
    }
    if (start < Duration.zero) {
      debugPrint("[LOOPER] Invalid LoopSection, start ($start) < 0");
      return;
    }
    if (end > MusicPlayer.instance.duration) {
      debugPrint(
        "[LOOPER] Invalid LoopSection, end ($end) > duration (${MusicPlayer.instance.duration})",
      );
      return;
    }

    section = LoopSection(start: start, end: end);
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs (beyond `enabled`):
  ///  - `start` [int] The start position of the section being looped, in milliseconds.
  ///  - `end` [int] The end position of the section being looped, in milliseconds.
  @override
  Map<String, dynamic> saveSettingsToJson() {
    return {
      ...super.saveSettingsToJson(),
      "start": section.start.inMilliseconds,
      "end": section.end.inMilliseconds,
    };
  }
}

/// Representation of a sect by [Looper] to select what section of the song to loop.
class LoopSection {
  LoopSection({
    this.start = Duration.zero,
    this.end = const Duration(seconds: 1),
  }) {
    assert(start <= end);
  }

  final Duration start;
  final Duration end;

  /// Duration between [start] and [end].
  Duration get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is LoopSection && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}
