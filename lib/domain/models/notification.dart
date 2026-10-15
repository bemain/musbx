/// A category of notification, which the user can configure separately.
///
/// The operating system stores these, so adding one takes effect when the app
/// next starts, and removing one leaves the user's settings for it behind.
enum NotificationChannel {
  /// Transport controls for the metronome, shown while it is in use.
  metronomeControls,
}

/// A button the user can tap on a notification.
enum NotificationAction {
  /// Pause whatever the notification is controlling.
  pause("Pause");

  const NotificationAction(this.label);

  /// The text shown on the button.
  final String label;
}

/// The buttons a notification can offer, as one of a fixed set of combinations.
///
/// Fixed ahead of time because iOS only shows buttons from combinations
/// registered before the app posts anything.
enum NotificationActionSet {
  /// Offered while the metronome is playing.
  metronomePlaying([NotificationAction.pause]);

  const NotificationActionSet(this.actions);

  /// The buttons, in the order they appear.
  final List<NotificationAction> actions;
}

/// A notification to show the user.
class AppNotification {
  const AppNotification({
    required this.channel,
    required this.title,
    this.summary,
    required this.body,
    this.actionSet,
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

  /// The buttons offered on the notification, or `null` for none.
  final NotificationActionSet? actionSet;
}

/// Something the user did to a notification.
class NotificationActionTapped {
  const NotificationActionTapped({
    required this.channel,
    required this.action,
  });

  /// The channel of the notification that was tapped.
  final NotificationChannel channel;

  /// The button the user tapped, or `null` if they tapped the notification
  /// itself rather than a button.
  final NotificationAction? action;
}
