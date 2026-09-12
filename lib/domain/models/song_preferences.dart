import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/domain/models/stem_type.dart';
import 'package:musbx/utils/utils.dart';

part 'song_preferences.g.dart';

@JsonSerializable()
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

  final Duration? position;

  final double? speed;
  final double? pitch;

  final Duration? loopStart;
  final Duration? loopEnd;

  final int? numEqualizerBands;

  final Map<int, double>? equalizerGains;

  /// Whether this song should be demixed or not.
  final bool? shouldDemix;

  final Map<StemType, ({bool enabled, double volume})>? stems;

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
