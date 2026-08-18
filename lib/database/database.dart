import 'package:flutter/material.dart';
import 'package:musbx/keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Database {
  Database._();

  /// The supabase client used internally.
  static final SupabaseClient client = Supabase.instance.client;

  /// Whether the database has been [initialize]d.
  static bool isInitialized = false;

  /// Initialize the database connection.
  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );

      if (client.auth.currentSession != null) {
        await client.auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint("[DATABASE] Failed to initialize; $e");
    } finally {
      isInitialized = true;
    }
  }

  /// The reference to the 'announcements' table.
  static final SupabaseQueryBuilder announcements = Database.client.from(
    "announcements",
  );

  /// The reference to the 'feedback' table.
  static final SupabaseQueryBuilder feedback = Database.client.from(
    "feedback",
  );
}
