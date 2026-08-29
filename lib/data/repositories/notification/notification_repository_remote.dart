import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musbx/data/repositories/notification/notification_repository.dart';
import 'package:musbx/data/services/notification_service.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/notification.dart';
import 'package:musbx/domain/models/permission.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/utils/result.dart';

final class PermissionException implements Exception {
  @override
  String toString() => "Notification permission has not been given!";
}

@pragma("vm:entry-point")
class NotificationRepositoryRemote extends NotificationRepository {
  NotificationRepositoryRemote({
    required SharedPreferencesService sharedPreferences,
    required NotificationService notificationService,
    required PermissionService permissionService,
  }) : _sharedPreferences = sharedPreferences,
       _notificationService = notificationService,
       _permissionService = permissionService {
    _notificationService.actionStream.listen(_onActionReceived);

    unawaited(_checkPermissionStatus());
  }

  final SharedPreferencesService _sharedPreferences;
  final NotificationService _notificationService;
  final PermissionService _permissionService;

  @override
  final ValueNotifier<bool> hasPermissionNotifier = ValueNotifier(
    false,
  );

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

    try {
      final status = await _permissionService.request(
        Permission.notifications,
      );

      hasPermissionNotifier.value =
          status == PermissionStatus.granted ||
          status == PermissionStatus.unavailable;
      return Result.ok(hasPermission);
    } on ServiceDisabled catch (_) {
      return Result.unavailable("Notification service disabled");
    } catch (e, s) {
      return Result.failed(e, s);
    }
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

    try {
      await _notificationService.post(notification);
      return Result.ok(null);
    } on ServiceDisabled catch (_) {
      return Result.unavailable("Notification service disabled");
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  @override
  Future<Result<void>> cancelAll() async {
    try {
      await _notificationService.cancelAll();
      return Result.ok(null);
    } on ServiceDisabled catch (_) {
      return Result.unavailable("Notification service disabled");
    } catch (e, s) {
      return Result.failed(e, s);
    }
  }

  /// Callback for when the user taps an action on the notification while the app is the background.
  static Future<void> _onActionReceived(
    NotificationActionTapped action,
  ) async {
    if (action.channel == NotificationChannel.metronomeControls) {
      // Navigate to the metronome page
      Navigation.navigationShell.goBranch(
        Routes.branches.indexOf(Routes.metronome),
      );

      switch (action.key) {
        case "play":
          Metronome.instance.resume();
        case "pause":
          Metronome.instance.pause();
      }
    }
  }
}
