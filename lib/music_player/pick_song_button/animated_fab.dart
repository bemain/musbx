import 'package:flutter/material.dart';

class AnimatedFAB extends StatelessWidget {
  const AnimatedFAB({
    super.key,
    required this.animation,
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.foregroundColor,
    this.expandedForegroundColor,
    this.onExpandedPressed,
    this.child,
    this.expandedChild,
  });

  final Animation<double> animation;
  final Color? backgroundColor;
  final Color? expandedBackgroundColor;
  final Color? foregroundColor;
  final Color? expandedForegroundColor;
  final VoidCallback? onExpandedPressed;
  final Widget? child;
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    final backgroundColorTween = ColorTween(
      begin: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      end: expandedBackgroundColor ??
          backgroundColor ??
          Theme.of(context).colorScheme.primary,
    );
    final foregroundColorTween = ColorTween(
      begin:
          foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
      end: expandedForegroundColor ??
          foregroundColor ??
          Theme.of(context).colorScheme.onPrimary,
    );
    final angleTween = Tween<double>(begin: 0, end: 1);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => FloatingActionButton(
        onPressed: onExpandedPressed,
        backgroundColor: backgroundColorTween.lerp(animation.value),
        foregroundColor: foregroundColorTween.lerp(animation.value),
        child: Stack(
          children: [
            Transform.rotate(
                angle: angleTween.animate(animation).value,
                child: Opacity(opacity: 1 - animation.value, child: child)),
            Transform.rotate(
                angle: angleTween.animate(animation).value - 1,
                child: Opacity(opacity: animation.value, child: expandedChild)),
          ],
        ),
      ),
    );
  }
}
