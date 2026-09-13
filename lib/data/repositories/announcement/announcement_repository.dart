import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/utils/result.dart';

/// The announcements shown to the user, and what they have read.
abstract class AnnouncementRepository extends ChangeNotifier {
  @useResult
  Future<Result<Announcement>> getLatest();

  @useResult
  Future<Result<List<Announcement>>> getAll();

  @useResult
  Future<Result<List<Announcement>>> getUnread();

  DateTime get readAt;

  void markRead([DateTime? readAt]);
}
