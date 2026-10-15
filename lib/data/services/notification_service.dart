import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/notification.dart';

/// Shows notifications, and reports what the user does with them.
///
/// Notifications are optional. [disabled] returns a service with nothing behind
/// it, for platforms where the system has no notifications to show.
///
/// Every [NotificationChannel] is registered with the operating system when the
/// service starts, since the system owns them from then on and lets the user
/// configure each one separately.
@pragma("vm:entry-point")
class NotificationService extends OptionalService {
  NotificationService._(this.__notifications);

  /// The plugin handle, or `null` when this service is [disabled].
  final FlutterLocalNotificationsPlugin? __notifications;

  FlutterLocalNotificationsPlugin get _notifications {
    throwIfDisabled();
    return __notifications!;
  }

  @override
  bool get isEnabled => __notifications != null;

  /// Create the service, registering every [NotificationChannel] with the
  /// operating system.
  ///
  /// Returns a [disabled] service on platforms without notifications. Throws if
  /// the plugin cannot be initialized; since notifications are optional,
  /// callers should fall back to [disabled] rather than propagate that.
  static Future<NotificationService> create({
    FlutterLocalNotificationsPlugin? notifications,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return disabled();

    final n = notifications ?? FlutterLocalNotificationsPlugin();

    await n.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings("ic_notification"),
        // Permission is requested on the first press of play, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
          notificationCategories: [
            for (final set in NotificationActionSet.values)
              _darwinCategoryOf(set),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onResponse,
    );

    await _registerAndroidChannels(n);
    _listenForResponses();

    return NotificationService._(n);
  }

  static const _metronomeGroup = AndroidNotificationChannelGroup(
    "metronome-group",
    "Metronome",
  );

  /// Register every [NotificationChannel] with Android.
  ///
  /// Android ignores the settings of a channel that already exists, so changing
  /// anything here only reaches new installs.
  static Future<void> _registerAndroidChannels(
    FlutterLocalNotificationsPlugin n,
  ) async {
    final android = n
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannelGroup(_metronomeGroup);
    for (final channel in NotificationChannel.values) {
      await android.createNotificationChannel(_androidChannelOf(channel));
    }
  }

  /// How [channel] is registered with Android.
  ///
  /// Every notification restates its channel, so both registration and [post]
  /// read it from here.
  static AndroidNotificationChannel _androidChannelOf(
    NotificationChannel channel,
  ) => switch (channel) {
    NotificationChannel.metronomeControls => AndroidNotificationChannel(
      _keyOf(channel),
      "Quick Access",
      description:
          "Control the Metronome directly from your notifications drawer",
      groupId: _metronomeGroup.id,
      showBadge: false,
      enableLights: false,
      enableVibration: false,
      playSound: false,
    ),
  };

  /// How [set] is registered with iOS, which shows a notification's buttons
  /// from the category it names rather than from the notification itself.
  ///
  /// iOS replaces every category each time the app starts, so unlike channel
  /// keys the identifiers are free to change between releases.
  static DarwinNotificationCategory _darwinCategoryOf(
    NotificationActionSet set,
  ) => DarwinNotificationCategory(
    set.name,
    actions: [
      for (final action in set.actions)
        DarwinNotificationAction.plain(action.name, action.label),
    ],
  );

  /// A service with nothing behind it, for platforms without notifications.
  static NotificationService disabled() => NotificationService._(null);

  /// Show [notification], replacing whatever is showing on its channel.
  ///
  /// Each channel carries a single notification, so calling this again with
  /// updated content is how a long-lived notification is kept in step with the
  /// app: the system replaces it in place instead of alerting the user again.
  ///
  /// On Android, a channel that [_runsForegroundService] starts a foreground
  /// service with its first notification. Android removes that notification
  /// when the user swipes the app away, which no callback in the app can do
  /// reliably. The service can only be started while the app is visible, so the
  /// first notification on such a channel has to be posted from the foreground.
  ///
  /// Throws [ServiceDisabled] when this service is [disabled].
  Future<void> post(AppNotification notification) async {
    final id = idOf(notification.channel);
    final details = _detailsOf(notification);

    final android = _android;
    if (android != null &&
        _runsForegroundService(notification.channel) &&
        _foregroundChannel == null) {
      await android.startForegroundService(
        id: id,
        title: notification.title,
        body: notification.body,
        notificationDetails: details.android,
        // A sticky service is restarted without its notification after the
        // process dies, which the plugin cannot handle.
        startType: AndroidServiceStartType.startNotSticky,
        foregroundServiceTypes: {
          AndroidServiceForegroundType.foregroundServiceTypeMediaPlayback,
        },
      );
      _foregroundChannel = notification.channel;
      return;
    }

    await _notifications.show(
      id: id,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }

  /// Remove the notification showing on [channel], leaving other channels alone,
  /// and stop the foreground service it started, if any.
  ///
  /// Does nothing when the channel has no notification showing.
  ///
  /// Throws [ServiceDisabled] when this service is [disabled].
  Future<void> cancel(NotificationChannel channel) async {
    if (channel == _foregroundChannel) await _stopForegroundService();
    await _notifications.cancel(id: idOf(channel));
  }

  /// Remove every notification this app is showing, and stop the foreground
  /// service, if any.
  ///
  /// Throws [ServiceDisabled] when this service is [disabled].
  Future<void> cancelAll() async {
    await _stopForegroundService();
    await _notifications.cancelAll();
  }

  /// The channel whose notification the foreground service is showing, or
  /// `null` when it is not running.
  ///
  /// Android runs at most one, since the plugin has a single service.
  NotificationChannel? _foregroundChannel;

  /// The Android side of the plugin, or `null` on other platforms.
  AndroidFlutterLocalNotificationsPlugin? get _android => _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _stopForegroundService() async {
    if (_foregroundChannel == null) return;
    await _android?.stopForegroundService();
    _foregroundChannel = null;
  }

  /// Whether [channel] keeps the app running in the foreground on Android while
  /// its notification is showing.
  static bool _runsForegroundService(NotificationChannel channel) =>
      switch (channel) {
        NotificationChannel.metronomeControls => true,
      };

  /// How [notification] is presented on each platform.
  static NotificationDetails _detailsOf(AppNotification notification) {
    final channel = _androidChannelOf(notification.channel);
    final actions = notification.actionSet?.actions ?? const [];

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        channelShowBadge: channel.showBadge,
        importance: channel.importance,
        playSound: channel.playSound,
        enableVibration: channel.enableVibration,
        enableLights: channel.enableLights,
        subText: notification.summary,
        category: AndroidNotificationCategory.transport,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: false,
        actions: [
          for (final action in actions)
            AndroidNotificationAction(
              action.name,
              action.label,
              cancelNotification: false,
            ),
        ],
      ),
      // Shown only once the app is in the background.
      iOS: DarwinNotificationDetails(
        subtitle: notification.summary,
        categoryIdentifier: notification.actionSet?.name,
        presentAlert: false,
        presentBanner: false,
        presentList: false,
      ),
    );
  }

