import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/repositories/announcement/announcement_repository_remote.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2000)));

  late MockSupabaseService supabase;
  late SharedPreferencesService preferences;

  AnnouncementRepositoryRemote create([SupabaseService? service]) =>
      AnnouncementRepositoryRemote(
        sharedPreferences: preferences,
        supabase: ServiceLoader(
          create: () async => service ?? supabase,
          fallback: SupabaseService.disabled,
        ),
      );

  setUp(() async {
    supabase = MockSupabaseService();
    preferences = await createPreferences();
    when(() => supabase.isEnabled).thenReturn(true);
  });

  test("markRead moves readAt forward, across restarts", () {
    final announcements = create();
    var notifications = 0;
    announcements.addListener(() => notifications++);

    final readAt = DateTime(2026, 5, 1, 12);
    announcements.markRead(readAt);

    expect(notifications, 1);
    expect(create().readAt, readAt);
  });

  test("getUnread asks for what was published after readAt", () async {
    final readAt = DateTime(2026, 5, 1);
    final unread = [Announcement(title: "New")];
    when(
      () => supabase.getAnnouncementsAfter(readAt),
    ).thenAnswer((_) async => unread);

    final announcements = create()..markRead(readAt);

    expect((await announcements.getUnread()).asOk, unread);
  });

  test("a disabled backend reports Unavailable", () async {
    final announcements = create(SupabaseService.disabled());
    expect(await announcements.getLatest(), isA<Unavailable<Announcement>>());
    expect(await announcements.getUnread(), isA<Unavailable<Object?>>());
  });
}
