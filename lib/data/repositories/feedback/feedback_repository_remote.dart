import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/repositories/feedback/feedback_repository.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

/// Writes feedback to Supabase.
class FeedbackRepositoryRemote extends FeedbackRepository {
  FeedbackRepositoryRemote({
    required SharedPreferencesService sharedPreferences,
    required ServiceLoader<SupabaseService> supabase,
  }) : _sharedPreferences = sharedPreferences,
       _supabase = supabase;

  /// Read at call time, so a service created after this repository is used.
  final ServiceLoader<SupabaseService> _supabase;
  final SharedPreferencesService _sharedPreferences;

  @override
  Future<Result<void>> insert(String content) async {
    return OptionalService.guard(
      () => _supabase.value.insertFeedback(
        FeedbackEntry(
          content: content,
          sentBy: _supabase.value.currentUser?.id,
        ),
      ),
      "Supabase service disabled",
    );
  }

  PersistentValue<List<String>> _responses(Announcement announcement) =>
      _sharedPreferences.value<List<String>>(
        "announcements/${announcement.id}/responses",
        initialValue: [],
      );

  @override
  Future<Result<void>> respond(Announcement announcement, String response) {
    return OptionalService.guard(
      () {
        _responses(announcement).value = [
          ..._responses(announcement).value,
          response,
        ];

        return _supabase.value.insertFeedback(
          FeedbackEntry(
            content: response,
            responseTo: announcement.id,
            sentBy: _supabase.value.currentUser?.id,
          ),
        );
      },
      "Supabase service disabled",
    );
  }

  @override
  List<String> responses(Announcement announcement) =>
      _responses(announcement).value;
}
