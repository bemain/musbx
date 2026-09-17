// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Song _$SongFromJson(Map<String, dynamic> json) => Song(
  id: json['id'] as String,
  title: json['title'] as String,
  album: json['album'] as String?,
  artist: json['artist'] as String?,
  genre: json['genre'] as String?,
  artUri: json['artUri'] == null ? null : Uri.parse(json['artUri'] as String),
  audio: AudioReference.fromJson(json['audio'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'album': instance.album,
  'artist': instance.artist,
  'genre': instance.genre,
  'artUri': instance.artUri?.toString(),
  'audio': instance.audio,
};
