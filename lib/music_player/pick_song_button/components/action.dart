import 'package:flutter/material.dart';
import 'package:musbx/music_player/pick_song_button/speed_dial.dart';

class SpeedDialAction extends SpeedDialChild {
  /// A child of [SpeedDial] with a small [FloatingActionButton] and a [label] (usually a Text widget) beside it.
  const SpeedDialAction({
    this.onPressed,
    this.child,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Callback for when the [FloatingActionButton] is pressed.
  final void Function(PointerUpEvent event)? onPressed;

  /// The label describing the action performed when the [FloatingActionButton] is pressed.
  final Widget? label;

  /// The child of the [FloatingActionButton].
  final Widget? child;

  /// The background color of the [FloatingActionButton].
  final Color? backgroundColor;

  /// The foreground color of the [FloatingActionButton].
  final Color? foregroundColor;

  @override
  Widget assemble(BuildContext context, Animation<double> animation) {
    final colors = Theme.of(context).colorScheme;
    return Listener(
      onPointerUp: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  overflow: TextOverflow.ellipsis,
                ),
            child: Opacity(
              opacity: animation.value,
              child: Center(child: label),
            ),
          ),
          const SizedBox(width: 16),
          ScaleTransition(
            scale: animation,
            child: Container(
              width: 56,
              alignment: Alignment.center,
              child: FloatingActionButton.small(
                onPressed: () {},
                backgroundColor: backgroundColor ??
                    Color.alphaBlend(
                        colors.surfaceTint.withOpacity(0.1), colors.surface),
                foregroundColor: foregroundColor ?? colors.primary,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
