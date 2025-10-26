import 'package:flutter/material.dart';
import 'package:musbx/utils/persistent_value.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

    if (buildNumber >= 39 && (previousBuildNumber ?? 0) < 39) {
      // Remove old settings
      await PersistentValue.preferences.clear();
      _lastVersionLaunched.value = buildNumber.toString();
    }
  }
}
