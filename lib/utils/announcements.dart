import 'package:musbx/database/announcement.dart';
import 'package:musbx/database/database.dart';
import 'package:musbx/utils/launch_handler.dart';

class Announcements {
  Announcements._();

  /// Get the latest announcement from the database.
  static Future<Announcement> getLatest() async {
    return await Database.announcements
        .select()
        .order('created_at')
        .limit(1)
        .single()
        .withConverter(Announcement.fromJson);
  }

  /// Get all announcements from the database.
  static Future<List<Announcement>> getAll() async {
    return await Database.announcements.select().withConverter(
      (data) => data.map(Announcement.fromJson).toList(),
    );
  }

  /// Get all announcements from the database that have not been seen before.
  static Future<List<Announcement>> getUnread() async {
    return await Database.announcements
        .select()
        .gt("created_at", LaunchHandler.previousLaunchAt.toIso8601String())
        .withConverter(
          (data) => data.map(Announcement.fromJson).toList(),
        );
  }
}
