import 'package:flutter/material.dart';

abstract class SpeedDialChild {
  const SpeedDialChild();

  Widget assemble(BuildContext context, Animation<double> animation);
}

class SpeedDialAction extends SpeedDialChild {
  const SpeedDialAction({
    this.onPressed,
    this.child,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final void Function(PointerUpEvent event)? onPressed;

  final Widget? label;
  final Widget? child;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget assemble(BuildContext context, Animation<double> animation) {
    return Listener(
      onPointerUp: onPressed,
      child: Row(
        children: [
          DefaultTextStyle(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
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
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
