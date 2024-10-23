import 'package:flutter/material.dart';

class FlatCard extends StatelessWidget {
  const FlatCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    );
  }
}
