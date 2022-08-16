import 'package:flutter/material.dart';
import 'package:musbx/card_list.dart';
import 'package:musbx/reorderable_card_list.dart';

class EditableScreen extends StatefulWidget {
  const EditableScreen({super.key, required this.title, required this.widgets});

  final String title;
  final List<Widget> widgets;

  @override
  State<StatefulWidget> createState() => EditableScreenState();
}

class EditableScreenState extends State<EditableScreen> {
  late List<Widget> widgets = widget.widgets;

  bool editing = false;

  @override
  Widget build(BuildContext context) {
    return editing
        ? Scaffold(
            appBar: AppBar(
              title: Text("Editing ${widget.title}..."),
              actions: [
                IconButton(
                    onPressed: () {
                      setState(() {
                        editing = false;
                      });
                    },
                    icon: const Icon(Icons.done))
              ],
            ),
            body: ReorderableCardList(
              children: widgets,
              onReorder: (reorderedWidgets) {
                widgets = reorderedWidgets;
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  editing = false;
                });
              },
              child: const Icon(Icons.check),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                IconButton(
                    onPressed: () {
                      setState(() {
                        editing = true;
                      });
                    },
                    icon: const Icon(Icons.edit))
              ],
            ),
            body: CardList(children: widgets),
          );
  }
}
