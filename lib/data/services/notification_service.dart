import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart' as plugin;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/notification.dart';

/// Shows notifications, and reports what the user does with them.
///
/// Notifications are optional. [disabled] returns a service that shows nothing,
/// for platforms where the system has no notifications to show.
///
/// Every [NotificationChannel] is registered with the operating system when the
/// service starts, since the system owns them from then on and lets the user
/// configure each one separately.
@pragma("vm:entry-point")
class NotificationService extends OptionalService {
  NotificationService._(this._notifications);

  @override
  bool get isEnabled => _notifications != null;

  /// The plugin handle, or `null` when this service is [disabled].
  final plugin.AwesomeNotifications? _notifications;

  /// Create the service, registering every [NotificationChannel] with the
  /// operating system.
  ///
  /// Returns a [disabled] service on platforms without notifications. Throws if
  /// the plugin cannot be initialized; since notifications are optional,
  /// callers should fall back to [disabled] rather than propagate that.
  static Future<NotificationService> create({
    plugin.AwesomeNotifications? notifications,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return disabled();

    final n = notifications ?? plugin.AwesomeNotifications();

    await n.initialize(
      'resource://drawable/ic_notification',
      [
        plugin.NotificationChannel(
          channelGroupKey: "metronome-group",
          channelKey: _keyOf(NotificationChannel.metronomeControls),
          channelName: "Quick Access",
          channelDescription:
              "Control the Metronome directly from your notifications drawer",
          channelShowBadge: false,
          importance: plugin.NotificationImportance.Default,
          locked: true,
          enableLights: false,
          enableVibration: false,
          playSound: false,
          onlyAlertOnce: true,
        ),
      ],
      channelGroups: [
        plugin.NotificationChannelGroup(
          channelGroupKey: "metronome-group",
          channelGroupName: "Metronome",
        ),
      ],
      debug: kDebugMode,
    );

    await n.setListeners(
      onActionReceivedMethod: _onActionReceived,
    );

    return NotificationService._(n);
  }

  /// A service that shows nothing, for platforms without notifications.
  static NotificationService disabled() => NotificationService._(null);

  // TODO: Remove once we introduce `provider`.
  static late final NotificationService instance;
  static Future<void> initialize() async {
    try {
      instance = await create();
    } catch (error) {
      debugPrint("[NOTIFICATIONS] Disabled, initialization failed: $error");
      instance = disabled();
    }
  }

  /// Show [notification], replacing whatever is showing on its channel.
  ///
  /// Each channel carries a single notification, so calling this again with
  /// updated content is how a long-lived notification is kept in step with the
  /// app: the system replaces it in place instead of alerting the user again.
  ///
  /// Does nothing when this service is [disabled].
  Future<void> post(AppNotification notification) async {
    await _notifications?.createNotification(
      content: plugin.NotificationContent(
        id: idOf(notification.channel),
        channelKey: _keyOf(notification.channel),
        title: notification.title,
        summary: notification.summary,
        body: notification.body,
        color: Colors.transparent,
        category: plugin.NotificationCategory.Transport,
        actionType: plugin.ActionType.Default,
        notificationLayout: plugin.NotificationLayout.Default,
        showWhen: false,
        autoDismissible: false,
        displayOnForeground: Platform.isIOS ? false : true,
      ),
      actionButtons: [
        for (final action in notification.actions)
          plugin.NotificationActionButton(
            key: action.key,
            label: action.label,
            actionType: plugin.ActionType.KeepOnTop,
            autoDismissible: false,
            showInCompactView: true,
          ),
      ],
    );
  }

  /// Remove the notification showing on [channel], leaving other channels alone.
  ///
  /// Does nothing when this service is [disabled], or when the channel has no
  /// notification showing.
  Future<void> cancel(NotificationChannel channel) async {
    await _notifications?.cancel(idOf(channel));
  }

  /// Remove every notification this app is showing.
  Future<void> cancelAll() async {
    await _notifications?.cancelAll();
  }

  /// Actions received from the operating system.
  ///
  /// Static because [_onActionReceived] has to be, and never closed, because
  /// the system can deliver an action at any point in the process's life.
  static final _actionController =
      StreamController<NotificationActionTapped>.broadcast();

  /// What the user has done with a notification.
  ///
  /// Tapping a button emits that button's key; tapping the body of the
  /// notification emits an empty key, so listeners that only care about buttons
  /// have to skip it.
  ///
  /// Only actions that arrive while the app is running are emitted. Once the
  /// app has been terminated the plugin runs the handler in a separate isolate,
  /// which does not share this one's static state, so those actions reach no
  /// listener here.
  Stream<NotificationActionTapped> get actionStream =>
      _actionController.stream;

  /// Receives the user's notification taps from the operating system.
  ///
  /// Has to be static and annotated `vm:entry-point`: the plugin resolves this
  /// function by callback handle so it can be invoked from an isolate that has
  /// no instance to bind to, and rejects anything that is not a global or
  /// static method.
  ///
  /// Actions on channels this app does not recognize are dropped.
  @pragma("vm:entry-point")
  static Future<void> _onActionReceived(plugin.ReceivedAction action) async {
    final channel = action.channelKey == null
        ? null
        : _channelOf(action.channelKey!);
    if (channel == null) return;

    _actionController.add(
      NotificationActionTapped(
        channel: channel,
        key: action.buttonKeyPressed,
      ),
    );
  }

  /// The key the operating system stores [channel] under.
  ///
  /// The system persists channels by key and lets the user configure them
  /// there, so a key must never change once released: a new key registers a
  /// second channel and abandons whatever the user configured on the old one,
  /// which the app has no way to delete.
  static String _keyOf(NotificationChannel channel) => switch (channel) {
    NotificationChannel.metronomeControls => "metronome-controls",
  };

  /// The id of the one notification [channel] shows.
  ///
  /// Reusing an id is what replaces a notification in place rather than adding
  /// a second one. Like the channel key, an id must not change once released:
  /// notifications outlive an app update, so a new id strands the old
  /// notification on screen with nothing left able to address it.
  static int idOf(NotificationChannel channel) => switch (channel) {
    NotificationChannel.metronomeControls => 0,
  };

  /// The channel stored under [key], or `null` if this app has no such channel.
  ///
  /// Derived from [_keyOf] so the two directions cannot disagree.
  static NotificationChannel? _channelOf(String key) => NotificationChannel
      .values
      .where((channel) => _keyOf(channel) == key)
      .firstOrNull;
}
