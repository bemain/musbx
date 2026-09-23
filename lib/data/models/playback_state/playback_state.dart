import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/domain/models/stem_type.dart';
import 'package:musbx/utils/utils.dart';

part 'playback_state.g.dart';

/// The part of a song that playback is confined to. A `null` end is the end of
/// the song, a `null` start its beginning.
typedef LoopSection = ({Duration? start, Duration? end});

typedef StemData = ({bool enabled, double volume});

@JsonSerializable()
class PlaybackState {
  PlaybackState({
    required this.song,
    required this.isPlaying,
    this.position = Duration.zero,
    this.speed = 1.0,
    this.pitch = 0.0,
    this.loopSection = (start: null, end: null),
    this.equalizerGain = const [],
    this.stems = const {},
  });

  final Song song;

  final bool isPlaying;

  final Duration position;

  final double speed;
  final double pitch;

  final LoopSection loopSection;

  final List<double> equalizerGain;

  final Map<StemType, StemData> stems;

  /// Create a copy of this [PlaybackState] with the specified fields replaced
  /// with new values.
  ///
  /// If a field is not specified, it will be copied from this [PlaybackState].
  ///
  /// Example:
  /// ```dart
  /// final PlaybackState paused = state.copyWith(isPlaying: false);
  /// ```
  PlaybackState copyWith({
    Song? song,
    bool? isPlaying,
    Duration? position,
    double? speed,
    double? pitch,
    LoopSection? loopSection,
    List<double>? equalizerGain,
    Map<StemType, StemData>? stems,
  }) {
    return PlaybackState(
      song: song ?? this.song,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      loopSection: loopSection ?? this.loopSection,
      equalizerGain: equalizerGain ?? this.equalizerGain,
      stems: stems ?? this.stems,
    );
  }

  static PlaybackState fromJson(Json json) => _$PlaybackStateFromJson(json);

  Json toJson() => _$PlaybackStateToJson(this);
}
