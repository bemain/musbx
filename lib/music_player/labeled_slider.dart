import 'package:flutter/material.dart';

class LabeledSlider extends StatelessWidget {
  /// Label and clear button for Slider.
  const LabeledSlider({
    super.key,
    required this.value,
    this.nDigits = 1,
    this.clearDisabled = false,
    this.onClear,
    required this.child,
  });

  final Widget child;

  /// The value to show on the label.
  final double value;

  /// The number of digits used when displaying [value].
  final int nDigits;

  final bool clearDisabled;

  /// Called when the clear button is pressed.
  final Function()? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 20,
        child: Text(
          value.toStringAsFixed(nDigits),
          style: Theme.of(context).textTheme.caption,
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      ),
      Expanded(child: child),
      IconButton(
        iconSize: 20,
        onPressed: clearDisabled ? null : onClear?.call,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ]);
  }
}
