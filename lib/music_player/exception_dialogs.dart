import 'package:flutter/material.dart';
import 'package:musbx/custom_icons.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/navigation_page.dart';
import 'package:musbx/purchases.dart';

/// Show an exception dialog.
///
/// This is only dependent on [NavigationPage]'s context, and can thus be
/// used in places where no local context is available, such as button callbacks.
Future<void> showExceptionDialog(
  Widget dialog, {
  bool barrierDismissible = true,
}) async {
  if (navigationPageKey.currentContext == null ||
      !navigationPageKey.currentContext!.mounted) {
    return;
  }

  showDialog(
    context: navigationPageKey.currentContext!,
    builder: (context) => dialog,
    barrierDismissible: barrierDismissible,
  );
}

class MusicPlayerAccessRestrictedDialog extends StatelessWidget {
  const MusicPlayerAccessRestrictedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const FreeAccessRestrictedDialog(
      reason:
          "You have used your ${MusicPlayer.freeSongsPerWeek} weekly songs.",
    );
  }
}

class FreeAccessRestrictedDialog extends StatelessWidget {
  const FreeAccessRestrictedDialog({super.key, this.reason});

  /// Text explaining why access was restricted.
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.workspace_premium),
      title: const Text("Get Premium"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "${reason == null ? "" : "$reason\n\n"}Upgrade to the Premium version of Musician's Toolbox to get:"),
          const SizedBox(height: 8),
          const Text(" ★ Unlimited songs"),
          const Text(" ★ Full access to AI-powered Demixing"),
          const Text(" ★ An ad-free experience"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Dismiss"),
        ),
        FilledButton(
          onPressed: () async {
            Purchases.buyPremium();
            Navigator.of(context).pop();
          },
          child: const Text("Upgrade"),
        ),
      ],
    );
  }
}

class PremiumPurchasedDialog extends StatelessWidget {
  const PremiumPurchasedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.verified),
      title: const Text("Processing purchase"),
      content: const Text(
          """Thank you for supporting Musician's Toolbox by upgrading to Premium! 

Your purchase is processing and premium features will soon be activated. Please note that this can take up to 5 minutes."""),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Close"),
        )
      ],
    );
  }
}

class PremiumPurchaseFailedDialog extends StatelessWidget {
  const PremiumPurchaseFailedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.new_releases),
      title: const Text("Purchase failed"),
      content: const Text(
          """An error occured during your purchase, and your account has not been charged. Please try again in a few moments."""),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Dismiss"),
        ),
        FilledButton(
          onPressed: () async {
            Purchases.buyPremium();
            Navigator.of(context).pop();
          },
          child: const Text("Try again"),
        ),
      ],
    );
  }
}

class UnsupportedFileExtensionDialog extends StatelessWidget {
  /// Creates an alert dialog with the message that the selected file type is not supported.
  const UnsupportedFileExtensionDialog({super.key, required this.extension});

  final String extension;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Unsupported file type"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.file_present_rounded, size: 128),
          const SizedBox(height: 15),
          Text(
              "The file type '.$extension' is not supported. Try loading a different file.")
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Dismiss"),
        )
      ],
    );
  }
}

class FileCouldNotBeLoadedDialog extends StatelessWidget {
  /// Creates an alert dialog with the message that the selected file could not be loaded.
  const FileCouldNotBeLoadedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("File could not be loaded"),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.file_present_rounded, size: 128),
          SizedBox(height: 15),
          Text(
              "An error occurred while loading the file. Please try again later, or try selecting a different file.")
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Dismiss"),
        )
      ],
    );
  }
}

class YoutubeUnavailableDialog extends StatelessWidget {
  /// Creates an alert dialog with the message that the Youtube service is unavailable.
  const YoutubeUnavailableDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Search unavailable"),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CustomIcons.youtube, size: 128),
          SizedBox(height: 15),
          Text(
              "The Search service is currently unavailable. Please try again later.")
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Dismiss"),
        )
      ],
    );
  }
}
