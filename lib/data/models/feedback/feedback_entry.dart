import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/data/models/supabase_model.dart';
import 'package:musbx/utils/utils.dart';

part 'feedback_entry.g.dart';

@JsonSerializable()
class FeedbackEntry extends SupabaseModel {
  /// A feedback entry from a user.
  FeedbackEntry({
    super.id,
    super.createdAt,
    required this.content,
    required this.sentBy,
    this.responseTo,
  });

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
  String toString() => "FeedbackEntry($id)";
}
