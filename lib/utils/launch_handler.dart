import 'package:flutter/material.dart';
import 'package:musbx/utils/persistent_value.dart';
import 'package:musbx/widgets/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LaunchHandler {
  static bool initialized = false;

  static Future<void> initialize() async {
    if (initialized) return;
    initialized = true;

    final PackageInfo info = await PackageInfo.fromPlatform();

    if (info.buildNumber != lastVersionLaunched.value) {
      await onFirstLaunchWithVersion(info);
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
  static Future<void> onFirstLaunchWithVersion(PackageInfo info) async {
    final int buildNumber = int.parse(info.buildNumber);
    final int? previousBuildNumber = lastVersionLaunched.value == "0"
        ? null
        : int.parse(lastVersionLaunched.value);

    debugPrint(
      "[LAUNCH] First launch with version $buildNumber (${info.version})",
    );

    if (buildNumber >= 35 &&
        previousBuildNumber != null &&
        previousBuildNumber < 35) {
      // Remove all cached songs
      await Directories.applicationDocumentsDir("songs").delete();
    }
  }
}
