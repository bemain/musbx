import 'package:flutter/foundation.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
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
  SupabaseService._(this._client);

  @override
  bool get isEnabled => _client != null;

  /// The supabase client used internally.
  final SupabaseClient? _client;

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
  User? get currentUser => _client?.auth.currentUser;

  /// The announcements shown to the user, and what they have read.
  ///
  /// Reads nothing when this service is [disabled], but still remembers what
  /// has been read, since that is stored on the device.
  late final AnnouncementApiService announcements = AnnouncementApiService._(
    _client?.from("announcements"),
  );

  /// What the user has told us, whether unprompted or in answer to a poll.
  ///
  /// Refuses to send anything when this service is [disabled].
  late final FeedbackApiService feedback = FeedbackApiService._(
    _client?.from("feedback"),
  );
}

/// Reads the announcements the app shows, and remembers which the user has
/// already seen.
///
/// Announcements are ordered by when they were written, and "unread" means
/// written since [readAt] — there is no per-announcement record, so marking one
/// read marks everything older read with it.
///
/// With no backend behind it every read comes back empty, which the app cannot
/// tell apart from there being nothing to announce, and does not need to.
class AnnouncementApiService {
  AnnouncementApiService._(this._table);

  final SupabaseQueryBuilder? _table;

  /// The last time the announcements were read.
  ///
  /// Everything written after this is unread, so moving it forward is how
  /// announcements are dismissed. It defaults to the moment it is first read,
  /// which means a fresh install starts with nothing unread rather than with
  /// the entire history.
  ///
  /// TODO: Move this to repository
  late final TransformedPersistentValue<DateTime, String> readAt =
      SharedPreferencesService.instance.transformed(
        "announcements/readAt",
        initialValue: DateTime.now(),
        from: (value) => DateTime.parse(value),
        to: (value) => value.toIso8601String(),
      );

  /// Get the latest announcement from the database, or null if there are none.
  Future<Announcement?> getLatest() async {
    return await _table
        ?.select()
        .order('created_at')
        .limit(1)
        .maybeSingle()
        .withConverter((d) => d == null ? null : Announcement.fromJson(d));
  }

  /// Get all announcements from the database.
  Future<List<Announcement>> getAll() async {
    if (_table == null) return [];

    return await _table
        .select()
        .order('created_at')
        .withConverter(
          (data) => data.map(Announcement.fromJson).toList(),
        );
  }

  /// Get all announcements from the database that have not been seen before.
  ///
  /// Reads [readAt] as it stands when called, so this has to be run again to
  /// pick up a change rather than being awaited once.
  Future<List<Announcement>> getUnread() async {
    if (_table == null) return [];

    return await _table
        .select()
        .gt("created_at", readAt.value.toIso8601String())
        .order('created_at')
        .withConverter(
          (data) => data.map(Announcement.fromJson).toList(),
        );
  }
}

/// Sends what the user has told us to the backend.
///
/// Write-only: nothing in the app reads feedback back, and a user cannot see or
/// withdraw what they have sent.
///
/// With no backend behind it [insert] throws rather than discarding what it was
/// given, so nobody is thanked for feedback that went nowhere.
class FeedbackApiService {
  FeedbackApiService._(this._table);

  final SupabaseQueryBuilder? _table;

  /// Insert a feedback entry in the database.
  ///
  /// Throws if the backend cannot be reached, and a [StateError] if there is no
  /// backend to reach at all. Unlike a read, this cannot quietly do nothing:
  /// the user has just chosen to send something and is about to be told it
  /// arrived, so the caller has to hear that it did not.
  Future<void> insert(FeedbackEntry value) async {
    if (_table == null) {
      throw StateError("Cannot send feedback: the backend is unavailable.");
    }
    await _table.insert(value.toJson());
  }
}
