import 'package:meta/meta.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/repositories/feedback/feedback_respository_remote.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

/// What the user has told us, whether unprompted or in answer to a poll.
abstract class FeedbackRespository {
  // TODO: Remove once we introduce `provider`.
  static final FeedbackRespository instance = FeedbackRespositoryRemote(
    supabaseService: SupabaseService.instance,
  );

  @useResult
  Future<Result<void>> insert(FeedbackEntry value);
}
