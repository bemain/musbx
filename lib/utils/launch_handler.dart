import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/utils/persistent_value.dart';
import 'package:musbx/widgets/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class LaunchHandler {
  static bool initialized = false;

  static Future<void> initialize() async {
    if (initialized) return;
    initialized = true;

    try {
      info = await PackageInfo.fromPlatform();

      buildNumber = int.parse(info.buildNumber);
      previousBuildNumber = _lastVersionLaunched.value == "0"
          ? null
          : int.tryParse(_lastVersionLaunched.value);
      _lastVersionLaunched.value = info.buildNumber;

      if (buildNumber != previousBuildNumber) {
        await onFirstLaunchWithVersion();
      }

      await onLaunch();
    } catch (e) {
      debugPrint("[LAUNCH] Error occured during launch: $e");
    }
  }

  /// Application metadata.
  static late PackageInfo info;

  /// The current build number of the app.
  static late int buildNumber;

  /// The build number of the app the last time it was launched.
  static late int? previousBuildNumber;

  /// The version of the app the last time it was launched.
  static final PersistentValue<String> _lastVersionLaunched = PersistentValue(
    "lastVersionLaunched",
    initialValue: "0",
  );

  /// Called whenever the app launches.
  static Future<void> onLaunch() async {}

  /// Called when the app is launched for the first time with a new version.
  static Future<void> onFirstLaunchWithVersion() async {
    debugPrint(
      "[LAUNCH] First launch with version $buildNumber (${info.version})",
    );

    if (buildNumber == 38) {
      // Remove all cached songs
      final file = File(
        "${(await getTemporaryDirectory()).path}/song_history.json",
      );
      if (await file.exists()) await file.delete();
      final dir = Directories.applicationDocumentsDir("songs");
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }
}
