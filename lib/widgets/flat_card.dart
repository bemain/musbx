import 'package:flutter/material.dart';

class FlatCard extends StatelessWidget {
  const FlatCard({
    super.key,
    this.radius = const BorderRadius.all(Radius.circular(32)),
    required this.child,
  });

  final BorderRadiusGeometry radius;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }
}
