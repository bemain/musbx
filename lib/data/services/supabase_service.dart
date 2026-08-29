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
/// Only the tables the app actually uses are reachable, through
/// [announcements] and [feedback], rather than the client being handed out.
///
/// Nothing here is essential, so reaching the backend is allowed to fail:
/// [disabled] returns a service that behaves as though the backend held no
/// announcements and refuses to send feedback. Callers do not have to check
/// [isEnabled] first — see each method for what it does when disabled.
class SupabaseService extends OptionalService {
  SupabaseService._(this.__client);

  @override
  bool get isEnabled => __client != null;

  final SupabaseClient? __client;

  /// The supabase client used internally.
  SupabaseClient get _client {
    throwIfDisabled();
    return __client!;
  }

  /// Create the service, signing in anonymously if this device has no session.
  ///
  /// Performs network requests, and throws if the backend cannot be reached —
  /// which on a device that is offline at launch is the ordinary case, so
  /// callers are expected to fall back to [disabled] rather than propagate it.
  ///
  /// Supplying a [client] skips initializing the plugin along with it, so a
  /// test needs neither the real configuration nor a network.
  static Future<SupabaseService> create({
    SupabaseClient? client,
  }) async {
    if (client == null) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
    }
    final c = client ?? Supabase.instance.client;

    if (c.auth.currentSession == null) {
      await c.auth.signInAnonymously();
    }

    return SupabaseService._(c);
  }

  /// A service with no backend behind it, for when it could not be reached.
  static SupabaseService disabled() => SupabaseService._(null);

  // TODO: Remove once we introduce `provider`.
  // If signInAnonymously() throws — no connectivity at launch, Supabase briefly
  // unreachable — this installs disabled() permanently. Feedback submission
  // then throws StateError for the rest of the process lifetime, even once the
  // network comes back, and the only recovery is a full app restart.
  //
  // Since launch-time connectivity is genuinely unreliable on mobile, the
  // sign-in is better attempted lazily on first use, or retried, rather than
  // latched off after one failure.
  static late final SupabaseService instance;
  static Future<void> initialize() async {
    try {
      instance = await create();
    } catch (error) {
      debugPrint("[SUPABASE] Disabled, initialization failed: $error");
      instance = disabled();
    }
  }

  /// Who the backend takes this device to be, or `null` if there is no session
  /// to speak of, including when this service is [disabled].
  ///
  /// Identifies a device rather than a person, so it is only meaningful for
  /// telling one sender of feedback from another.
  User? get currentUser => _client.auth.currentUser;

  late final SupabaseQueryBuilder _announcements = _client.from(
    "announcements",
  );

  /// Get the latest announcement from the database.
  Future<Announcement> getLatestAnnouncement() async {
    return await _announcements
        .select()
        .order('created_at')
        .limit(1)
        .single()
        .withConverter(Announcement.fromJson);
  }

  /// Get all announcements from the database.
  Future<List<Announcement>> getAnnouncements() async {
    return await _announcements
        .select()
        .order('created_at')
        .withConverter(
          (data) => data.map(Announcement.fromJson).toList(),
        );
  }

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
  /// Throws if the backend cannot be reached, and a [StateError] if there is no
  /// backend to reach at all. Unlike a read, this cannot quietly do nothing:
  /// the user has just chosen to send something and is about to be told it
  /// arrived, so the caller has to hear that it did not.
  Future<void> insertFeedback(FeedbackEntry value) async {
    await _feedback.insert(value.toJson());
  }
}
