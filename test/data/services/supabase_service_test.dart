import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _row = {
  "id": "a1",
  "created_at": "2026-05-01T12:00:00.000Z",
  "title": "Poll",
};

final _session = {
  "access_token": "token",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "refresh",
  "user": {
    "id": "device",
    "aud": "authenticated",
    "created_at": "2026-05-01T12:00:00.000Z",
  },
};

void main() {
  final List<http.Request> requests = [];
  late Object? Function(http.Request request) respond;
  late SupabaseClient client;

  setUp(() {
    requests.clear();
    respond = (_) => <Object>[];
    client = SupabaseClient(
      "https://db.test",
      "key",
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path == "/auth/v1/signup") {
          return http.Response(jsonEncode(_session), 200, request: request);
        }
        return http.Response(
          jsonEncode(respond(request)),
          200,
          headers: {"content-type": "application/json"},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
  });

  group("create", () {
    test("signs in anonymously when the device has no session", () async {
      final supabase = await SupabaseService.createWith(client);

      expect(supabase.isEnabled, isTrue);
      expect(supabase.currentUser?.id, "device");
      expect(requests.single.url.path, "/auth/v1/signup");
    });

    test("keeps the session the device already has", () async {
      await SupabaseService.createWith(client);
      requests.clear();

      final supabase = await SupabaseService.createWith(client);

      expect(supabase.currentUser?.id, "device");
      expect(requests, isEmpty);
    });
  });

  group("queries", () {
    late SupabaseService supabase;

    setUp(() async {
      supabase = await SupabaseService.createWith(client);
      requests.clear();
    });

    test("getAnnouncementsAfter asks for newer rows, newest first", () async {
      respond = (_) => [_row];

      final announcements = await supabase.getAnnouncementsAfter(
        DateTime.utc(2026, 4, 1),
      );

      expect(announcements.single.id, "a1");
      final query = requests.single.url;
      expect(query.path, "/rest/v1/announcements");
      expect(
        query.queryParameters["created_at"],
        "gt.2026-04-01T00:00:00.000Z",
      );
      expect(query.queryParameters["order"], startsWith("created_at.desc"));
    });

    test("getAnnouncements reads every row", () async {
      respond = (_) => [_row, _row];

      expect(await supabase.getAnnouncements(), hasLength(2));
      expect(requests.single.url.queryParameters, isNot(contains("limit")));
    });

    test("getLatestAnnouncement reads a single row", () async {
      respond = (_) => _row;

      final latest = await supabase.getLatestAnnouncement();

      expect(latest.title, "Poll");
      expect(requests.single.url.queryParameters["limit"], "1");
    });

    test(
      "insertFeedback posts the entry with the database's columns",
      () async {
        respond = (_) => null;

        await supabase.insertFeedback(
          FeedbackEntry(content: "Hi", sentBy: "device", responseTo: "a1"),
        );

        final request = requests.single;
        expect(request.method, "POST");
        expect(request.url.path, "/rest/v1/feedback");
        expect(jsonDecode(request.body), containsPair("sent_by", "device"));
      },
    );
  });

  group("disabled", () {
    final disabled = SupabaseService.disabled();

    test("is not enabled", () => expect(disabled.isEnabled, isFalse));

    test("throws from everything that needs the backend", () {
      expect(() => disabled.currentUser, throwsA(isA<ServiceDisabled>()));
      expect(disabled.getAnnouncements(), throwsA(isA<ServiceDisabled>()));
      expect(
        disabled.insertFeedback(FeedbackEntry(content: "x", sentBy: null)),
        throwsA(isA<ServiceDisabled>()),
      );
    });
  });
}
