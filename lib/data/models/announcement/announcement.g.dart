// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['id', 'created_at']);
  return Announcement(
    id: json['id'] as String?,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    title: json['title'] as String,
    content: json['content'] as String?,
    responses: json['responses'] == null
        ? null
        : AnnouncementResponses.fromJson(
            json['responses'] as Map<String, dynamic>,
          ),
    popup: json['popup'] as bool? ?? false,
  );
}

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'title': instance.title,
      'content': instance.content,
      'responses': instance.responses,
      'popup': instance.popup,
    };

AnnouncementResponses _$AnnouncementResponsesFromJson(
  Map<String, dynamic> json,
) => AnnouncementResponses(
  allowMultiple: json['allow_multiple'] as bool? ?? false,
  showOther: json['show_other'] as bool? ?? false,
  responses: (json['responses'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AnnouncementResponsesToJson(
  AnnouncementResponses instance,
) => <String, dynamic>{
  'allow_multiple': instance.allowMultiple,
  'show_other': instance.showOther,
  'responses': instance.responses,
};
