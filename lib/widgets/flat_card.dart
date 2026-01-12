import 'package:flutter/material.dart';

/// A card with no elevation and rounded corners.
class FlatCard extends StatelessWidget {
  /// Creates a [FlatCard].
  const FlatCard({
    super.key,
    this.color,
    this.radius = const BorderRadius.all(Radius.circular(32)),
    this.margin,
    required this.child,
  });

  /// The background color of the card.
  ///
  /// If null, [CardTheme.color] is used.
  final Color? color;

  /// The border radius for the card's corners.
  final BorderRadiusGeometry radius;

  /// The empty space surrounding the card.
  ///
  /// See [Card.margin].
  final EdgeInsetsGeometry? margin;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
      ),
      margin: margin,
      color: color,
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }
}
