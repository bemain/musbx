import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.25),
            blurRadius: 8.0,
            spreadRadius: 4.0,
          )
        ],
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(12.0),
          ),
        ),
        color: Theme.of(context).colorScheme.surface,
        elevation: 3.0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: child,
        ),
      ),
    );
  }
}
