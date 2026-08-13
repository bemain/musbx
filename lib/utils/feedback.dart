import 'package:musbx/database/database.dart';
import 'package:musbx/database/feedback.dart';

class UserFeedback {
  UserFeedback._();

  /// Insert a feedback entry in the database.
  static Future<void> insert(FeedbackEntry value) async {
    await Database.feedback.insert(value.toJson());
  }
}
