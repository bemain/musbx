import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:musbx/firebase_options.dart';

class Analytics {
  Analytics._();

  /// Whether Firebase Analytics is available on the current platform.
  static late final bool isAvailable;

  /// Log that the current screen has changed.
  static Future<void> logScreenView(String? name) async {
    await FirebaseAnalytics.instance.logScreenView(screenName: name);
  }

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isAvailable = true;
    } catch (e) {
      debugPrint("[FIREBASE] Failed to initialize; $e");
      isAvailable = false;
    }
  }
}
