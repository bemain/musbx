import 'package:flutter/material.dart';

class AlertSheet extends StatelessWidget {
  /// A bottom sheet that mimics the style of an [AlertDialog].
  ///
  /// An alert sheet informs the user about
  /// situations that require acknowledgment. An alert sheet has an optional
  /// title and an optional list of actions. The title is displayed above the
  /// content and the actions are displayed below the content.
  const AlertSheet({
    super.key,
    this.title,
    required this.content,
    this.actions,
  });

  final Widget? title;

  final Widget? content;

  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                top: 24.0,
                right: 24.0,
                bottom: content == null ? 20.0 : 0.0,
              ),
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.headlineSmall,
                child: title!,
              ),
            ),
          if (content != null)
            Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                top: 16.0,
                right: 24.0,
                bottom: 24.0,
              ),
              child: content!,
            ),
          if (actions != null)
            Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: 24.0,
              ),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowAlignment: OverflowBarAlignment.end,
                overflowDirection: VerticalDirection.down,
                overflowSpacing: 0,
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}
