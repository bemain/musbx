import 'package:flutter/material.dart';

class CardList extends StatelessWidget {
  const CardList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: children
          .map((Widget widget) => Card(
                key: ValueKey(widget),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: widget),
              ))
          .toList(),
    );
  }
}
