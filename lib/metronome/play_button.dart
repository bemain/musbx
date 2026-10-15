import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/data/repositories/metronome/metronome_repository.dart';
import 'package:musbx/data/repositories/notification/notification_repository.dart';
import 'package:musbx/metronome/notification_indicator.dart';
import 'package:provider/provider.dart';

/// Play / pause button to start or stop the [Metronome].
class PlayButton extends StatelessWidget {
  const PlayButton({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final MetronomeRepository metronome = context.read();

    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: () => _onPressed(context),
      child: Center(
        child: SizedBox.square(
          dimension: 150,
          child: FittedBox(
            child: Icon(
              metronome.isPlaying
                  ? Symbols.stop_rounded
                  : Symbols.play_arrow_rounded,
              color: Theme.of(context).colorScheme.primary,
              fill: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _onPressed(BuildContext context) {
    final MetronomeRepository metronome = context.read();
    if (metronome.isPlaying) {
      metronome.pause();
    } else {
      metronome.resume();
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
      await notifications.requestPermission();
    }
  }
}
