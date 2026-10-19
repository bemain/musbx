import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/models/sound_group.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/domain/models/part.dart';

import '../../helpers/mocks.dart';

class MockSoLoud extends Mock implements SoLoud {
  @override
  void setInaudibleBehavior(SoundHandle handle, bool mustTick, bool kill) =>
      super.noSuchMethod(
        Invocation.method(#setInaudibleBehavior, [handle, mustTick, kill]),
      );
}

/// Covers what goes through [SoLoud] alone; the filters behind pitch and
/// equalizer need the native engine.
void main() {
  setUpAll(registerFallbacks);

  late MockSoLoud soLoud;
  late AudioEngineService engine;

  setUp(() async {
    soLoud = MockSoLoud();
    when(
      () => soLoud.init(bufferSize: any(named: "bufferSize")),
    ).thenAnswer((_) async {});
    when(() => soLoud.stop(any())).thenAnswer((_) async {});
    when(() => soLoud.disposeSource(any())).thenAnswer((_) async {});
    when(soLoud.createVoiceGroup).thenReturn(const SoundHandle(100));

    engine = await AudioEngineService.createWith(soLoud);
  });

  SongPartsGroup song() => SongPartsGroup(
    parts: [null, Part.values.first],
    sources: [MockAudioSource(), MockAudioSource()],
    handles: const [SoundHandle(1), SoundHandle(2)],
    groupHandle: const SoundHandle(100),
  );

  test("create initializes the engine with a small buffer", () {
    verify(() => soLoud.init(bufferSize: 512));
  });

  test("stop ends every voice before freeing its source", () async {
    final sound = song();

    await engine.stop(sound);

    verifyInOrder([
      () => soLoud.stop(const SoundHandle(1)),
      () => soLoud.stop(const SoundHandle(2)),
      () => soLoud.disposeSource(sound.sources[0]),
      () => soLoud.disposeSource(sound.sources[1]),
      () => soLoud.destroyVoiceGroup(const SoundHandle(100)),
    ]);
  });

  test("pause, resume and speed act on the whole group", () {
    final sound = song();

    engine.pause(sound);
    engine.resume(sound);
    engine.setSpeed(sound, 0.5);

    verifyInOrder([
      () => soLoud.setPause(const SoundHandle(100), true),
      () => soLoud.setPause(const SoundHandle(100), false),
      () => soLoud.setRelativePlaySpeed(const SoundHandle(100), 0.5),
    ]);
  });

  test("seek moves every part", () {
    engine.seek(song(), const Duration(seconds: 3));

    verify(
      () => soLoud.seek(const SoundHandle(1), const Duration(seconds: 3)),
    );
    verify(
      () => soLoud.seek(const SoundHandle(2), const Duration(seconds: 3)),
    );
  });

  group("part volume", () {
    test("reaches the voice of that part", () {
      when(() => soLoud.getVolume(const SoundHandle(2))).thenReturn(0.25);
      final sound = song();

      engine.setPartVolume(sound, Part.values.first, 0.5);

      verify(() => soLoud.setVolume(const SoundHandle(2), 0.5));
      expect(engine.getPartVolume(sound, Part.values.first), 0.25);
    });

    test("of a part the song lacks is ignored", () {
      final sound = song();
      final missing = Part.values.last;

      engine.setPartVolume(sound, missing, 0.5);

      expect(engine.getPartVolume(sound, missing), isNull);
      verifyNever(() => soLoud.setVolume(any(), any()));
    });
  });

  test("schedule plays once at a time on the engine's clock", () {
    final source = MockAudioSource();
    when(
      () => soLoud.playScheduled(
        source,
        const Duration(seconds: 2),
        volume: 0.8,
      ),
    ).thenReturn(const SoundHandle(7));

    expect(
      engine.schedule(source, const Duration(seconds: 2), volume: 0.8),
      const SoundHandle(7),
    );
  });

  group("tones", () {
    setUp(() {
      when(
        () => soLoud.loadWaveform(any(), any(), any(), any()),
      ).thenAnswer((_) async => MockAudioSource());
      var next = 1;
      when(
        () => soLoud.play(any(), paused: true),
      ).thenAnswer((_) => SoundHandle(next++));
    });

    test("createTones fails when no voice group can be made", () {
      when(soLoud.createVoiceGroup).thenReturn(-1 as SoundHandle);
      expect(engine.createTones, throwsA(isA<Exception>()));
    });

    test("setTones adds a paused tone per frequency", () async {
      final tones = await engine.setTones(
        engine.createTones(),
        [220, 330],
        WaveForm.sin,
      );

      expect(tones.handles, const [SoundHandle(1), SoundHandle(2)]);
      expect(tones.groupHandle, const SoundHandle(100));
      verify(
        () => soLoud.addVoicesToGroup(const SoundHandle(100), any()),
      ).called(2);
      verify(() => soLoud.setWaveformFreq(tones.sources[0], 220));
      verify(() => soLoud.setWaveformFreq(tones.sources[1], 330));
    });

    test("setTones removes tones beyond the frequencies", () async {
      final three = await engine.setTones(
        engine.createTones(),
        [220, 330, 440],
        WaveForm.sin,
      );

      final one = await engine.setTones(three, [110], WaveForm.square);

      expect(one.handles, const [SoundHandle(1)]);
      verify(() => soLoud.stop(const SoundHandle(3)));
      verify(() => soLoud.stop(const SoundHandle(2)));
      verify(() => soLoud.disposeSource(three.sources[2]));
      verify(() => soLoud.setWaveform(one.sources[0], WaveForm.square));
      verify(() => soLoud.setWaveformFreq(one.sources[0], 110));
      expect(three.handles, hasLength(3));
    });
  });
}
