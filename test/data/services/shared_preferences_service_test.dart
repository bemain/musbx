import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fixtures.dart';

void main() {
  late SharedPreferencesService preferences;
  setUp(() async => preferences = await createPreferences());

  group("value", () {
    test("reads the initial value until something is stored", () {
      final value = preferences.value("count", initialValue: 3);
      expect(value.value, 3);

      value.value = 5;
      expect(value.value, 5);
      expect(preferences.value("count", initialValue: 3).value, 5);
    });

    test("notifies only on change", () {
      final value = preferences.value("flag", initialValue: false);
      var notifications = 0;
      value.addListener(() => notifications++);

      value.value = true;
      value.value = true;
      expect(notifications, 1);
    });

    test("stores a copy of lists", () {
      final value = preferences.value<List<String>>("list", initialValue: []);
      final list = ["a"];
      value.value = list;
      list.add("b");
      expect(value.value, ["a"]);
    }, skip: "Bug: SharedPreferencesWithCache keeps a reference to the list");

    test("rejects types that cannot be stored", () {
      expect(
        () => preferences.value("date", initialValue: DateTime(2000)),
        throwsArgumentError,
      );
    });
  });

  test("transformed converts on the way in and out", () {
    TransformedPersistentValue<Duration, int> handle() =>
        preferences.transformed(
          "duration",
          initialValue: Duration.zero,
          to: (d) => d.inSeconds,
          from: (s) => Duration(seconds: s),
        );

    handle().value = const Duration(minutes: 2);
    expect(handle().value, const Duration(minutes: 2));
    expect(preferences.value("duration", initialValue: 0).value, 120);
  });

  test("remove falls back to the initial value", () async {
    preferences.value("count", initialValue: 0).value = 9;
    await preferences.remove("count");
    expect(preferences.value("count", initialValue: 0).value, 0);
  });

  test("clear only removes the app's own keys", () async {
    preferences = await createPreferences({"flutter.plugin": "keep"});
    preferences.value("count", initialValue: 0).value = 9;

    await preferences.clear();

    expect(preferences.value("count", initialValue: 0).value, 0);
    expect(await SharedPreferencesAsync().getString("flutter.plugin"), "keep");
  });

  group("migration", () {
    test("moves legacy keys under the prefix", () async {
      preferences = await createPreferences({
        "metronome/bpm": 120,
        "currentBranch": "beta",
        "drone/intervals": ["0", "7"],
      });

      expect(preferences.value("metronome/bpm", initialValue: 0).value, 120);
      expect(
        preferences.value("currentBranch", initialValue: "").value,
        "beta",
      );
      expect(
        preferences
            .value<List<String>>("drone/intervals", initialValue: [])
            .value,
        ["0", "7"],
      );
      expect(
        await SharedPreferencesAsync().getKeys(),
        {
          "musbx/metronome/bpm",
          "musbx/currentBranch",
          "musbx/drone/intervals",
        },
      );
    });

    test("leaves plugin keys and already migrated values alone", () async {
      preferences = await createPreferences({
        "flutter.plugin": true,
        "metronome/bpm": 60,
        "musbx/metronome/bpm": 90,
      });

      expect(preferences.value("metronome/bpm", initialValue: 0).value, 90);
      expect(await SharedPreferencesAsync().getBool("flutter.plugin"), isTrue);
    });
  });
}
