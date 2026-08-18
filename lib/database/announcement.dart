import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/database/model.dart';
import 'package:musbx/utils/utils.dart';

part 'announcement.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum AnnouncementType {
  message,
  selectSingle,
  selectMulti,
}

@JsonSerializable()
class Announcement extends Model {
  /// An announcement shown to all users on startup.
  Announcement({
    super.id,
    super.createdAt,
    required this.title,
    this.content,
    this.responses,
    this.popup = false,
  });

  /// The title of this announcement.
  final String title;

  /// The content of this announcement.
  final String? content;

  /// The responses the user can pick from to react to this [Announcement].
  final AnnouncementResponses? responses;

  /// Whether to show this announcement as a popup on launch.
  final bool popup;

  static Announcement fromJson(Json json) => _$AnnouncementFromJson(json);

  @override
  Json toJson() => _$AnnouncementToJson(this);

  @override
  String toString() => "Announcement($id)";
}

@JsonSerializable()
class AnnouncementResponses {
  /// Responses that allows the user to react to an [Announcement].
  AnnouncementResponses({
    this.allowMultiple = false,
    this.showOther = false,
    required this.responses,
  });

  /// Whether selecting multiple responses is allowed.
  @JsonKey(name: "allow_multiple")
  final bool allowMultiple;

  /// Whether to show an 'other' option where the user can input their own value.
  @JsonKey(name: "show_other")
  final bool showOther;

  /// Pre-made responses the user can pick from.
  final List<String> responses;

  static AnnouncementResponses fromJson(Json json) =>
      _$AnnouncementResponsesFromJson(json);

  Json toJson() => _$AnnouncementResponsesToJson(this);

  @override
  String toString() => toJson().toString();
}
