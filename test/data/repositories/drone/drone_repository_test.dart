import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/repositories/drone/drone_repository.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/music/pitch.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockAudioEngine engine;
  late SharedPreferencesService preferences;
  late DroneRepository drone;

  DroneRepository create() {
    final repository = DroneRepository(
      audioEngine: engine,
      sharedPreferences: preferences,
    );
    addTearDown(repository.dispose);
    return repository;
  }

  /// The frequencies most recently handed to the audio engine.
  Future<List<double>> soundingFrequencies() async {
    await pumpEventQueue();
    return verify(
          () => engine.setTones(any(), captureAny(), any()),
        ).captured.last
        as List<double>;
  }

  setUp(() async {
    engine = MockAudioEngine();
    preferences = await createPreferences();
    drone = create();
  });

  test("the root defaults to A3", () {
    expect(drone.root.abbreviation, "A3");
    expect(drone.root.frequency, closeTo(220, 1e-9));
  });

  test("sounds each interval above the root", () async {
    drone.intervals = {0, 7};
    expect(drone.pitches.map((p) => p.abbreviation), ["A3", "E4"]);
    expect(await soundingFrequencies(), [
      closeTo(220, 0.01),
      closeTo(329.63, 0.01),
    ]);
  });

  test("the root is clamped between C2 and B5", () {
    drone.root = Pitch.parse("C1@32.7Hz");
    expect(drone.root.abbreviation, "C2");
    drone.root = Pitch.parse("C7@2093Hz");
    expect(drone.root.abbreviation, "B5");
  });

  test("the root stays on its note when the tuning changes", () async {
    drone.intervals = {0};
    drone.tuning = const Pitch(PitchClass.a(), 4, 442);

    expect(drone.root.abbreviation, "A3");
    expect(await soundingFrequencies(), [closeTo(221, 0.01)]);
  });

  test("adding and removing intervals", () {
    drone
      ..addInterval(4)
      ..addInterval(7)
      ..addInterval(4)
      ..removeInterval(7);
    expect(drone.intervals, {4});
  });

  test("tuning, waveform, root and intervals survive a restart", () {
    drone
      ..tuning = const Pitch(PitchClass.a(), 4, 432)
      ..waveform = WaveForm.square
      ..root = Pitch.parse("D3@146.83Hz")
      ..intervals = {0, 4};

    final restarted = create();
    expect(restarted.tuning.frequency, 432);
    expect(restarted.waveform, WaveForm.square);
    expect(restarted.root.abbreviation, "D3");
    expect(restarted.intervals, {0, 4});
  });

  test("an unknown stored waveform falls back to sine", () async {
    preferences = await createPreferences({"musbx/drone/waveform": "noise"});
    expect(create().waveform, WaveForm.sin);
  });

  test("emptying the intervals pauses the drone", () async {
    drone.intervals = {0};
    await pumpEventQueue();
    drone.resume();
    expect(drone.isPlaying, isTrue);

    drone.intervals = {};
    await pumpEventQueue();
    expect(drone.isPlaying, isFalse);
  });
}
