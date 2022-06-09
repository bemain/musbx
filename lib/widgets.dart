import 'dart:async';

import 'package:flutter/material.dart';

class ContinuousButton extends StatelessWidget {
  /// Button that can be held down to yield continuous presses.
  const ContinuousButton({
    super.key,
    required this.onPressed,
    this.interval = const Duration(milliseconds: 100),
    required this.child,
  });

  /// Callback for when this button is pressed.
  final void Function() onPressed;

  /// Interval between callbacks if the button is held pressed.
  final Duration interval;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Timer timer = Timer(const Duration(), () {});
    return GestureDetector(
      onTap: onPressed,
      onLongPressStart: (LongPressStartDetails details) {
        timer = Timer.periodic(interval, (timer) => onPressed());
      },
      onLongPressUp: () {
        timer.cancel();
      },
      onLongPressCancel: () {
        timer.cancel();
      },
      child: child,
    );
  }
}
