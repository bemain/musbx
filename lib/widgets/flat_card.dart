import 'package:flutter/material.dart';

/// A card with no elevation and rounded corners.
class FlatCard extends StatelessWidget {
  /// Creates a [FlatCard].
  const FlatCard({
    super.key,
    this.color,
    this.radius = const BorderRadius.all(Radius.circular(32)),
    required this.child,
  });

  /// The background color of the card.
  ///
  /// If null, [CardTheme.color] is used.
  final Color? color;

  /// The border radius for the card's corners.
  final BorderRadiusGeometry radius;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
      ),
      color: color,
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }
}
