import 'package:flutter/material.dart';

class CircularLoadingCheck extends StatelessWidget {
  /// A circular loading indicator that turns into a checkmark when completed.
  const CircularLoadingCheck({
    super.key,
    this.progress,
    required this.isComplete,
    this.size = 48.0,
  });

  final double? progress;
  final bool isComplete;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: isComplete
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey("check_icon"),
                size: size * 0.8,
                color: Theme.of(context).colorScheme.primary,
              )
            : CircularProgressIndicator(
                key: const ValueKey("progress_indicator"),
                constraints: BoxConstraints(minHeight: size, minWidth: size),
                value: progress,
              ),
      ),
    );
  }
}
