import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/repositories/feedback/feedback_repository.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

/// Writes feedback to Supabase.
class FeedbackRepositoryRemote extends FeedbackRepository {
  FeedbackRepositoryRemote({required ServiceLoader<SupabaseService> supabase})
    : _supabase = supabase;

  /// Read at call time, so a service created after this repository is used.
  final ServiceLoader<SupabaseService> _supabase;

  @override
  Future<Result<void>> insert(FeedbackEntry value) async {
    return OptionalService.guard(
      () => _supabase.value.insertFeedback(value),
      "Supabase service disabled",
    );
  }
}
