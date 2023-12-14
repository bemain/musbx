import 'package:flutter/material.dart';

class SpeedDialChild extends StatelessWidget {
  const SpeedDialChild({
    super.key,
    this.onPressed,
    this.child,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;

  final Widget? label;
  final Widget? child;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () {},
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: child,
    );
  }
}
