import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/data/models/announcement/announcement.dart';
import 'package:musbx/data/models/feedback/feedback_entry.dart';

void main() {
  test("reads an announcement row from the database", () {
    final announcement = Announcement.fromJson({
      "id": "a1",
      "created_at": "2026-05-01T12:00:00.000Z",
      "title": "Poll",
      "content": "Which?",
      "responses": {
        "allow_multiple": true,
        "responses": ["A", "B"],
      },
    });

    expect(announcement.id, "a1");
    expect(announcement.createdAt, DateTime.utc(2026, 5, 1, 12));
    expect(announcement.popup, isFalse);
    expect(announcement.responses?.allowMultiple, isTrue);
    expect(announcement.responses?.showOther, isFalse);
    expect(announcement.responses?.responses, ["A", "B"]);
  });

  test("a row without an id is rejected", () {
    expect(
      () => Announcement.fromJson({
        "created_at": "2026-05-01T12:00:00.000Z",
        "title": "x",
      }),
      throwsA(isA<MissingRequiredKeysException>()),
    );
  });

  test("feedback is written with the database's column names", () {
    final json = FeedbackEntry(
      content: "Hi",
      sentBy: "user",
      responseTo: "a1",
    ).toJson();

    expect(json["sent_by"], "user");
    expect(json["response_to"], "a1");
    expect(json["id"], isA<String>());
  });
}
