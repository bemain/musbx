import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/notifications.dart';

class NotificationIndicator extends StatelessWidget {
  const NotificationIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Notifications.hasPermissionNotifier,
      builder: (context, hasPermission, child) {
        if (hasPermission) return const SizedBox();

        return IconButton(
          onPressed: () {
            if (hasPermission) return;
            _requestPermission(context);
          },
          icon: const Icon(Icons.notifications_off),
        );
      },
    );
  }

  Future<void> _requestPermission(BuildContext context) async {
    if (await Notifications.shouldShowRationale()) {
      if (!context.mounted) return;
      final bool mayRequestPermission = await showDialog(
        context: context,
        builder: (context) => const NotificationPermissionRationale(),
      );
      if (!mayRequestPermission) return;
    }

    await Notifications.requestPermission();
    if (Notifications.hasPermission && Metronome.instance.isPlaying) {
      await Metronome.instance.updateNotification();
    }
  }
}

class NotificationPermissionRationale extends StatelessWidget {
  const NotificationPermissionRationale({super.key});

  @override
  Widget build(BuildContext context) {
    Notifications.hasRequestedPermission = true;

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
