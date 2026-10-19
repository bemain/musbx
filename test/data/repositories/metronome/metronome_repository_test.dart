import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/repositories/metronome/metronome_repository.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockAudioEngine engine;
  late SharedPreferencesService preferences;
  late MetronomeRepository metronome;
  late Map<String, AudioSource> ticks;

  Future<MetronomeRepository> create() async {
    final repository = await MetronomeRepository.create(
      sharedPreferences: preferences,
      audioEngine: engine,
    );
    addTearDown(repository.dispose);
    return repository;
  }

  /// Advance the engine clock and let the scheduler run.
  Future<void> advanceTo(Duration time) async {
    when(engine.getEngineTime).thenReturn(time);
    when(engine.getPlayheadTime).thenReturn(time);
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  setUp(() async {
    engine = MockAudioEngine();
    ticks = {};
    when(() => engine.loadAsset(any())).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      return ticks[path.split("/").last] = MockAudioSource();
    });
    preferences = await createPreferences();
    metronome = await create();
  });

  test("bpm is clamped and survives a restart", () async {
    metronome.bpm = 1000;
    expect(metronome.bpm, MetronomeRepository.maxBpm);
    metronome.bpm = 1;
    expect(metronome.bpm, MetronomeRepository.minBpm);

    metronome
      ..bpm = 90
      ..higher = 3
      ..subdivisions = 2;
    final restarted = await create();
    expect(
      (restarted.bpm, restarted.higher, restarted.subdivisions),
      (90, 3, 2),
    );
  });

  test("schedules an accented tick, then quieter subdivisions", () {
    metronome
      ..bpm = 250
      ..subdivisions = 4
      ..resume();

    final scheduled = verify(
      () => engine.schedule(captureAny(), captureAny(), volume: 1.0),
    ).captured;
    expect(scheduled, [
      ticks["beat_accented.mp3"],
      const Duration(milliseconds: 50),
      ticks["beat_subdivision.mp3"],
      const Duration(milliseconds: 110),
      ticks["beat_subdivision.mp3"],
      const Duration(milliseconds: 170),
    ]);
  });

  test("beat follows the engine clock", () async {
    metronome
      ..bpm = 60
      ..resume();
    expect(metronome.beat, 0);

    await advanceTo(const Duration(milliseconds: 2100));
    expect(metronome.beat, 2);
    verify(
      () => engine.schedule(
        ticks["beat_primary.mp3"]!,
        const Duration(milliseconds: 3050),
        volume: 1.0,
      ),
    ).called(1);
  });

  test("changing the tempo restarts from the first beat", () async {
    metronome
      ..bpm = 60
      ..resume();
    await advanceTo(const Duration(milliseconds: 1100));
    expect(metronome.beat, 1);

    metronome.bpm = 70;
    expect(metronome.beat, 0);
    expect(metronome.isPlaying, isTrue);
  });

  test("pausing unschedules pending ticks", () {
    metronome.resume();
    metronome.pause();

    expect(metronome.isPlaying, isFalse);
    verify(() => engine.unschedule(any())).called(greaterThan(0));
  });
}
