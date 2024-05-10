import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/metronome/notification_indicator.dart';
import 'package:musbx/notifications.dart';
import 'package:musbx/widgets.dart';

class PlayButton extends StatelessWidget {
  /// Play / pause button to start or stop the [Metronome].
  const PlayButton({Key? key, this.size}) : super(key: key);

  final double? size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Metronome.instance.isPlayingNotifier,
      builder: (context, bool isRunning, child) {
        final IconData icon =
            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded;

        return IconButton(
          onPressed: () {
            if (isRunning) {
              Metronome.instance.pause();
            } else {
              Metronome.instance.play();
              _requestNotificationPermission(context);
            }
          },
          color: Theme.of(context).colorScheme.primary,
          icon: size == null
              ? ExpandedIcon(icon)
              : Icon(
                  icon,
                  size: size,
                ),
        );
      },
    );
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    if (!Notifications.hasPermission) {
      if (await Notifications.shouldShowRationale()) {
        if (!context.mounted) return;
        await showDialog(
          context: context,
          builder: (context) => const NotificationPermissionRationale(),
        );

        if (Notifications.hasPermission) {
          await Metronome.instance.updateNotification();
        }
      }
    }
  }
}
