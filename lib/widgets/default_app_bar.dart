import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/utils/purchases.dart';
import 'package:musbx/widgets/exception_dialogs.dart';

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Create an [AppBar] with the text "Musician's toolbox" as title
  /// that features a button for opening an about dialog, that displays
  /// [helpText] and general information about the app.
  const DefaultAppBar({
    super.key,
    this.title,
    this.leading,
    this.helpText,
  }) : preferredSize = const Size.fromHeight(kToolbarHeight);

  /// The primary widget displayed in the app bar.
  final Widget? title;

  final Widget? leading;

  /// A short text explaining how to use the screen. Displayed in the about dialog.
  final String? helpText;

  @override
  final Size preferredSize; // default is 56.0

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: title,
      actions: const [
        GetPremiumButton(),
        SettingsButton(),
      ],
    );
  }
}

class GetPremiumButton extends StatelessWidget {
  /// A simple icon button that opens the "Get Premium"-dialog when pressed.
  /// If [Purchases.hasPremium] is true, returns a zero-sized box.
  const GetPremiumButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Purchases.hasPremiumNotifier,
      builder: (context, hasPremium, child) {
        if (hasPremium) return const SizedBox();

        return IconButton(
          onPressed: () {
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              builder: (context) => const FreeAccessRestrictedDialog(),
            );
          },
          icon: const Icon(Symbols.workspace_premium),
        );
      },
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.push(Routes.settings);
      },
      icon: const Icon(Symbols.settings),
    );
  }
}
