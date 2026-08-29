import 'package:flutter/foundation.dart';
import 'package:musbx/data/repositories/notification/notification_repository_remote.dart';
import 'package:musbx/data/services/notification_service.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/notification.dart';
import 'package:musbx/utils/result.dart';

abstract class NotificationRepository {
  // TODO: Remove once we introduce `provider`.
  static final NotificationRepository instance = NotificationRepositoryRemote(
    sharedPreferences: SharedPreferencesService.instance,
    notificationService: NotificationService.instance,
    permissionService: PermissionService.instance,
  );

  /// Whether the user has given the app permission to show notifications
  bool get hasPermission => hasPermissionNotifier.value;
  ValueNotifier<bool> get hasPermissionNotifier;

  /// Whether permission to show notifications has been requested at least once.
  ///
  /// We don't want to be too intrusive, so notification permission is only
  /// requested when the user presses the play button for the first time ever.
  bool get hasRequestedPermission;
  set hasRequestedPermission(bool value);

  /// Request permission to show notifications, if it has not been given already.
  Future<Result<bool>> requestPermission();

  Future<Result<void>> post(AppNotification notification);

  /// Cancel all notifications
  Future<Result<void>> cancelAll();
}
