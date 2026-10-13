import 'package:flutter/foundation.dart';
import 'package:musbx/domain/models/notification.dart';
import 'package:musbx/utils/result.dart';

/// The notifications the app shows, and the permission needed to show them.
abstract class NotificationRepository {
  /// Whether the user has given the app permission to show notifications.
  bool get hasPermission => hasPermissionNotifier.value;
  ValueNotifier<bool> get hasPermissionNotifier;

  /// Whether permission to show notifications has been requested at least once.
  ///
  /// To avoid being intrusive, permission is only requested unprompted the
  /// first time the user ever starts the metronome.
  bool get hasRequestedPermission;
  set hasRequestedPermission(bool value);

  /// Request permission to show notifications, if it has not been given already.
  Future<Result<bool>> requestPermission();

  /// Show [notification], replacing any earlier one with the same id.
  Future<Result<void>> post(AppNotification notification);

  /// Remove the notification showing on [channel].
  Future<Result<void>> cancel(NotificationChannel channel);

  /// Remove every notification the app is showing.
  Future<Result<void>> cancelAll();

  /// What the user does with the notifications, while the app is running.
  Stream<NotificationActionTapped> get actions;
}
