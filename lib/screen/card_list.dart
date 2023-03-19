import 'package:flutter/material.dart';
import 'package:musbx/screen/widget_card.dart';

class CardList extends StatelessWidget {
  const CardList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: children.map((widget) => WidgetCard(child: widget)).toList(),
    );
  }
}
