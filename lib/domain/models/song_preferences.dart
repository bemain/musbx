import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/domain/models/stem_type.dart';
import 'package:musbx/utils/utils.dart';

part 'song_preferences.g.dart';

@JsonSerializable()
/// How the user last left a song: where they were in it, and what they had
/// adjusted.
///
/// Read when a song is opened and written when it is closed, so that reopening
/// it picks up where they stopped. Every field is nullable, meaning "never set",
/// which is what lets a default change without overriding a deliberate choice.
class SongPreferences {
  const SongPreferences({
    this.position,
    this.speed,
    this.pitch,
    this.loopStart,
    this.loopEnd,
    this.numEqualizerBands,
    this.equalizerGains,
    this.shouldDemix,
    this.stems,
  });

  /// Where playback was left off.
  final Duration? position;

  /// How fast the song was played, as a fraction of its original tempo.
  final double? speed;

  /// How many semitones the song was transposed.
  final double? pitch;

  /// Where the looped section started.
  final Duration? loopStart;

  /// Where the looped section ended.
  final Duration? loopEnd;

  /// How many bands the equalizer was split into.
  final int? numEqualizerBands;

  /// The gain of each equalizer band, by band index.
  final Map<int, double>? equalizerGains;

  /// Whether this song should be demixed or not.
  final bool? shouldDemix;

  /// How loud each stem was, and whether it was heard at all.
  final Map<StemType, ({bool enabled, double volume})>? stems;

  /// A copy with the given fields replaced.
  ///
  /// [equalizerGains] and [stems] are merged into the existing ones rather than
  /// replacing them wholesale.
  SongPreferences copyWith({
    Duration? position,
    double? speed,
    double? pitch,
    Duration? loopStart,
    Duration? loopEnd,
    int? numEqualizerBands,
    Map<int, double>? equalizerGains,
    bool? shouldDemix,
    Map<StemType, ({bool enabled, double volume})>? stems,
  }) {
    return SongPreferences(
      position: position ?? this.position,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      loopStart: loopStart ?? this.loopStart,
      loopEnd: loopEnd ?? this.loopEnd,
      numEqualizerBands: numEqualizerBands ?? this.numEqualizerBands,
      equalizerGains: equalizerGains == null
          ? this.equalizerGains
          : {...?this.equalizerGains, ...equalizerGains},
      shouldDemix: shouldDemix ?? this.shouldDemix,
      stems: stems == null ? this.stems : {...?this.stems, ...stems},
    );
  }

  static SongPreferences fromJson(Json json) =>
      _$SongPreferencesFromJson(json);

  Json toJson() => _$SongPreferencesToJson(this);
}
