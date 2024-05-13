import 'package:flutter/material.dart';

class WidgetCard extends StatelessWidget {
  /// Wraps [child] in a card and adds padding around it.
  const WidgetCard({super.key, required this.child});

  /// The widget to wrap in a card.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(child),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: child,
      ),
    );
  }
}
