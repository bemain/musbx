import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/database/model.dart';
import 'package:musbx/utils/utils.dart';

part 'announcement.g.dart';

@JsonSerializable()
class Announcement extends Model {
  /// An announcement shown to all users on startup.
  Announcement({
    super.id,
    super.createdAt,
    required this.title,
    required this.content,
  });

  /// The title of this announcement.
  final String title;

  /// The content of this announcement.
  final String? content;

  static Announcement fromJson(Json json) => _$AnnouncementFromJson(json);

  @override
  Json toJson() => _$AnnouncementToJson(this);

  @override
  String toString() => "Announcement($title)";
}
