import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/database/database.dart';
import 'package:musbx/database/model.dart';
import 'package:musbx/utils/utils.dart';

part 'feedback.g.dart';

@JsonSerializable()
class FeedbackEntry extends Model {
  /// A feedback entry from a user.
  FeedbackEntry({
    super.id,
    super.createdAt,
    required this.content,
    String? sentBy,
    this.responseTo,
  }) : sentBy = sentBy ?? Database.client.auth.currentUser?.id;

  /// The content of this feedback entry.
  final String? content;

  /// The id of the user that sent this feedback.
  @JsonKey(name: "sent_by")
  final String? sentBy;

  /// The [Announcement] that this is a response to.
  @JsonKey(name: "response_to")
  final String? responseTo;

  static FeedbackEntry fromJson(Json json) => _$FeedbackEntryFromJson(json);

  @override
  Json toJson() => _$FeedbackEntryToJson(this);

  @override
  String toString() => "Feedback($id)";
}
