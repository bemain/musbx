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

class CardList extends StatelessWidget {
  /// Displays [children] as a list of cards,
  /// with an app bar featuring a button to open an about dialog.
  const CardList({super.key, required this.children, this.helpText});

  /// The widgets to display as a list of cards.
  final List<Widget> children;

  /// A short text explaining how to use the screen. Displayed in the about dialog.
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Musician's toolbox"),
        actions: [
          InfoButton(child: (helpText == null) ? null : Text(helpText!))
        ],
      ),
      body: ListView(
        children: children
            .map((Widget widget) => Card(
                  key: ValueKey(widget),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: widget),
                ))
            .toList(),
      ),
    );
  }
}
