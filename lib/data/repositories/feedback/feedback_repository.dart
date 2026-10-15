import 'package:meta/meta.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/utils/result.dart';

/// What the user has told us, whether unprompted or in answer to a poll.
abstract class FeedbackRepository {
  @useResult
  Future<Result<void>> insert(String content);

  Future<Result<void>> respond(Announcement announcement, String response);

  List<String> responses(Announcement announcement);
}
