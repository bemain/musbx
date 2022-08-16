import 'package:flutter/material.dart';

class ReorderableCardList extends StatefulWidget {
  const ReorderableCardList({
    super.key,
    required this.children,
    this.onReorder,
  });

  final List<Widget> children;
  final Function(List<Widget> reorderedChildren)? onReorder;

  @override
  State<StatefulWidget> createState() => ReorderableCardListState();
}

class ReorderableCardListState extends State<ReorderableCardList> {
  late List<Widget> reorderedChildren = widget.children;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          Widget child = reorderedChildren[oldIndex];
          reorderedChildren.remove(child);
          if (newIndex > reorderedChildren.length) {
            reorderedChildren.add(child);
          } else {
            reorderedChildren.insert(newIndex, child);
          }
        });
        widget.onReorder?.call(reorderedChildren);
      },
      children: reorderedChildren
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
