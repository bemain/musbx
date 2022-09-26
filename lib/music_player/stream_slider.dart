import 'package:flutter/material.dart';

class StreamSlider extends StatefulWidget {
  /// Slider that listens to a stream and updates whenever it changes.
  /// Includes a label displaying the current value and a clear button.
  ///
  /// Stores a value internally and displays that. The value is updated when
  /// the user changes the slider or the stream changes.
  const StreamSlider({
    super.key,
    required this.listenable,
    this.onChanged,
    this.onChangeEnd,
    this.onClear,
    this.initialValue = 0.0,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.labelFractionDigits = 1,
  });

  /// The stream to listen to. Updates whenever this changes.
  final ValueNotifier<double> listenable;

  /// Called during a drag when the user is selecting a new value for the slider by dragging.
  /// See [Slider.onChanged]
  final Function(double value)? onChanged;

  /// Called when the user is done selecting a new value for the slider.
  /// See [Slider.onChangeEnd]
  final Function(double value)? onChangeEnd;

  /// Called when the clear button is pressed.
  final Function()? onClear;

  /// Initial value for the slider.
  final double initialValue;

  /// The minimum value the user can select.
  /// See [Slider.min]
  final double min;

  /// The maximum value the user can select.
  /// See [Slider.max]
  final double max;

  /// The number of discrete divisions.
  /// See [Slider.divisions]
  final int? divisions;

  /// The number of digits used when displaying the current value on the label.
  final int labelFractionDigits;

  @override
  State<StatefulWidget> createState() => StreamSliderState();
}

class StreamSliderState extends State<StreamSlider> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.listenable,
      builder: (context, value, child) => Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              value.toStringAsFixed(widget.labelFractionDigits),
              style: Theme.of(context).textTheme.caption,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              onChanged: (double value) {
                widget.onChanged?.call(value);
              },
              min: widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: widget.divisions,
              onChangeEnd: widget.onChangeEnd?.call,
            ),
          ),
          IconButton(
            iconSize: 20,
            onPressed: widget.onClear?.call,
            icon: const Icon(Icons.backspace_rounded),
          )
        ],
      ),
    );
  }
}
