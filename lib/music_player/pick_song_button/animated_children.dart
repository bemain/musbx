import 'package:flutter/material.dart';
import 'speed_dial_child.dart';

class AnimatedChildren extends StatelessWidget {
  final Animation<double> animation;
  final List<SpeedDialChild> actions;
  final Future Function() close;
  final bool invokeAfterClosing;

  const AnimatedChildren({
    Key? key,
    required this.animation,
    required this.actions,
    required this.close,
    required this.invokeAfterClosing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ...List.generate(
            actions.length,
            (i) => _buildAnimatedSpeedDialChild(context, i),
          )
        ],
      ),
    );
  }

  Widget _buildAnimatedSpeedDialChild(BuildContext context, int i) {
    final speedDialChild = actions[i];
    final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Interval(((actions.length - 1 - i) / actions.length), 1,
            curve: Curves.easeInOutCubic));

    onPressed(event) async {
      invokeAfterClosing ? await close() : close();
      speedDialChild.onPressed?.call();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Listener(
        onPointerUp: onPressed,
        child: Row(
          children: [
            DefaultTextStyle(
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Opacity(
                opacity: curvedAnimation.value,
                child: Center(child: speedDialChild.label),
              ),
            ),
            const SizedBox(width: 16),
            ScaleTransition(
              scale: curvedAnimation,
              child: Container(
                width: 56,
                alignment: Alignment.center,
                child: speedDialChild,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
