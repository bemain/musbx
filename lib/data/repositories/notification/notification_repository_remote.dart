import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/repositories/notification/notification_repository.dart';
import 'package:musbx/data/services/notification_service.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/notification.dart';
import 'package:musbx/domain/models/permission.dart';
import 'package:musbx/utils/result.dart';

/// Thrown when a notification is posted without the user having allowed them.
final class PermissionException implements Exception {
  @override
  String toString() => "Notification permission has not been given!";
}

@pragma("vm:entry-point")
/// Posts notifications through [NotificationService], refusing to while the
/// user has not given permission, and remembers whether permission has been
/// asked for.
class NotificationRepositoryRemote extends NotificationRepository {
  NotificationRepositoryRemote({
    required SharedPreferencesService sharedPreferences,
    required ServiceLoader<NotificationService> notifications,
    required PermissionService permissionService,
  }) : _sharedPreferences = sharedPreferences,
       _notifications = notifications,
       _permissionService = permissionService {
    unawaited(_checkPermissionStatus());
  }

  final SharedPreferencesService _sharedPreferences;

  /// Read at call time, so a service created after this repository is used.
  final ServiceLoader<NotificationService> _notifications;
  final PermissionService _permissionService;

  @override
  final ValueNotifier<bool> hasPermissionNotifier = ValueNotifier(false);

  late final PersistentValue<bool> _hasRequestedPermission = _sharedPreferences
      .value(
        "metronome/hasRequestedPermission",
        initialValue: false,
      );
  @override
  bool get hasRequestedPermission => _hasRequestedPermission.value;
  @override
  set hasRequestedPermission(bool value) =>
      _hasRequestedPermission.value = value;

  @override
  Future<Result<bool>> requestPermission() async {
    hasRequestedPermission = true;

    if (hasPermission) return Result.ok(true);

    return OptionalService.guard(
      () async {
        final status = await _permissionService.request(
          Permission.notifications,
        );

        hasPermissionNotifier.value =
            status == PermissionStatus.granted ||
            status == PermissionStatus.unavailable;
        return hasPermission;
      },
      "Notification service disabled",
    );
  }

  Future<void> _checkPermissionStatus() async {
    final status = await _permissionService.status(
      Permission.notifications,
    );
    hasPermissionNotifier.value =
        status == PermissionStatus.granted ||
        status == PermissionStatus.unavailable;
  }

  @override
  Future<Result<void>> post(AppNotification notification) async {
    if (!hasPermission) return Result.failed(PermissionException());

    return OptionalService.guard(
      () async => (await _notifications.ready).post(notification),
      "Notification service disabled",
    );
  }

  @override
  Future<Result<void>> cancel(NotificationChannel channel) async {
    return OptionalService.guard(
      () async => (await _notifications.ready).cancel(channel),
      "Notification service disabled",
    );
  }

  @override
  Future<Result<void>> cancelAll() async {
    return OptionalService.guard(
      () async => (await _notifications.ready).cancelAll(),
      "Notification service disabled",
    );
  }

  @override
  Stream<NotificationActionTapped> get actions =>
      _notifications.value.actionStream;
}
