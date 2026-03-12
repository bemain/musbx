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
    isInitialized = true;

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// The reference to the 'announcements' table.
  static final SupabaseQueryBuilder announcements = Database.client.from(
    "announcements",
  );
}
