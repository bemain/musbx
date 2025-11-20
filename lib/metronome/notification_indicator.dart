import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/utils/notifications.dart';

class MetronomeNotificationIndicator extends StatelessWidget {
  const MetronomeNotificationIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Notifications.hasPermissionNotifier,
      builder: (context, hasPermission, child) => ValueListenableBuilder(
        valueListenable: Metronome.instance.showNotificationNotifier,
        builder: (context, showNotification, child) {
          if (showNotification && hasPermission) return const SizedBox();

          return IconButton(
            onPressed: () async {
              await _requestPermission(context);
              if (!context.mounted) return;
              await _requestShowNotification(context);
            },
            icon: const Icon(Symbols.notifications_off),
          );
        },
      ),
    );
  }

  /// Ask for permission to send notifications.
  Future<void> _requestPermission(BuildContext context) async {
    if (Notifications.hasPermission) return;

    if (await Notifications.shouldShowRationale()) {
      if (!context.mounted) return;
      final bool mayRequestPermission =
          await showDialog(
            context: context,
            builder: (context) => const NotificationPermissionRationale(),
          ) ??
          false;
      if (!mayRequestPermission) return;
    }

    await Notifications.requestPermission();

    if (Notifications.hasPermission) {
      // When permission is given, we assume the user wants us to show a notification.
      Metronome.instance.showNotification = true;
    }

    if (Notifications.hasPermission && Metronome.instance.isPlaying) {
      await Metronome.instance.updateNotification();
    }
  }

  /// Ask if we can show a Metronome notification, if the user has disabled it
  /// in the settings.
  Future<void> _requestShowNotification(BuildContext context) async {
    if (Metronome.instance.showNotification) return;

    final bool? mayShowNotification = await showDialog(
      context: context,
      builder: (context) => const NotificationShowRequestDialog(),
    );

    if (mayShowNotification != null) {
      Metronome.instance.showNotification = mayShowNotification;
    }
  }
}

class NotificationShowRequestDialog extends StatelessWidget {
  const NotificationShowRequestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enable Metronome notification"),
      icon: const Icon(Symbols.notification_settings, weight: 600),
      content: const Text(
        "A notification will be shown while the Metronome is playing so you can pause it without opening the app. \nThis can be disabled in the Settings.",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text("Enable"),
        ),
      ],
    );
  }
}

class NotificationPermissionRationale extends StatelessWidget {
  const NotificationPermissionRationale({super.key});

  @override
  Widget build(BuildContext context) {
    Notifications.hasRequestedPermission.value = true;

    return AlertDialog(
      title: const Text("Enable notifications"),
      icon: const Icon(Symbols.notifications_active, weight: 600),
      content: const Text(
        "Turn on notifications to quickly access the Metronome from the notifications drawer.",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text("Deny"),
        ),
        FilledButton(
          onPressed: () {
            Notifications.requestPermission();
            Navigator.of(context).pop(true);
          },
          child: const Text("Allow"),
        ),
      ],
    );
  }
}
