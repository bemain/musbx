import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/settings/settings_page.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contact"),
      ),
      body: SettingsList(
        children: [
          SectionTitle(text: "Contact Developer"),
          ListTile(
            leading: Icon(Symbols.mail),
            title: Text("Mail"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("mailto:bemain.dev@gmail.com"));
            },
          ),
          ListTile(
            leading: Icon(Symbols.captive_portal),
            title: Text("Website"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://bemain.github.io"));
            },
          ),
          ListTile(
            leading: Icon(SimpleIcons.github),
            title: Text("GitHub"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://github.com/bemain"));
            },
          ),
        ],
      ),
    );
  }
}
