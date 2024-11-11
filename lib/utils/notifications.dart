import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/utils/persistent_value.dart';

class Notifications {
  /// Whether the notification plugin has been initialized by running [initialize].
  static bool isInitialized = false;

  /// Used internally to show notifications.
  static final AwesomeNotifications _notifications = AwesomeNotifications();

  /// Whether the user has given the app permission to show notifications
  static bool get hasPermission => hasPermissionNotifier.value;
  static final ValueNotifier<bool> hasPermissionNotifier = ValueNotifier(false);

  /// Whether permission to show notifications has been requested at least once.
  ///
  /// We don't want to be too intrusive, so notification permission is only
  /// requested when the user presses the play button for the first time ever.
  static PersistentValue<bool> hasRequestedPermission = PersistentValue(
    "metronome/hasRequestedPermission",
    initialValue: false,
  );

  /// Callback for when the user taps an action on the notification while the app is the background.
  @pragma("vm:entry-point")
  static Future<void> _onActionReceived(ReceivedAction action) async {
    if (action.channelKey == "metronome-controls") {
      switch (action.buttonKeyPressed) {
        case "play":
          Metronome.instance.play();
          break;
        case "pause":
          Metronome.instance.pause();
          break;
      }
    }
  }

  /// Initialize the notifications service.
  static Future<void> initialize() async {
    if (isInitialized) return;

    // Check permission
    final allowedPermissions = await _notifications.checkPermissionList();
    hasPermissionNotifier.value = allowedPermissions.isNotEmpty;

    // Initialize AwesomeNotifications
    await _notifications.initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelGroupKey: "metronome-group",
          channelKey: "metronome-controls",
          channelName: "Quick Access",
          channelDescription:
              "Control the Metronome directly from your notifications drawer",
          channelShowBadge: false,
          importance: NotificationImportance.Default,
          locked: true,
          enableLights: false,
          enableVibration: false,
          playSound: false,
          onlyAlertOnce: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: "metronome-group",
          channelGroupName: "Metronome",
        ),
      ],
      debug: true,
    );

    await _notifications.setListeners(
      onActionReceivedMethod: _onActionReceived,
    );

    isInitialized = true;
  }

  /// Request permission to show notifications, if it has not been given already.
  static Future<bool> requestPermission() async {
    if (!isInitialized) {
      throw "The `Notifications` service hasn't been initialized. Call `initialize()` first.";
    }

    hasRequestedPermission.value = true;

    hasPermissionNotifier.value = await _notifications.isNotificationAllowed();
    if (!hasPermission) {
      await _notifications.requestPermissionToSendNotifications();
      final allowedPermissions = await _notifications.checkPermissionList();
      hasPermissionNotifier.value = allowedPermissions.isNotEmpty;
    }
    return hasPermission;
  }

  static Future<bool> shouldShowRationale() async {
    if (!isInitialized) {
      throw "The `Notifications` service hasn't been initialized. Call `initialize()` first.";
    }

    final lockedPermissions =
        await _notifications.shouldShowRationaleToRequest();
    return lockedPermissions.isNotEmpty;
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    if (!isInitialized) {
      throw "The `Notifications` service hasn't been initialized. Call `initialize()` first.";
    }
    await _notifications.cancelAll();
  }

  static Future<void> create({
    required NotificationContent content,
    List<NotificationActionButton>? actionButtons,
  }) async {
    if (!isInitialized) {
      throw "The `Notifications` service hasn't been initialized. Call `initialize()` first.";
    }
    if (!hasPermission) return;

    await _notifications.createNotification(
      content: content,
      actionButtons: actionButtons,
    );
  }
}
