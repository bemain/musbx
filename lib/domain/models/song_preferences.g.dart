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
      parts: (json['parts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          $enumDecode(_$PartEnumMap, k),
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
      'parts': instance.parts?.map(
        (k, e) => MapEntry(_$PartEnumMap[k]!, <String, dynamic>{
          'enabled': e.enabled,
          'volume': e.volume,
        }),
      ),
    };

$Rec _$recordConvert<$Rec>(Object? value, $Rec Function(Map) convert) =>
    convert(value as Map<String, dynamic>);

const _$PartEnumMap = {
  Part.vocals: 'vocals',
  Part.piano: 'piano',
  Part.guitar: 'guitar',
  Part.bass: 'bass',
  Part.drums: 'drums',
  Part.other: 'other',
};
