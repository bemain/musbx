import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/utils/result.dart';

/// The announcements shown to the user, and what they have read.
abstract class AnnouncementRepository extends ChangeNotifier {
  @useResult
  /// The most recently published announcement.
  Future<Result<Announcement>> getLatest();

  @useResult
  /// Every announcement ever published, newest first.
  Future<Result<List<Announcement>>> getAll();

  @useResult
  /// The announcements published after [readAt].
  Future<Result<List<Announcement>>> getUnread();

  /// When the user last read the announcements.
  ///
  /// Everything published after this is unread. It defaults to the moment it is
  /// first read, so a fresh install starts with nothing unread rather than with
  /// the entire history.
  DateTime get readAt;

  /// Move [readAt] forward, dismissing everything published before it.
  void markRead([DateTime? readAt]);
}
