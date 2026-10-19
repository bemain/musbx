import 'package:flutter/foundation.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reaches the backend the app stores announcements and feedback in.
///
/// The user is signed in anonymously, which is what gives feedback a stable
/// author without ever asking anyone to make an account. That identity lives on
/// the device: signing in from another one, or clearing the app's data, makes
/// the user someone else as far as the backend is concerned.
///
/// Only the queries the app actually needs are exposed, rather than the client
/// being handed out.
///
/// Nothing here is essential, so reaching the backend is allowed to fail:
/// [disabled] returns a service with no client behind it.
class SupabaseService extends OptionalService {
  SupabaseService._(this.__client);

  /// The Supabase client, or `null` when this service is [disabled].
  final SupabaseClient? __client;

  SupabaseClient get _client {
    throwIfDisabled();
    return __client!;
  }

  @override
  bool get isEnabled => __client != null;

  /// Create the service, signing in anonymously if this device has no session.
  ///
  /// Performs network requests, and throws if the backend cannot be reached —
  /// which on a device that is offline at launch is the ordinary case, so
  /// callers are expected to fall back to [disabled] rather than propagate it.
  static Future<SupabaseService> create() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    return createWith(Supabase.instance.client);
  }

  /// Create the service over [client], signing in anonymously if it has no
  /// session.
  ///
  /// Skips initializing the plugin, so a test needs neither the real
  /// configuration nor a network.
  @visibleForTesting
  static Future<SupabaseService> createWith(SupabaseClient client) async {
    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }

    return SupabaseService._(client);
  }

  /// A service with no backend behind it, for when it could not be reached.
  static SupabaseService disabled() => SupabaseService._(null);

  /// Who the backend takes this device to be, or `null` if there is no session
  /// to speak of.
  ///
  /// Identifies a device rather than a person, so it is only meaningful for
  /// telling one sender of feedback from another.
  ///
  /// Throws [ServiceDisabled] when this service is [disabled].
  User? get currentUser => _client.auth.currentUser;

  late final SupabaseQueryBuilder _announcements = _client.from(
    "announcements",
  );

  /// Get the latest announcement from the database.
  ///
  /// Throws [ServiceDisabled] when this service is [disabled], as does every
  /// query below.
  Future<Announcement> getLatestAnnouncement() async {
    return await _announcements
        .select()
        .order('created_at')
        .limit(1)
        .single()
        .withConverter(Announcement.fromJson);
  }

  /// Get all announcements from the database, newest first.
  Future<List<Announcement>> getAnnouncements() async {
    return await _announcements
        .select()
        .order('created_at')
        .withConverter(
          (data) => data.map(Announcement.fromJson).toList(),
        );
  }

  /// Get the announcements published after [date], newest first.
  Future<List<Announcement>> getAnnouncementsAfter(DateTime date) async {
    return await _announcements
        .select()
        .gt("created_at", date.toIso8601String())
        .order('created_at')
        .withConverter(
          (data) => data.map(Announcement.fromJson).toList(),
        );
  }

  late final SupabaseQueryBuilder _feedback = _client.from("feedback");

  /// Insert a feedback entry in the database.
  ///
  /// Throws if the backend cannot be reached, and [ServiceDisabled] if there is
  /// no backend to reach at all. Unlike a read, this cannot quietly do nothing:
  /// the user has just chosen to send something and is about to be told it
  /// arrived, so the caller has to hear that it did not.
  Future<void> insertFeedback(FeedbackEntry value) async {
    await _feedback.insert(value.toJson());
  }
}
