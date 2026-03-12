import 'package:musbx/database/announcement.dart';
import 'package:musbx/database/model.dart';
import 'package:musbx/keys.dart';
import 'package:musbx/utils/utils.dart';
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
  static final DatabaseService<Announcement> announcements =
      DatabaseService<Announcement>(
        "announcements",
        fromJson: Announcement.fromJson,
      );
}

class DatabaseService<T extends Model> {
  DatabaseService(
    String table, {
    required this.fromJson,
  }) : table = Database.client.from(table);

  final SupabaseQueryBuilder table;

  final T Function(Json json) fromJson;

  /// Perform an INSERT into the [table].
  PostgrestFilterBuilder<dynamic> insert(T object) {
    return table.insert(object.toJson());
  }

  PostgrestBuilder<List<T>, List<T>, List<Json>> select() {
    return table.select().withConverter(
      (data) => data.map(fromJson).toList(),
    );
  }
}
