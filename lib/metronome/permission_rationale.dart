import 'package:flutter/material.dart';
import 'package:musbx/notifications.dart';

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
