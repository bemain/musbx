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

class CardScreen extends StatelessWidget {
  /// Displays [children] as a list of cards,
  /// with an app bar featuring a button to open an about dialog.
  const CardScreen({
    super.key,
    required this.children,
    this.header,
    this.headerHeight,
    this.helpText,
    this.tabs,
  });

  /// Widget show above
  final Widget? header;

  final double? headerHeight;

  final List<Tab>? tabs;

  /// The widgets to display as a list of cards.
  final List<Widget> children;

  /// A short text explaining how to use the screen. Displayed in the about dialog.
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    if (header != null) assert(headerHeight != null);

    if (tabs == null) return buildCardListView();

    return buildTabView();
  }

  Widget buildCardListView() {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Musician's toolbox"),
          actions: [
            InfoButton(child: (helpText == null) ? null : Text(helpText!))
          ],
          bottom: header == null
              ? null
              : PreferredSize(
                  preferredSize: Size.fromHeight(headerHeight!),
                  child: WidgetCard(child: header!),
                ),
        ),
        body: CardList(children: children));
  }

  Widget buildTabView() {
    TabBar tabBar = TabBar(tabs: tabs!);

    return DefaultTabController(
      length: tabs!.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Musician's toolbox"),
          actions: [
            InfoButton(child: (helpText == null) ? null : Text(helpText!))
          ],
          bottom: tabBar,
        ),
        body: Column(
          children: [
            WidgetCard(child: header!),
            Expanded(
              child: TabBarView(children: children),
            ),
          ],
        ),
      ),
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
