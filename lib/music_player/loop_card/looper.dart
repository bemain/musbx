import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player_component.dart';

/// A component for [MusicPlayer] that is used to loop a section of a song.
class Looper extends MusicPlayerComponent {
  /// The section being looped.
  LoopSection get section => sectionNotifier.value;
  set section(LoopSection section) => sectionNotifier.value = section;
  final ValueNotifier<LoopSection> sectionNotifier =
      ValueNotifier(LoopSection());

  /// Clamp [position] to between [section.start] and [section.end], or between 0 and [duration] if this component is not [enabled].
  Duration clampPosition(Duration position, {required Duration duration}) {
    return Duration(
      milliseconds: position.inMilliseconds.clamp(
        (enabled) ? section.start.inMilliseconds : 0,
        (enabled) ? section.end.inMilliseconds : duration.inMilliseconds,
      ),
    );
  }
}

/// Used by [Looper] to select what section of the song to loop.
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
