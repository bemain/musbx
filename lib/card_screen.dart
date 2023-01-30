import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InfoButton extends StatelessWidget {
  /// A button that opens an about dialog when pressed.
  ///
  /// The dialog shows info about the app and allows the user to view licenses.
  /// It also shows [child].
  const InfoButton({
    super.key,
    this.child,
  });

  /// Additional widget shown in the about dialog
  final Widget? child;

  static PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () async {
          packageInfo ??= await PackageInfo.fromPlatform();

          showAboutDialog(
            context: context,
            applicationIcon: const ImageIcon(
              AssetImage("assets/icon/musbx.png"),
            ),
            applicationVersion: "Version ${packageInfo?.version}",
            children: (child == null) ? null : [child!],
          );
        },
        icon: const Icon(Icons.info_outline_rounded));
  }
}

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

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DefaultAppBar({super.key, this.helpText})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  /// A short text explaining how to use the screen. Displayed in the about dialog.
  final String? helpText;

  @override
  final Size preferredSize; // default is 56.0

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Musician's toolbox"),
      actions: [InfoButton(child: (helpText == null) ? null : Text(helpText!))],
    );
  }
}

class WidgetCard extends StatelessWidget {
  /// Wraps [child] in a card.
  const WidgetCard({super.key, required this.child});

  /// The widget to wrap in a card.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(child),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        child: child,
      ),
    );
  }
}

class CardList extends StatelessWidget {
  const CardList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: children.map((widget) => WidgetCard(child: widget)).toList(),
    );
  }
}
