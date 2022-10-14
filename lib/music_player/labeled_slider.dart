import 'package:flutter/material.dart';

class LabeledSlider extends StatelessWidget {
  /// Label and clear button for Slider.
  const LabeledSlider({
    super.key,
    required this.label,
    this.clearDisabled = false,
    this.onClear,
    required this.child,
  });

  final Widget child;

  /// The value to show on the label.
  final String label;

  final bool clearDisabled;

  /// Called when the clear button is pressed.
  final Function()? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 22,
        child: Text(
          label,
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
