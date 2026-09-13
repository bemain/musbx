import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/notification/notification_repository.dart';
import 'package:musbx/metronome/metronome.dart';
import 'package:musbx/metronome/notification_indicator.dart';
import 'package:musbx/utils/result.dart';
import 'package:provider/provider.dart';

class PlayButton extends StatelessWidget {
  /// Play / pause button to start or stop the [Metronome].
  const PlayButton({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Metronome.instance.isPlayingNotifier,
      builder: (context, isPlaying, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => _onPressed(context),
          child: Center(
            child: SizedBox.square(
              dimension: 150,
              child: FittedBox(
                child: Icon(
                  isPlaying
                      ? Symbols.stop_rounded
                      : Symbols.play_arrow_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  fill: 1,
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
      Metronome.instance.resume();
      _requestNotificationPermission(context);
    }
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    final NotificationRepository notifications = context.read();
    if (!notifications.hasPermission &&
        !notifications.hasRequestedPermission) {
      if (!context.mounted) return;

      final bool mayRequestPermission =
          await showDialog(
            context: context,
            builder: (context) => const NotificationPermissionRationale(),
          ) ??
          false;
      if (!mayRequestPermission) return;

      if (await notifications.requestPermission() case Ok(
        value: true,
      )) {
        await Metronome.instance.updateNotification();
      }
    }
  }
}
