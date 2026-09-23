// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackState _$PlaybackStateFromJson(Map<String, dynamic> json) =>
    PlaybackState(
      song: Song.fromJson(json['song'] as Map<String, dynamic>),
      isPlaying: json['isPlaying'] as bool,
      position: json['position'] == null
          ? Duration.zero
          : Duration(microseconds: (json['position'] as num).toInt()),
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      loopSection:
          _$recordConvert(
            json['loopSection'],
            ($jsonValue) => (
              end: $jsonValue['end'] == null
                  ? null
                  : Duration(microseconds: ($jsonValue['end'] as num).toInt()),
              start: $jsonValue['start'] == null
                  ? null
                  : Duration(
                      microseconds: ($jsonValue['start'] as num).toInt(),
                    ),
            ),
          ) ??
          (start: null, end: null),
      equalizerGain:
          (json['equalizerGain'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      stems:
          (json['stems'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              $enumDecode(_$StemTypeEnumMap, k),
              _$recordConvert(
                e,
                ($jsonValue) => (
                  enabled: $jsonValue['enabled'] as bool,
                  volume: ($jsonValue['volume'] as num).toDouble(),
                ),
              ),
            ),
          ) ??
          const {},
    );

Map<String, dynamic> _$PlaybackStateToJson(PlaybackState instance) =>
    <String, dynamic>{
      'song': instance.song,
      'isPlaying': instance.isPlaying,
      'position': instance.position.inMicroseconds,
      'speed': instance.speed,
      'pitch': instance.pitch,
      'loopSection': <String, dynamic>{
        'end': instance.loopSection.end?.inMicroseconds,
        'start': instance.loopSection.start?.inMicroseconds,
      },
      'equalizerGain': instance.equalizerGain,
      'stems': instance.stems.map(
        (k, e) => MapEntry(_$StemTypeEnumMap[k]!, <String, dynamic>{
          'enabled': e.enabled,
          'volume': e.volume,
        }),
      ),
    };

$Rec _$recordConvert<$Rec>(Object? value, $Rec Function(Map) convert) =>
    convert(value as Map<String, dynamic>);

const _$StemTypeEnumMap = {
  StemType.vocals: 'vocals',
  StemType.piano: 'piano',
  StemType.guitar: 'guitar',
  StemType.bass: 'bass',
  StemType.drums: 'drums',
  StemType.other: 'other',
};
