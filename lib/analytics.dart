import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:musbx/firebase_options.dart';

class Analytics {
  /// Whether Firebase Analytics is available on the current platform.
  static late final bool isAvailable;

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
