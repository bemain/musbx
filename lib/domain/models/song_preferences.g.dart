// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SongPreferences _$SongPreferencesFromJson(Map<String, dynamic> json) =>
    SongPreferences(
      position: json['position'] == null
          ? null
          : Duration(microseconds: (json['position'] as num).toInt()),
      speed: (json['speed'] as num?)?.toDouble(),
      pitch: (json['pitch'] as num?)?.toDouble(),
      loopStart: json['loopStart'] == null
          ? null
          : Duration(microseconds: (json['loopStart'] as num).toInt()),
      loopEnd: json['loopEnd'] == null
          ? null
          : Duration(microseconds: (json['loopEnd'] as num).toInt()),
      numEqualizerBands: (json['numEqualizerBands'] as num?)?.toInt(),
      equalizerGains: (json['equalizerGains'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toDouble()),
      ),
      shouldDemix: json['shouldDemix'] as bool?,
      stems: (json['stems'] as Map<String, dynamic>?)?.map(
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
      ),
    );

Map<String, dynamic> _$SongPreferencesToJson(SongPreferences instance) =>
    <String, dynamic>{
      'position': instance.position?.inMicroseconds,
      'speed': instance.speed,
      'pitch': instance.pitch,
      'loopStart': instance.loopStart?.inMicroseconds,
      'loopEnd': instance.loopEnd?.inMicroseconds,
      'numEqualizerBands': instance.numEqualizerBands,
      'equalizerGains': instance.equalizerGains?.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'shouldDemix': instance.shouldDemix,
      'stems': instance.stems?.map(
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
