import 'dart:math';

import 'package:flutter/material.dart';

/// Widget based on [TabController]. Can simply replace [TabBar].
///
/// Requires [TabController], witch can be read from [context] with
/// [DefaultTabController] using. Or you can provide controller in the constructor.
class SegmentedTabControl extends StatefulWidget
    implements PreferredSizeWidget {
  const SegmentedTabControl({
    super.key,
    required this.tabs,
    this.height = kTextTabBarHeight,
    this.controller,
    this.textColor,
    this.textStyle,
    this.selectedTabPadding = EdgeInsets.zero,
    this.selectedTabColor,
    this.selectedTabTextStyle,
    this.selectedTabTextColor,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.splashColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
  });

  /// Height of the widget.
  ///
  /// [preferredSize] returns this value.
  final double height;

  final List<Widget> tabs;

  /// Can be provided by [DefaultTabController].
  final TabController? controller;

  /// Style of the text on tabs that are not selected.
  final TextStyle? textStyle;

  /// Style of the text on the selected tab.
  final TextStyle? selectedTabTextStyle;

  /// The color of the text on tabs that are not selected.
  final Color? textColor;

  /// The color of the text on the selected tab.
  final Color? selectedTabTextColor;

  /// Padding around the selected tab.
  final EdgeInsets selectedTabPadding;

  /// The color of the selected tab.
  final Color? selectedTabColor;

  /// Padding between the tabs.
  final EdgeInsets tabPadding;

  /// The splash color used for the `InkWell`s wrapping the tabs.
  final Color? splashColor;

  final BorderRadiusGeometry borderRadius;

  @override
  State<SegmentedTabControl> createState() => _SegmentedTabControlState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _SegmentedTabControlState extends State<SegmentedTabControl> {
  late final _controller =
      widget.controller ?? DefaultTabController.of(context);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
          elevation: 0,
          child: SizedBox(
            height: widget.height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.tabs.length; i++)
                  _buildTab(context, i),
              ],
            ),
          ),
        );
      },
    );
  }

  Card _buildTab(BuildContext context, int i) {
    final bool isSelected = _controller.index == i;

    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle? textStyle =
        ((isSelected ? widget.selectedTabTextStyle : null) ??
                widget.textStyle ??
                Theme.of(context).textTheme.titleSmall)
            ?.copyWith(
      color: (isSelected
          ? widget.selectedTabTextColor ?? colors.onPrimaryContainer
          : widget.textColor ?? colors.onSurface),
    );

    final BorderRadius borderRadius = widget.borderRadius
        .subtract(
          BorderRadius.only(
            topRight: Radius.circular(max(
              widget.selectedTabPadding.right,
              widget.selectedTabPadding.top,
            )),
            topLeft: Radius.circular(max(
              widget.selectedTabPadding.left,
              widget.selectedTabPadding.top,
            )),
            bottomRight: Radius.circular(max(
              widget.selectedTabPadding.right,
              widget.selectedTabPadding.bottom,
            )),
            bottomLeft: Radius.circular(max(
              widget.selectedTabPadding.left,
              widget.selectedTabPadding.bottom,
            )),
          ),
        )
        .resolve(null);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      elevation: 0,
      color: isSelected
          ? widget.selectedTabColor ?? colors.primaryContainer
          : Colors.transparent,
      margin: widget.selectedTabPadding,
      child: InkWell(
        borderRadius: borderRadius,
        splashColor: widget.splashColor,
        onTap: isSelected
            ? null
            : () {
                _controller.animateTo(i);
              },
        child: Padding(
          padding: widget.tabPadding,
          child: DefaultTextStyle.merge(
            style: textStyle,
            child: widget.tabs[i],
          ),
        ),
      ),
    );
  }
}
