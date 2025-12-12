import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/settings/selectors.dart';
import 'package:musbx/theme.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/utils/utils.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri? storeUrl = Platform.isAndroid
    ? Uri.parse(
        "https://play.google.com/store/apps/details?id=se.agardh.musbx&pcampaignid=musbx_settings",
      )
    : Platform.isIOS
    ? Uri.parse("https://apps.apple.com/us/app/musicians-toolbox/id1670009655")
    : null;

class SettingsList extends StatelessWidget {
  /// Displays a list of [children] with formatting appropriate for a page in
  /// the settings menu.
  const SettingsList({
    super.key,
    required this.children,
  });

  /// The widgets to display in the list.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      data: ListTileThemeData(
        minTileHeight: 56,
        contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 24),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  /// Title for grouping a number of settings together.
  const SectionTitle({super.key, required this.text});

  /// Title describing the section.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 32, right: 16, bottom: 4),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: SettingsList(
        children: [
          SectionTitle(text: "Tools"),
          ListTile(
            leading: Icon(CustomIcons.metronome),
            title: Text("Metronome"),
            trailing: Icon(Symbols.chevron_forward),
            onTap: () {
              context.push(Routes.metronomeSettings);
            },
          ),
          ListTile(
            leading: Icon(Symbols.library_music),
            title: Text("Songs"),
            trailing: Icon(Symbols.chevron_forward),
            onTap: () {
              context.push(Routes.songsSettings);
            },
          ),
          ListTile(
            leading: Icon(Symbols.speed),
            title: Text("Tuner"),
            trailing: Icon(Symbols.chevron_forward),
            onTap: () {
              context.push(Routes.tunerSettings);
            },
          ),
          ListTile(
            leading: Icon(CustomIcons.tuning_fork),
            title: Text("Drone"),
            trailing: Icon(Symbols.chevron_forward),
            onTap: () {
              context.push(Routes.droneSettings);
            },
          ),

          SectionTitle(text: "General"),
          ValueListenableBuilder(
            valueListenable: AppTheme.themeModeNotifier,
            builder: (context, themeMode, child) => ListTile(
              leading: Icon(Symbols.routine),
              title: Text("Theme"),
              subtitle: Text(
                ThemeSelector.themeDescription(themeMode),
              ),
              onTap: () async {
                await showAlertSheet<void>(
                  context: context,
                  builder: (context) => ThemeSelector(
                    themeNotifier: AppTheme.themeModeNotifier,
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: Icon(Symbols.policy),
            title: Text("Privacy policy"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://bemain.github.io/musbx/privacy"));
            },
          ),
          ListTile(
            leading: Icon(Symbols.contract),
            title: Text("Licenses"),
            trailing: Icon(Symbols.chevron_forward),
            onTap: () {
              context.push(Routes.licenses);
            },
          ),
          if (!Purchases.hasPremium)
            ListTile(
              leading: Icon(Symbols.workspace_premium),
              title: Text("Upgrade to Premium"),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => const FreeAccessRestrictedDialog(),
                );
              },
            ),

          SectionTitle(text: "Contact"),
          ListTile(
            leading: Icon(Symbols.mail),
            title: Text("Mail"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("mailto:bemain.dev@gmail.com"));
            },
          ),
          if (Platform.isAndroid | Platform.isIOS)
            ListTile(
              leading: Icon(
                Platform.isAndroid
                    ? SimpleIcons.googleplay
                    : SimpleIcons.appstore,
              ),

              title: Text(
                Platform.isAndroid ? "Google Play" : "App Store",
              ),
              trailing: Icon(Symbols.launch),
              onTap: () {
                if (storeUrl != null) launchUrl(storeUrl!);
              },
            ),
          ListTile(
            leading: Icon(Symbols.language),
            title: Text("Website"),
            trailing: Icon(Symbols.launch),
            onTap: () {
              launchUrl(Uri.parse("https://bemain.github.io"));
            },
          ),

          const SizedBox(height: 32),
          RichText(
            text: TextSpan(
              text: "Version ${LaunchHandler.info.version}\n",
              style: TextTheme.of(context).bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(0x50),
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Symbols.copyright,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(0x50),
                  ),
                ),
                TextSpan(text: " Benjamin Agardh ${DateTime.now().year}"),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
