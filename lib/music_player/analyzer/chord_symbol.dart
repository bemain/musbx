import 'package:flutter/material.dart';
import 'package:musbx/model/chord.dart';

class ChordSymbol extends StatefulWidget {
  /// Widget displaying a musical [chord].
  const ChordSymbol({super.key, required this.chord, this.color});

  /// The chord being displayed.
  final Chord chord;

  /// The color of the symbol.
  final Color? color;

  @override
  State<StatefulWidget> createState() => _ChordSymbolState();
}

class _ChordSymbolState extends State<ChordSymbol> {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          ...widget.chord.root.toString().characters.map(_buildChar),
          _buildChar("${widget.chord.quality}"),
          if (widget.chord.extension != null)
            _buildChar(
              "${widget.chord.extension!}",
              superscript: true,
            ),
          if (widget.chord.alterations != null)
            ...widget.chord.alterations!.characters.map((char) => _buildChar(
                  char,
                  superscript: true,
                ))
        ],
      ),
    );
  }

  WidgetSpan _buildChar(String char, {bool superscript = false}) =>
      switch (char) {
        "♭" => _buildSpan(
            char,
            superscript: superscript,
            textScaler: const TextScaler.linear(1.3),
            offsetFraction: 1 / 16,
          ),
        "♯" => _buildSpan(
            char,
            superscript: superscript,
            offsetFraction: -1 / 6,
          ),
        _ => _buildSpan(
            char,
            superscript: superscript,
          ),
      };

  WidgetSpan _buildSpan(
    String text, {
    bool superscript = false,
    TextScaler? textScaler,
    double? offsetFraction,
  }) {
    final TextStyle? style = superscript
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.bodyMedium;

    return WidgetSpan(
      baseline: TextBaseline.alphabetic,
      alignment: superscript
          ? PlaceholderAlignment.aboveBaseline
          : PlaceholderAlignment.bottom,
      style: style,
      child: Transform.translate(
        offset: Offset(
          0.0,
          (style?.fontSize ?? 14) * (offsetFraction ?? 0),
        ),
        child: Text(
          text,
          style: style?.copyWith(color: widget.color),
          textScaler: textScaler,
        ),
      ),
    );
  }
}
