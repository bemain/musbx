import 'package:material_plus/material_plus.dart';
import 'package:musbx/database/announcement.dart';
import 'package:musbx/database/database.dart';

class Announcements {
  Announcements._();

  /// The last time the announcements were read.
  static final TransformedPersistentValue<DateTime, String> readAt =
      TransformedPersistentValue(
        "announcements/readAt",
        initialValue: DateTime.now(),
        from: (value) => DateTime.parse(value),
        to: (value) => value.toIso8601String(),
      );

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
    return await Database.announcements
        .select()
        .order('created_at')
        .withConverter(
          (data) => data.map(Announcement.fromJson).toList(),
        );
  }

  /// Get all announcements from the database that have not been seen before.
  static Future<List<Announcement>> getUnread() async {
    return await Database.announcements
        .select()
        .gt("created_at", readAt.value.toIso8601String())
        .order('created_at')
        .withConverter(
          (data) => data.map(Announcement.fromJson).toList(),
        );
  }
}
