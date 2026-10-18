import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/utils/utils.dart';

void main() {
  test("JSON round-trips every field", () {
    const preferences = SongPreferences(
      position: Duration(seconds: 12),
      speed: 0.75,
      pitch: -2,
      loopStart: Duration(seconds: 5),
      loopEnd: Duration(seconds: 30),
      numEqualizerBands: 7,
      equalizerGains: {0: 1.5, 6: 0.25},
      shouldDemix: true,
      parts: {
        Part.vocals: (enabled: false, volume: 1.0),
        Part.drums: (enabled: true, volume: 0.5),
      },
    );

    final restored = SongPreferences.fromJson(
      jsonDecode(jsonEncode(preferences.toJson())) as Json,
    );

    expect(restored.toJson(), preferences.toJson());
    expect(restored.parts?[Part.drums], (enabled: true, volume: 0.5));
  });

  test("unset fields stay unset", () {
    final restored = SongPreferences.fromJson(
      jsonDecode(jsonEncode(const SongPreferences().toJson())) as Json,
    );
    expect(restored.speed, isNull);
    expect(restored.shouldDemix, isNull);
    expect(restored.parts, isNull);
  });

  test("copyWith merges gains and parts instead of replacing them", () {
    const original = SongPreferences(
      speed: 1.25,
      equalizerGains: {0: 2.0, 1: 0.5},
      parts: {Part.bass: (enabled: true, volume: 0.3)},
    );

    final updated = original.copyWith(
      equalizerGains: {1: 1.0},
      parts: {Part.vocals: (enabled: false, volume: 1.0)},
    );

    expect(updated.speed, 1.25);
    expect(updated.equalizerGains, {0: 2.0, 1: 1.0});
    expect(updated.parts, {
      Part.bass: (enabled: true, volume: 0.3),
      Part.vocals: (enabled: false, volume: 1.0),
    });
  });
}
