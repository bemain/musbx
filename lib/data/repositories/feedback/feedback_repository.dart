import 'package:meta/meta.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/repositories/feedback/feedback_repository_remote.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

/// What the user has told us, whether unprompted or in answer to a poll.
abstract class FeedbackRepository {
  // TODO: Remove once we introduce `provider`.
  static final FeedbackRepository instance = FeedbackRepositoryRemote(
    supabaseService: SupabaseService.instance,
  );

  @useResult
  Future<Result<void>> insert(FeedbackEntry value);
}
