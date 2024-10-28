import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/metronome/metronome.dart';

class CountDisplay extends StatefulWidget {
  /// Widget for displaying the number of beat and the [Metronome]'s current count.
  const CountDisplay({super.key});

  @override
  State<StatefulWidget> createState() => CountDisplayState();
}

class CountDisplayState extends State<CountDisplay> {
  final Metronome metronome = Metronome.instance;

  @override
  void initState() {
    super.initState();

    // Listen for changes to:
    // - higher: change number of circles
    // - count: change which circle is highlighted.
    metronome.higherNotifier.addListener(_onUpdate);
    metronome.countNotifier.addListener(_onUpdate);
  }

  @override
  void dispose() {
    metronome.higherNotifier.removeListener(_onUpdate);
    metronome.countNotifier.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(metronome.higher, (index) {
        return Icon(
          (metronome.count == index)
              ? Symbols.radio_button_checked
              : Symbols.circle, // Highlight current beat
          color: Theme.of(context).colorScheme.primary,
        );
      }),
    );
  }
}
