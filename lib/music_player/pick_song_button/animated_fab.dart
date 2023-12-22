import 'package:flutter/material.dart';

class AnimatedFAB extends StatelessWidget {
  final Animation<double> animation;
  final Color? backgroundColor;
  final Color? expandedBackgroundColor;
  final Color? foregroundColor;
  final Color? expandedForegroundColor;
  final VoidCallback? onClosePressed;
  final Widget? child;
  final Widget? expandedChild;

  const AnimatedFAB({
    Key? key,
    required this.animation,
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.foregroundColor,
    this.expandedForegroundColor,
    this.onClosePressed,
    this.child,
    this.expandedChild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColorTween = ColorTween(
        begin: backgroundColor,
        end: expandedBackgroundColor ?? backgroundColor);
    final foregroundColorTween = ColorTween(
        begin: foregroundColor,
        end: expandedForegroundColor ?? foregroundColor);
    final angleTween = Tween<double>(begin: 0, end: 1);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => FloatingActionButton(
        onPressed: onClosePressed,
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
