import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/repositories/announcements/announcements_repository_remote.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

/// The announcements shown to the user, and what they have read.
abstract class AnnouncementsRepository extends ChangeNotifier {
  // TODO: Remove once we introduce `provider`.
  static final AnnouncementsRepository instance =
      AnnouncementsRepositoryRemote(
        sharedPreferences: SharedPreferencesService.instance,
        supabaseService: SupabaseService.instance,
      );

  @useResult
  Future<Result<Announcement>> getLatest();

  @useResult
  Future<Result<List<Announcement>>> getAll();

  @useResult
  Future<Result<List<Announcement>>> getUnread();

  DateTime get readAt;

  void markRead([DateTime? readAt]);
}
