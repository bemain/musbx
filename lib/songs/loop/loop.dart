import 'package:flutter/material.dart';
import 'package:material_plus/material_plus.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/utils/utils.dart';

class LoopComponent extends SongPlayerComponent {
  LoopComponent(super.player);

  /// The start of the section being looped.
  Duration get start => sectionNotifier.value.$1;
  set start(Duration value) =>
      sectionNotifier.value = (value, sectionNotifier.value.$2);

  /// The end of the section being looped.
  Duration get end => sectionNotifier.value.$2;
  set end(Duration value) =>
      sectionNotifier.value = (sectionNotifier.value.$1, value);

  /// The section being looped.
  /// The first value is the [start] and the second is the [end] of the section.
  (Duration start, Duration end) get section => (start, end);
  set section((Duration start, Duration end) value) {
    start = value.$1;
    end = value.$2;
  }

  late final ValueNotifier<(Duration start, Duration end)> sectionNotifier =
      ValueNotifier((Duration.zero, player.duration))
        ..addListener(notifyListeners);

  @override
  Future<void> initialize() async {
    player.positionNotifier.addListener(() {
      if (player.position < start || player.position > end) {
        if (player.isPlaying) {
          // Seek to the start
          player.seek(start);
        } else {
          // Clamp the current position to the looped section
          player.position = clamp(player.position);
        }
      }
    });
    addListener(() {
      if (player.position < start || player.position > end) {
        player.position = clamp(player.position);
      }
    });
  }

  /// Clamp [position] to between [start] and [end].
  Duration clamp(Duration position) {
    return position.clamp(start, end);
  }

  /// Load settings from a [json] map.
  ///
  /// [json] can contain the following key-value pairs (beyond `enabled`):
  ///  - `start` [int] The start position of the section being looped, in milliseconds.
  ///  - `end` [int] The end position of the section being looped, in milliseconds.
  ///
  /// If start and end don't make a valid LoopSection (e.g. if start > end) no values are set.
  @override
  void loadPreferencesFromJson(Json json) {
    super.loadPreferencesFromJson(json);

    Duration start = Duration(milliseconds: tryCast<int>(json['start']) ?? 0);
    Duration end = Duration(
      milliseconds:
          tryCast<int>(json['end']) ?? player.duration.inMilliseconds,
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

    this.start = start;
    this.end = end;

    notifyListeners();
  }

  /// Save settings for a song to a json map.
  ///
  /// Saves the following key-value pairs (beyond `enabled`):
  ///  - `start` [int] The start position of the section being looped, in milliseconds.
  ///  - `end` [int] The end position of the section being looped, in milliseconds.
  @override
  Json savePreferencesToJson() {
    return {
      ...super.savePreferencesToJson(),
      "start": start.inMilliseconds,
      "end": end.inMilliseconds,
    };
  }
}
