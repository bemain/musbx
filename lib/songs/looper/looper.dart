import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/widgets/widgets.dart';

class LoopComponent extends SongPlayerComponent {
  LoopComponent(super.player);

  /// The section being looped.
  LoopSection get section => sectionNotifier.value;
  set section(LoopSection section) => sectionNotifier.value = section;
  final ValueNotifier<LoopSection> sectionNotifier =
      ValueNotifier(LoopSection());

  @override
  FutureOr<void> initialize() {
    player.positionNotifier.addListener(() {
      // Clamp the current position to the looped section
      if (player.position < section.start || player.position > section.end) {
        player.seek(player.position);
      }
    });
    sectionNotifier.addListener(() async {
      // Clamp the current position to the looped section
      if (player.position < section.start || player.position > section.end) {
        player.seek(player.position);
      }
    });
  }

  /// Clamp [position] to between [section.start] and [section.end].
  Duration clamp(Duration position) {
    return Duration(
      milliseconds: position.inMilliseconds.clamp(
        section.start.inMilliseconds,
        section.end.inMilliseconds,
      ),
    );
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
      milliseconds: tryCast<int>(json["end"]) ?? player.duration.inMilliseconds,
    );

    if (end < start) {
      debugPrint("[LOOPER] Invalid LoopSection, start ($start) > end ($end)");
      return;
    }
    if (start < Duration.zero) {
      debugPrint("[LOOPER] Invalid LoopSection, start ($start) < 0");
      return;
    }
    if (end > player.duration) {
      debugPrint(
        "[LOOPER] Invalid LoopSection, end ($end) > duration (${player.duration})",
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
