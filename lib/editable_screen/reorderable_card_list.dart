import 'package:flutter/material.dart';

class ReorderableCardList extends StatelessWidget {
  const ReorderableCardList({
    super.key,
    required this.children,
    required this.onReorder,
  });

  final List<Widget> children;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: onReorder,
      children: children
          .map((Widget widget) => Card(
                key: ValueKey(widget),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: AbsorbPointer(child: widget),
                ),
              ))
          .toList(),
    );
  }
}
