import 'package:musbx/config/service_loader.dart';
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
    required ServiceLoader<SupabaseService> supabase,
  }) : _sharedPreferences = sharedPreferences,
       _supabase = supabase;

  final SharedPreferencesService _sharedPreferences;

  /// Read at call time, so a service created after this repository is used.
  final ServiceLoader<SupabaseService> _supabase;

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
      () => _supabase.value.getLatestAnnouncement(),
      "Supabase service disabled",
    );
  }

  @override
  Future<Result<List<Announcement>>> getAll() async {
    return OptionalService.guard(
      () => _supabase.value.getAnnouncements(),
      "Supabase service disabled",
    );
  }

  /// Reads [readAt] as it stands when called, so this has to be run again to
  /// pick up a change rather than being awaited once.
  @override
  Future<Result<List<Announcement>>> getUnread() async {
    return OptionalService.guard(
      () => _supabase.value.getAnnouncementsAfter(_readAtNotifier.value),
      "Supabase service disabled",
    );
  }
}
