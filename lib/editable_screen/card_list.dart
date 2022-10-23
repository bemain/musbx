import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CardList extends StatelessWidget {
  const CardList({super.key, required this.children, this.screenHelp});

  final List<Widget> children;
  final String? screenHelp;

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
                  children: (screenHelp == null)
                      ? null
                      : [
                          Text(
                            screenHelp!,
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
