import 'package:flutter/material.dart';

class EmptyTabBar extends StatelessWidget {
  /// A [TabBar] with tabs that are all empty (have no label or icon).
  ///
  /// Uses [DefaultTabController.of] to determine the number of tabs.
  const EmptyTabBar({super.key, this.height = 20});

  /// The height of the TabBar.
  ///
  /// Defaults to 20.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TabBar(
        tabs: List.filled(
          DefaultTabController.of(context).length,
          Tab(child: Container()),
        ),
      ),
    );
  }
}
