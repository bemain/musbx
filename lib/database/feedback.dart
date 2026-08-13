import 'package:json_annotation/json_annotation.dart';
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
  });

  /// The content of this feedback entry.
  final String? content;

  static FeedbackEntry fromJson(Json json) => _$FeedbackEntryFromJson(json);

  @override
  Json toJson() => _$FeedbackEntryToJson(this);

  @override
  String toString() => "Feedback($id)";
}
