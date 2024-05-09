import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';

class Notifications {
  /// Whether the notification plugin has been initialized by running [initialize].
  static bool isInitialized = false;

  /// Whether the user has given the app permission to show notifications
  static bool hasPermission = false;

  /// Used internally to show notifications.
  static final AwesomeNotifications _notifications = AwesomeNotifications();

  /// Callback for when the user taps an action on the notification while the app is the background
  @pragma("vm:entry-point")
  static Future<void> _onActionReceived(
    ReceivedAction action,
  ) async {
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

    await _notifications.initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelGroupKey: "metronome-group",
          channelKey: "metronome-controls",
          channelName: "Quick Access",
          channelDescription:
              "Control the Metronome directly from your notifications drawer",
          importance: NotificationImportance.Default,
          enableLights: false,
          enableVibration: false,
          playSound: false,
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

    final allowedPermissions = await _notifications.checkPermissionList();
    hasPermission = allowedPermissions.isNotEmpty;

    isInitialized = true;
  }

  /// Request permission to show notifications, if it has not been given already.
  static Future<bool> requestPermission() async {
    hasPermission = await _notifications.isNotificationAllowed();

    if (!hasPermission) {
      await _notifications.requestPermissionToSendNotifications();
      final allowedPermissions = await _notifications.checkPermissionList();
      hasPermission = allowedPermissions.isNotEmpty;
    }
    return hasPermission;
  }

  static Future<bool> shouldShowRationale() async {
    if (!isInitialized) {
      throw "The `Notifications` plugin hasn't been initialized. Call `initialize()` first.";
    }

    final lockedPermissions =
        await _notifications.shouldShowRationaleToRequest();
    return lockedPermissions.isNotEmpty;
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static Future<void> createMetronomeQuickAccess() async {
    if (!isInitialized || !hasPermission) return;

    final bool isPlaying = Metronome.instance.isPlaying;
    await _notifications.createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: "metronome-controls",
        title: 'Metronome',
        summary: isPlaying ? "Playing" : "Paused",
        body:
            "${Metronome.instance.higher} beats • ${Metronome.instance.bpm} bpm",
        color: Colors.transparent,
        category: NotificationCategory.Service,
        actionType: ActionType.KeepOnTop,
        notificationLayout: NotificationLayout.Default,
        showWhen: false,
        autoDismissible: false,
        locked: true,
      ),
      actionButtons: [
        if (!isPlaying)
          NotificationActionButton(
            key: "play",
            label: "Play",
            actionType: ActionType.KeepOnTop,
            autoDismissible: false,
            showInCompactView: true,
          ),
        if (isPlaying)
          NotificationActionButton(
            key: "pause",
            label: "Pause",
            actionType: ActionType.KeepOnTop,
            autoDismissible: false,
            showInCompactView: true,
          ),
      ],
    );
  }
}

class NotificationPermissionRationale extends StatelessWidget {
  const NotificationPermissionRationale({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enable notifications"),
      icon: const Icon(Icons.notifications_active),
      content: const Text(
          "Turn on notifications to quickly access the Metronome from the notifications drawer."),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text("Deny")),
        FilledButton(
            onPressed: () {
              Notifications.requestPermission();
              Navigator.of(context).pop(true);
            },
            child: const Text("Allow")),
      ],
    );
  }
}
