import 'package:flutter/material.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/metronome/notification_indicator.dart';
import 'package:musbx/utils/notifications.dart';

class PlayButton extends StatelessWidget {
  /// Play / pause button to start or stop the [Metronome].
  const PlayButton({Key? key, this.size}) : super(key: key);

  final double? size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Metronome.instance.isPlayingNotifier,
      builder: (context, bool isPlaying, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => _onPressed(context),
          child: Center(
            child: SizedBox.square(
              dimension: 150,
              child: FittedBox(
                child: Icon(
                  color: Theme.of(context).colorScheme.primary,
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPressed(BuildContext context) {
    if (Metronome.instance.isPlaying) {
      Metronome.instance.pause();
    } else {
      Metronome.instance.play();
      _requestNotificationPermission(context);
    }
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    if (!Notifications.hasPermission &&
        !Notifications.hasRequestedPermission.value) {
      if (await Notifications.shouldShowRationale()) {
        if (!context.mounted) return;
        await showDialog(
          context: context,
          builder: (context) => const NotificationPermissionRationale(),
        );
      } else {
        await Notifications.requestPermission();
      }

      if (Notifications.hasPermission) {
        await Metronome.instance.updateNotification();
      }
    }
  }
}
