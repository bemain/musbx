import 'package:meta/meta.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/utils/result.dart';

/// What the user has told us, whether unprompted or in answer to a poll.
abstract class FeedbackRepository {
  @useResult
  Future<Result<void>> insert(FeedbackEntry value);
}
