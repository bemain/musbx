import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/exception_dialogs.dart';
import 'package:musbx/persistent_value.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class LaunchHandler {
  static bool initialized = false;

  static Future<void> initialize() async {
    if (initialized) return;
    initialized = true;

    final PackageInfo info = await PackageInfo.fromPlatform();

    if (info.buildNumber != lastVersionLaunched.value) {
      onFirstLaunchWithVersion(info);
      lastVersionLaunched.value = info.buildNumber;
    }

    onLaunch(info);
  }

  /// Called whenever the app launches.
  static void onLaunch(PackageInfo info) {}

  /// The version of the app the last time it was launched.
  static PersistentValue<String> lastVersionLaunched = PersistentValue(
    "lastVersionLaunched",
    initialValue: "0",
  );

  /// Called when the app is launched for the first time with a new version.
  static void onFirstLaunchWithVersion(PackageInfo info) async {
    final int buildNumber = int.parse(info.buildNumber);
    final int? previousBuildNumber = lastVersionLaunched.value == "0"
        ? null
        : int.parse(lastVersionLaunched.value);

    debugPrint(
        "[LAUNCH] First launch with version $buildNumber (${info.version})");

    if (buildNumber >= 26) {
      // Remove old cached files
      final Directory tempDir = await getTemporaryDirectory();
      final Directory demixerDir = Directory("${tempDir.path}/demixer");
      if (await demixerDir.exists()) await demixerDir.delete(recursive: true);

      final Directory docsDir = await getApplicationDocumentsDirectory();
      final Directory prefsDir = Directory("${docsDir.path}/song_preferences");
      if (await prefsDir.exists()) await prefsDir.delete(recursive: true);

      final File songHistory = File("${docsDir.path}/song_history.json");
      if (await songHistory.exists()) await songHistory.delete();
      final File searchHistory =
          File("${docsDir.path}/youtube_search_history.json");
      if (await searchHistory.exists()) await searchHistory.delete();
    }

    if (buildNumber >= 29) {
      // Check if the user has bought the paid version of the app (before the freemium update)
      // TODO: Remove this once all users have migrated.
      if (previousBuildNumber != null && previousBuildNumber <= 28) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showExceptionDialog(
            const FreemiumTransitionDialog(),
            barrierDismissible: false,
          );
        });
      }
    }
  }
}
