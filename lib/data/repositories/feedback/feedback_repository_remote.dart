import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/repositories/feedback/feedback_repository.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

class FeedbackRepositoryRemote extends FeedbackRepository {
  FeedbackRepositoryRemote({required SupabaseService supabaseService})
    : _supabaseService = supabaseService;

  final SupabaseService _supabaseService;

  @override
  Future<Result<void>> insert(FeedbackEntry value) async {
    return OptionalService.guard(
      () => _supabaseService.insertFeedback(value),
      "Supabase service disabled",
    );
  }
}
