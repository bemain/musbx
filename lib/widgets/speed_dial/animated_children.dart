import 'package:flutter/material.dart';
import 'package:musbx/widgets/speed_dial/speed_dial.dart';

class AnimatedChildren extends StatelessWidget {
  const AnimatedChildren({
    super.key,
    required this.animation,
    required this.children,
    required this.close,
  });

  final Animation<double> animation;
  final List<SpeedDialChild> children;
  final Future<void> Function() close;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ...List.generate(
            children.length,
            (i) => _buildAnimatedSpeedDialChild(context, i),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSpeedDialChild(BuildContext context, int i) {
    final speedDialChild = children[i];
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        ((children.length - 1 - i) / children.length),
        1,
        curve: Curves.easeInOutCubic,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Listener(
        onPointerUp: (event) => close(),
        child: speedDialChild.assemble(context, curvedAnimation),
      ),
    );
  }
}
