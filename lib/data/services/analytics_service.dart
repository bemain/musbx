import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/firebase_options.dart';

/// Reports how the app is used to Firebase Analytics.
///
/// Analytics is optional. [disabled] returns a service that accepts every call
/// and reports nothing, so callers never have to ask whether analytics is
/// available before logging.
class AnalyticsService extends OptionalService {
  AnalyticsService._(this._firebase);

  /// The Firebase handle, or `null` when this service is [disabled].
  final FirebaseAnalytics? _firebase;

  @override
  bool get isEnabled => _firebase != null;

  /// Create the service, initializing Firebase with [options] or the options
  /// generated for the current platform.
  ///
  /// Returns a [disabled] if the platform lacks a Firebase configuration.
  /// Throws if initialization fails anywhere else; since analytics is optional,
  /// callers should fall back to [disabled] rather than propagate that.
  static Future<AnalyticsService> create({FirebaseOptions? options}) async {
    if (Platform.isLinux) return disabled();

    // TODO: Move this to a composition root
    await Firebase.initializeApp(
      options: options ?? DefaultFirebaseOptions.currentPlatform,
    );

    return AnalyticsService._(FirebaseAnalytics.instance);
  }

  /// A service that discards everything logged to it, for when analytics is
  /// unavailable or switched off.
  static AnalyticsService disabled() => AnalyticsService._(null);

  // TODO: Remove once we introduce `provider`.
  static late final AnalyticsService instance;
  static Future<void> initialize() async {
    try {
      instance = await create();
    } catch (error) {
      debugPrint("[ANALYTICS] Disabled, initialization failed: $error");
      instance = disabled();
    }
  }

  /// Log that the current screen has changed.
  ///
  /// Does nothing when this service is [disabled].
  Future<void> logScreenView(String name) async {
    await _firebase?.logScreenView(screenName: name);
  }
}
