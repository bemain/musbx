import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late final TextTheme textTheme = GoogleFonts.andikaTextTheme(
    Theme.of(context).textTheme,
  );

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium,
        children: [
          _buildString(widget.chord.root.abbreviation),
          _buildString("${widget.chord.quality}"),
          if (widget.chord.extension != null)
            _buildString(
              "${widget.chord.extension!}",
              superscript: true,
            ),
          if (widget.chord.alterations != null)
            _buildString(
              widget.chord.alterations!,
              superscript: true,
            ),
        ],
      ),
    );
  }

  InlineSpan _buildString(String char, {bool superscript = false}) =>
      switch (char) {
        "♭" => _buildSpan(
          "♭",
          superscript: superscript,
        ),
        "♯" => _buildSpan(
          "♯",
          superscript: superscript,
        ),
        _ => _buildSpan(
          char,
          superscript: superscript,
        ),
      };

  InlineSpan _buildSpan(
    String text, {
    bool superscript = false,
  }) {
    final TextStyle? style = superscript
        ? textTheme.labelSmall
        : textTheme.bodyMedium;

    return WidgetSpan(
      baseline: TextBaseline.alphabetic,
      alignment: superscript
          ? PlaceholderAlignment.aboveBaseline
          : PlaceholderAlignment.bottom,
      style: style,
      child: Text(
        text,
        style: style?.copyWith(color: widget.color),
      ),
    );
  }
}
