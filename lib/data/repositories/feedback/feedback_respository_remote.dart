import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/repositories/feedback/feedback_respository.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

class FeedbackRespositoryRemote extends FeedbackRespository {
  FeedbackRespositoryRemote({required SupabaseService supabaseService})
    : _supabaseService = supabaseService;

  final SupabaseService _supabaseService;

  @override
  Future<Result<void>> insert(FeedbackEntry value) async {
    try {
      return Result.ok(await _supabaseService.insertFeedback(value));
    } on ServiceDisabled catch (_) {
      return Result.unavailable("Supabase service disabled");
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
