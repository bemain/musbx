// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackEntry _$FeedbackEntryFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['id', 'created_at']);
  return FeedbackEntry(
    id: json['id'] as String?,
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    content: json['content'] as String?,
    sentBy: json['sent_by'] as String?,
    responseTo: json['response_to'] as String?,
  );
}

Map<String, dynamic> _$FeedbackEntryToJson(FeedbackEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt.toIso8601String(),
      'content': instance.content,
      'sent_by': instance.sentBy,
      'response_to': instance.responseTo,
    };
