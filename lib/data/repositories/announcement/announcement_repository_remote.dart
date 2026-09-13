import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/repositories/announcement/announcement_repository.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

/// Reads announcements from Supabase, and remembers locally what has been read.
class AnnouncementRepositoryRemote extends AnnouncementRepository {
  AnnouncementRepositoryRemote({
    required SharedPreferencesService sharedPreferences,
    required SupabaseService supabaseService,
  }) : _sharedPreferences = sharedPreferences,
       _supabaseService = supabaseService;

  final SharedPreferencesService _sharedPreferences;

  final SupabaseService _supabaseService;

  late final TransformedPersistentValue<DateTime, String> _readAtNotifier =
      _sharedPreferences.transformed(
        "announcements/readAt",
        initialValue: DateTime.now(),
        from: (value) => DateTime.parse(value),
        to: (value) => value.toIso8601String(),
      );

  @override
  DateTime get readAt => _readAtNotifier.value;

  @override
  void markRead([DateTime? readAt]) {
    _readAtNotifier.value = readAt ?? DateTime.now();
    notifyListeners();
  }

  @override
  Future<Result<Announcement>> getLatest() async {
    return OptionalService.guard(
      _supabaseService.getLatestAnnouncement,
      "Supabase service disabled",
    );
  }

  @override
  Future<Result<List<Announcement>>> getAll() async {
    return OptionalService.guard(
      _supabaseService.getAnnouncements,
      "Supabase service disabled",
    );
  }

  /// Reads [readAt] as it stands when called, so this has to be run again to
  /// pick up a change rather than being awaited once.
  @override
  Future<Result<List<Announcement>>> getUnread() async {
    return OptionalService.guard(
      () async =>
          await _supabaseService.getAnnouncementsAfter(_readAtNotifier.value),
      "Supabase service disabled",
    );
  }
}