  /// Actions received from the operating system.
  ///
  /// Static because [_listenForResponses] has to be, and never closed, because
  /// the system can deliver an action at any point in the process's life.
  static final _actionController =
      StreamController<NotificationActionTapped>.broadcast();

  /// What the user has done with a notification.
  ///
  /// Tapping a button emits that button; tapping the body of the notification
  /// emits a `null` action, so listeners that only care about buttons have to
  /// skip it.
  ///
  /// Only actions that arrive while the app is running are emitted. Once the
  /// app has been terminated there is no isolate left to forward them to.
  Stream<NotificationActionTapped> get actionStream =>
      _actionController.stream;

  /// The name the main isolate's response port is registered under.
  static const _responsePortName = "musbx.notification_responses";

  /// Receive the responses [_onResponse] forwards to this isolate.
  ///
  /// Replaces any port left registered by an earlier run of this isolate, such
  /// as before a hot restart, since that one has no listener anymore.
  static void _listenForResponses() {
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(_responsePortName);
    IsolateNameServer.registerPortWithName(port.sendPort, _responsePortName);

    port.listen(_onForwardedResponse);
  }

  /// Emit a response [_onResponse] forwarded, dropping notifications and
  /// buttons this app does not recognize, such as ones a previous version
  /// posted.
  static void _onForwardedResponse(Object? message) {
    if (message case [int id, String? actionId]) {
      final channel = _channelOfId(id);
      if (channel == null) return;

      final action = actionId == null ? null : _actionOf(actionId);
      if (actionId != null && action == null) return;

      _actionController.add(
        NotificationActionTapped(channel: channel, action: action),
      );
    }
  }

  /// The action with [id], or `null` if this app has no such action.
  ///
  /// Every platform identifies a button by [Enum.name], so this is its inverse.
  static NotificationAction? _actionOf(String id) =>
      NotificationAction.values.asNameMap()[id];

  /// Receives the user's notification taps from the operating system, and
  /// forwards them to the main isolate.
  ///
  /// Buttons that leave the app in the background are handled in a separate
  /// isolate that the plugin starts, even while the app is running, so the
  /// response is sent to the port [_listenForResponses] registered rather than
  /// handled here. Only plain values are sent, since the two isolates do not
  /// share a heap.
  ///
  /// Has to be static and annotated `vm:entry-point`: the plugin resolves this
  /// function by callback handle so it can be invoked from an isolate that has
  /// no instance to bind to, and rejects anything that is not a global or
  /// static method.
  @pragma("vm:entry-point")
  static void _onResponse(NotificationResponse response) {
    if (response.id == null) return;

    IsolateNameServer.lookupPortByName(
      _responsePortName,
    )?.send([response.id, response.actionId]);
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
  ///
  /// Never 0, which Android rejects for a foreground service's notification.
  static int idOf(NotificationChannel channel) => switch (channel) {
    NotificationChannel.metronomeControls => 1,
  };

  /// The channel stored under [id], or `null` if this app has no such channel.
  ///
  /// Derived from [idOf] so the two directions cannot disagree.
  static NotificationChannel? _channelOfId(int id) => NotificationChannel
      .values
      .where((channel) => idOf(channel) == id)
      .firstOrNull;
}
