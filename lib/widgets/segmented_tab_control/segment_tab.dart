import 'package:flutter/material.dart';

const double _kTabHeight = 46.0;

class SegmentTab extends StatelessWidget {
  const SegmentTab({
    super.key,
    this.text,
    this.child,
    this.icon,
    this.iconMargin,
    this.height,
  }) : assert(text != null || child != null || icon != null),
       assert(text == null || child == null);

  /// The text to display as the tab's label.
  ///
  /// Must not be used in combination with [child].
  final String? text;

  /// The widget to be used as the tab's label.
  ///
  /// Usually a [Text] widget, possibly wrapped in a [Semantics] widget.
  ///
  /// Must not be used in combination with [text].
  final Widget? child;

  /// An icon to display as the tab's label.
  final Widget? icon;

  /// The margin added around the tab's icon.
  ///
  /// Only useful when used in combination with [icon], and either one of
  /// [text] or [child] is non-null.
  ///
  /// Defaults to 8 pixels of right margin.
  final EdgeInsetsGeometry? iconMargin;

  /// The height of the [Tab].
  ///
  /// If null, the height will be calculated based on the content of the [Tab].
  /// The default height is 46.0 pixels.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Widget label;
    if (icon == null) {
      label = _buildLabelText();
    } else if (text == null && child == null) {
      label = icon!;
    } else {
      label = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: iconMargin ?? const EdgeInsets.only(right: 8),
            child: icon,
          ),
          _buildLabelText(),
        ],
      );
    }
    return SizedBox(
      height: height ?? _kTabHeight,
      child: Center(
        child: label,
      ),
    );
  }

  Widget _buildLabelText() {
    return child ?? Text(text!, softWrap: false, overflow: TextOverflow.fade);
  }
}
