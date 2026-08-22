/// A category of notification, which the user can configure separately.
///
/// The operating system stores these, so adding one takes effect when the app
/// next starts, and removing one leaves the user's settings for it behind.
enum NotificationChannel {
  /// Transport controls for the metronome, shown while it is in use.
  metronomeControls,
}

/// A button the user can tap on a notification.
class NotificationAction {
  const NotificationAction({required this.key, required this.label});

  /// Identifies this action to the app when the user taps it.
  final String key;

  /// The text shown on the button.
  final String label;
}

/// A notification to show the user.
class AppNotification {
  const AppNotification({
    required this.channel,
    required this.title,
    this.summary,
    required this.body,
    this.actions = const [],
  });

  /// The channel to show this on, which decides how the system presents it and
  /// which settings the user controls it with.
  final NotificationChannel channel;

  /// The heading, naming what the notification is about.
  final String title;

  /// A short status shown beside the [title], such as whether something is
  /// currently running.
  final String? summary;

  /// The detail below the [title].
  final String body;

  /// Buttons offered on the notification, in the order they appear.
  final List<NotificationAction> actions;
}

/// Something the user did to a notification.
class NotificationActionTapped {
  const NotificationActionTapped({required this.channel, required this.key});

  /// The channel of the notification that was tapped.
  final NotificationChannel channel;

  /// The [NotificationAction.key] of the button the user tapped, or empty if
  /// they tapped the notification itself rather than a button.
  final String key;
}
