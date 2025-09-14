import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/model/accidental.dart';
import 'package:musbx/model/pitch.dart';
import 'package:musbx/model/pitch_class.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/settings/selectors.dart';
import 'package:musbx/tuner/tuner.dart';
import 'package:musbx/utils/launch_handler.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/custom_icons.dart';
import 'package:musbx/widgets/exception_dialogs.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// A page with a slide-from-right transition.
CustomTransitionPage<void> settingsPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeIn)),
        ),
        child: child,
      );
    },
    child: child,
  );
}

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
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 4),
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
          SectionTitle(text: "Tuner"),
          ValueListenableBuilder(
            valueListenable: Tuner.instance.tuningNotifier,
            builder: (context, tuning, child) => ListTile(
              leading: Icon(CustomIcons.tuning_fork),
              title: Text("Tuning"),
              subtitle: Text(
                "${tuning.frequency.toStringAsFixed(0)} Hz",
              ),
              onTap: () async {
                final double? frequency = await showDialog<double>(
                  context: context,
                  builder: (context) => TuningSelector(
                    initialFrequency: tuning.frequency.toInt(),
                  ),
                );
                if (frequency == null) return;

                Tuner.instance.tuning = Pitch(PitchClass.a(), 4, frequency);
              },
            ),
          ),
          ValueListenableBuilder(
            valueListenable: Tuner.instance.preferredAccidentalNotifier,
            builder: (context, accidental, child) => ListTile(
              leading: Icon(CustomIcons.accidentals),
              title: Text("Preferred accidentals"),
              subtitle: Text(
                AccidentalSelector.accidentalDescription(accidental),
              ),
              onTap: () async {
                final Accidental? value = await showDialog<Accidental>(
                  context: context,
                  builder: (context) => AccidentalSelector(
                    initialAccidental: accidental,
                  ),
                );
                if (value == null) return;

                Tuner.instance.preferredAccidental = value;
              },
            ),
          ),

          SectionTitle(text: "General"),
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

          SectionTitle(text: "Contact me"),
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
