import 'package:flutter/material.dart';
import 'package:musbx/music_player/music_player.dart';

class CardHeader extends StatelessWidget {
  /// A widget placed at the top of each component card.
  ///
  /// Includes a switch for toggling if the component is enabled,
  /// the title of the component, and a reset button.
  const CardHeader({
    super.key,
    required this.title,
    required this.enabled,
    this.onEnabledChanged,
    this.onResetPressed,
  });

  final String title;
  final bool enabled;
  final void Function(bool)? onEnabledChanged;
  final void Function()? onResetPressed;

  @override
  Widget build(BuildContext context) {
    final MusicPlayer musicPlayer = MusicPlayer.instance;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: enabled,
            onChanged: musicPlayer.nullIfNoSongElse(onEnabledChanged),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            iconSize: 20,
            onPressed: musicPlayer.nullIfNoSongElse(onResetPressed),
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}
