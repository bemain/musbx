import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CardList extends StatelessWidget {
  /// Displays [children] as a list of cards,
  /// with an app bar featuring a button to open an about dialog.
  const CardList({super.key, required this.children, this.helpText});

  /// The widgets to display as a list of cards.
  final List<Widget> children;

  /// A short text explaining how to use the screen. Displayed in the AboutDialog.
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Musician's toolbox"),
        actions: [
          IconButton(
              onPressed: () async {
                PackageInfo packageInfo = await PackageInfo.fromPlatform();

                showAboutDialog(
                  context: context,
                  applicationIcon: const ImageIcon(
                    AssetImage("assets/icon/musbx.png"),
                  ),
                  applicationVersion: "Version ${packageInfo.version}",
                  children: (helpText == null)
                      ? null
                      : [
                          Text(
                            helpText!,
                          )
                        ],
                );
              },
              icon: const Icon(Icons.info_outline_rounded))
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
