import 'package:flutter/material.dart';

class ReorderableCardList extends StatefulWidget {
  const ReorderableCardList({
    super.key,
    required this.children,
    this.onReorder,
    this.onReorderDone,
  });

  final List<Widget> children;
  final Function(List<Widget> reorderedChildren)? onReorder;
  final Function(List<Widget> reorderedChildren)? onReorderDone;

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
      footer: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ElevatedButton(
          onPressed: () {
            widget.onReorderDone?.call(reorderedChildren);
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(15),
          ),
          child: const Icon(Icons.check),
        ),
      ),
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
