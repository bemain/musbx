import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/repositories/announcement/announcement_repository.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

class AnnouncementRepositoryRemote extends AnnouncementRepository {
  AnnouncementRepositoryRemote({
    required SharedPreferencesService sharedPreferences,
    required SupabaseService supabaseService,
  }) : _sharedPreferences = sharedPreferences,
       _supabaseService = supabaseService;

  final SharedPreferencesService _sharedPreferences;

  final SupabaseService _supabaseService;

  /// The last time the announcements were read.
  ///
  /// Everything written after this is unread, so moving it forward is how
  /// announcements are dismissed. It defaults to the moment it is first read,
  /// which means a fresh install starts with nothing unread rather than with
  /// the entire history.
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
    try {
      return Result.ok(await _supabaseService.getLatestAnnouncement());
    } on ServiceDisabled catch (_) {
      return Result.unavailable("Supabase service disabled");
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  @override
  Future<Result<List<Announcement>>> getAll() async {
    try {
      return Result.ok(await _supabaseService.getAnnouncements());
    } on ServiceDisabled catch (_) {
      return Result.unavailable("Supabase service disabled");
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  /// Get all announcements from the database that have not been seen before.
  ///
  /// Reads [_readAtNotifier] as it stands when called, so this has to be run again to
  /// pick up a change rather than being awaited once.
  @override
  Future<Result<List<Announcement>>> getUnread() async {
    try {
      return Result.ok(
        await _supabaseService.getAnnouncementsAfter(_readAtNotifier.value),
      );
    } on ServiceDisabled catch (_) {
      return Result.unavailable("Supabase service disabled");
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }
}
