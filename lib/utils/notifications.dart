import 'package:flutter/foundation.dart';
import 'package:musbx/data/services/notification_service.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/permission.dart';
import 'package:musbx/domain/notification.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/navigation.dart';

@pragma("vm:entry-point")
class Notifications {
  /// Whether the notification plugin has been initialized by running [initialize].
  static bool isInitialized = false;

  /// Whether the user has given the app permission to show notifications
  static bool get hasPermission => hasPermissionNotifier.value;
  static final ValueNotifier<bool> hasPermissionNotifier = ValueNotifier(
    false,
  );

  /// Whether permission to show notifications has been requested at least once.
  ///
  /// We don't want to be too intrusive, so notification permission is only
  /// requested when the user presses the play button for the first time ever.
  static PersistentValue<bool> hasRequestedPermission =
      SharedPreferencesService.instance.value(
        "metronome/hasRequestedPermission",
        initialValue: false,
      );

  /// Initialize the notifications service.
  static Future<void> initialize() async {
    if (isInitialized) return;

    NotificationService.instance.actionStream.listen(_onActionReceived);

    await _checkPermissionStatus();

    isInitialized = true;
  }

  /// Request permission to show notifications, if it has not been given already.
  static Future<bool> requestPermission() async {
    if (!isInitialized) {
      throw "The `Notifications` service hasn't been initialized. Call `initialize()` first.";
    }

    hasRequestedPermission.value = true;

    if (!hasPermission) {
      await _checkPermissionStatus();
    }
    return hasPermission;
  }

  static Future<void> _checkPermissionStatus() async {
    final status = await PermissionService.instance.status(
      Permission.notifications,
    );
    hasPermissionNotifier.value =
        status == PermissionStatus.granted ||
        status == PermissionStatus.unavailable;
  }

  static Future<void> post(AppNotification notification) async {
    if (!isInitialized) {
      throw "The `Notifications` service hasn't been initialized. Call `initialize()` first.";
    }
    if (!hasPermission) return;

    await NotificationService.instance.post(notification);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    if (!isInitialized) {
      throw "The `Notifications` service hasn't been initialized. Call `initialize()` first.";
    }
    await NotificationService.instance.cancelAll();
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
