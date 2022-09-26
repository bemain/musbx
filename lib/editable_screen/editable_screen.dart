import 'package:flutter/material.dart';
import 'package:musbx/editable_screen/card_list.dart';
import 'package:musbx/editable_screen/reorderable_card_list.dart';

class EditableScreen extends StatefulWidget {
  const EditableScreen({super.key, required this.title, required this.widgets});

  final String title;
  final List<Widget> widgets;

  @override
  State<StatefulWidget> createState() => EditableScreenState();
}

class EditableScreenState extends State<EditableScreen> {
  late List<int> widgetOrder =
      List.generate(widget.widgets.length, (index) => index);

  bool editing = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> sortedWidgets = widgetOrder
        .map(
          (widgetIndex) => widget.widgets[widgetIndex],
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? "Editing ${widget.title}..." : widget.title),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  editing = !editing;
                });
              },
              icon: Icon(editing ? Icons.done : Icons.edit)),
        ],
      ),
      floatingActionButton: editing
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  editing = false;
                });
              },
              child: const Icon(Icons.check),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: editing
          ? ReorderableCardList(
              children: sortedWidgets,
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  int widgetIndex = widgetOrder[oldIndex];
                  widgetOrder.remove(widgetIndex);
                  if (newIndex > widgetOrder.length) {
                    widgetOrder.add(widgetIndex);
                  } else {
                    widgetOrder.insert(newIndex, widgetIndex);
                  }
                });
              },
            )
          : CardList(children: sortedWidgets),
    );
  }
}
