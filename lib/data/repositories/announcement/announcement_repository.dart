import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/utils/result.dart';

/// The announcements shown to the user, and what they have read.
abstract class AnnouncementRepository extends ChangeNotifier {
  /// The most recently published announcement.
  @useResult
  Future<Result<Announcement>> getLatest();

  /// Every announcement ever published, newest first.
  @useResult
  Future<Result<List<Announcement>>> getAll();

  /// The announcements published after [readAt].
  @useResult
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
