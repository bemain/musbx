import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';
import 'package:musbx/data/repositories/feedback/feedback_repository_remote.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  setUpAll(
    () => registerFallbackValue(FeedbackEntry(content: "", sentBy: null)),
  );

  late MockSupabaseService supabase;
  late SharedPreferencesService preferences;
  final poll = Announcement(id: "poll", title: "Poll");

  FeedbackRepositoryRemote create([SupabaseService? service]) =>
      FeedbackRepositoryRemote(
        sharedPreferences: preferences,
        supabase: loaderOf(
          service ?? supabase,
          fallback: SupabaseService.disabled,
        ),
      );

  setUp(() async {
    supabase = MockSupabaseService();
    preferences = await createPreferences();
    when(() => supabase.insertFeedback(any())).thenAnswer((_) async {});
  });

  test("insert sends the content", () async {
    await create().insert("Great app").then((r) => r.asOk);

    final sent =
        verify(() => supabase.insertFeedback(captureAny())).captured.single
            as FeedbackEntry;
    expect(sent.content, "Great app");
    expect(sent.responseTo, isNull);
  });

  test("responses are sent and remembered across restarts", () async {
    await create().respond(poll, "Yes").then((r) => r.asOk);
    await create().respond(poll, "Also no").then((r) => r.asOk);

    final sent = verify(
      () => supabase.insertFeedback(captureAny()),
    ).captured.cast<FeedbackEntry>();
    expect(sent.map((e) => e.responseTo), ["poll", "poll"]);
    expect(create().responses(poll), ["Yes", "Also no"]);
  });

  test("a response that fails to send is not remembered", () async {
    when(() => supabase.insertFeedback(any())).thenThrow(Exception("offline"));

    expect(await create().respond(poll, "Yes"), isA<Failure<void>>());
    expect(create().responses(poll), isEmpty);
  });

  test("a disabled backend reports Unavailable", () async {
    final feedback = create(SupabaseService.disabled());
    expect(await feedback.insert("x"), isA<Unavailable<void>>());
  });
}
