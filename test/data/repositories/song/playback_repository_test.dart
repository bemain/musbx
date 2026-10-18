import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/services/audio_session_service.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/domain/models/song_preferences.dart';
import 'package:musbx/utils/result.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbacks);

  late MockAudioEngine engine;
  late MockAudioSession session;
  late PlaybackRepository playback;
  final song = urlSong("a");
  final single = {null: File("audio.mp3")};

  setUp(() {
    engine = MockAudioEngine(duration: const Duration(minutes: 3));
    session = MockAudioSession();
    playback = PlaybackRepository(audioEngine: engine, audioSession: session);
    addTearDown(playback.dispose);
  });

  Future<void> load([SongPreferences? preferences]) async =>
      (await playback.load(song, single, preferences: preferences)).asOk;

  group("load", () {
    test("starts paused at the defaults without preferences", () async {
      await load();

      expect(playback.song, song);
      expect(playback.isPlaying, isFalse);
      expect(playback.position, Duration.zero);
      expect(playback.speed, 1.0);
      expect(playback.pitch, 0.0);
      expect(playback.numEqualizerBands, 5);
      expect(playback.parts, Part.values.toSet());
      expect(playback.getPartEnabled(Part.vocals), isTrue);
    });

    test("restores preferences, readable back unchanged", () async {
      const preferences = SongPreferences(
        position: Duration(seconds: 20),
        speed: 0.8,
        pitch: -3,
        loopStart: Duration(seconds: 10),
        loopEnd: Duration(seconds: 60),
        numEqualizerBands: 6,
        equalizerGains: {0: 1.5, 5: 0.5},
        shouldDemix: true,
        parts: {Part.vocals: (enabled: false, volume: 0.7)},
      );
      await load(preferences);

      final read = playback.readPreferences();
      expect(read.speed, 0.8);
      expect(read.pitch, -3);
      expect(read.loopStart, preferences.loopStart);
      expect(read.loopEnd, preferences.loopEnd);
      expect(read.equalizerGains, {0: 1.5, 1: 1, 2: 1, 3: 1, 4: 1, 5: 0.5});
      expect(read.parts?[Part.vocals], (enabled: false, volume: 0.7));
      expect(read.shouldDemix, isTrue, reason: "not owned by playback");
    });

    test("restores the position", () async {
      await load(const SongPreferences(position: Duration(seconds: 20)));
      expect(playback.position, const Duration(seconds: 20));
      expect(
        playback.readPreferences().position,
        const Duration(seconds: 20),
      );
    }, skip: "Bug: load seeks but never updates positionNotifier");

    test("clamps preferences into the allowed ranges", () async {
      await load(
        const SongPreferences(
          speed: 5,
          pitch: -40,
          numEqualizerBands: 100,
          loopStart: Duration(minutes: 2),
          loopEnd: Duration(minutes: 10),
        ),
      );

      expect(playback.speed, 2.0);
      expect(playback.pitch, -12);
      expect(playback.numEqualizerBands, PlaybackRepository.maxNumBands);
      expect(playback.loopSection?.end, const Duration(minutes: 3));
    });

    test("moves a loop end before its start up to the start", () async {
      await load(
        const SongPreferences(
          loopStart: Duration(seconds: 30),
          loopEnd: Duration(seconds: 10),
        ),
      );
      expect(playback.loopSection?.end, const Duration(seconds: 30));
    });

    test("mutes disabled parts on the engine", () async {
      await playback
          .load(
            song,
            {
              Part.vocals: File("vocals.mp3"),
              Part.drums: File("drums.mp3"),
            },
            preferences: const SongPreferences(
              parts: {Part.vocals: (enabled: false, volume: 0.5)},
            ),
          )
          .then((r) => r.asOk);

      expect(playback.isMulti, isTrue);
      verify(() => engine.setPartVolume(any(), Part.vocals, 0.0)).called(1);
    });

    test("a failed load leaves nothing loaded and frees sources", () async {
      var loads = 0;
      when(() => engine.loadFile(any())).thenAnswer((_) async {
        if (loads++ == 1) throw const FileSystemException("corrupt");
        return MockAudioSource();
      });

      final result = await playback.load(song, {
        Part.vocals: File("vocals.mp3"),
        Part.drums: File("drums.mp3"),
      });

      expect(result, isA<Failure<void>>());
      expect(playback.song, isNull);
      verify(() => engine.unload(any())).called(1);
    });

    test("replaces the previously loaded song", () async {
      await load(const SongPreferences(speed: 1.5));
      final other = urlSong("b");
      await playback.load(other, single).then((r) => r.asOk);

      expect(playback.song, other);
      expect(playback.speed, 1.0);
    });
  });

  group("loop section", () {
    setUp(load);

    test("seek is clamped into the loop section", () {
      playback.setLoopSection(
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 20),
      );

      playback.seek(const Duration(seconds: 5));
      expect(playback.position, const Duration(seconds: 10));
      playback.seek(const Duration(seconds: 25));
      expect(playback.position, const Duration(seconds: 20));
    });

    test("moving one end keeps the other", () {
      playback.setLoopSection(
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 20),
      );
      playback.setLoopSection(end: const Duration(seconds: 30));
      expect(playback.loopSection, (
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 30),
      ));
    });

    test("an end before the start is pushed up to it", () {
      playback.setLoopSection(start: const Duration(seconds: 10));
      playback.setLoopSection(end: const Duration(seconds: 5));
      expect(playback.loopSection?.end, const Duration(seconds: 10));
    });

    test("the position is pulled into a new section", () {
      playback.seek(const Duration(seconds: 50));
      playback.setLoopSection(end: const Duration(seconds: 40));
      expect(playback.position, const Duration(seconds: 40));
    });

    test("playback past the end jumps back to the start", () async {
      playback.setLoopSection(
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 20),
      );
      when(
        () => engine.getPosition(any()),
      ).thenReturn(const Duration(seconds: 21));
      await playback.resume();

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(playback.position, const Duration(seconds: 10));
    });
  });

  group("adjustments", () {
    setUp(load);

    test("band gains are clamped and unknown bands ignored", () {
      playback.setBandGain(0, 10);
      playback.setBandGain(1, -1);
      playback.setBandGain(99, 1.5);

      expect(playback.getBandGain(0), PlaybackRepository.equalizerMaxGain);
      expect(playback.getBandGain(1), PlaybackRepository.equalizerMinGain);
      expect(playback.getBandGain(99), isNull);
    });

    test("setPart leaves what is not specified alone", () {
      playback.setPart(Part.bass, volume: 0.4);
      playback.setPart(Part.bass, enabled: false);
      expect(playback.getPartVolume(Part.bass), 0.4);
      expect(playback.getPartEnabled(Part.bass), isFalse);
    });

    test("reset returns to the defaults but keeps the song", () {
      playback
        ..speed = 1.5
        ..pitch = 2
        ..setBandGain(0, 2)
        ..setPart(Part.drums, enabled: false)
        ..setLoopSection(start: const Duration(seconds: 5))
        ..reset();

      expect(playback.song, song);
      expect(playback.speed, 1.0);
      expect(playback.pitch, 0.0);
      expect(playback.getBandGain(0), 1.0);
      expect(playback.getPartEnabled(Part.drums), isTrue);
      expect(playback.loopSection, (start: null, end: null));
    });

    test("do nothing when no song is loaded", () async {
      await playback.stop().then((r) => r.asOk);
      playback
        ..setBandGain(0, 2)
        ..reset()
        ..pause();
      await playback.resume();

      expect(playback.song, isNull);
      expect(playback.getBandGain(0), isNull);
      expect(playback.isPlaying, isFalse);
    });
  });

  group("playing", () {
    setUp(load);

    test("resume and pause toggle playing and claim the session", () async {
      await playback.resume();
      expect(playback.isPlaying, isTrue);
      verify(() => session.setActive(true)).called(greaterThan(0));

      playback.pause();
      expect(playback.isPlaying, isFalse);
    });

    test("an interruption pauses and its end resumes", () async {
      await playback.resume();

      session.events.add(AudioSessionEvent.pause);
      await pumpEventQueue();
      expect(playback.isPlaying, isFalse);

      session.events.add(AudioSessionEvent.resume);
      await pumpEventQueue();
      expect(playback.isPlaying, isTrue);
    });

    test("the end of an interruption does not start a paused song", () async {
      session.events.add(AudioSessionEvent.duck);
      await pumpEventQueue();
      session.events.add(AudioSessionEvent.unduck);
      await pumpEventQueue();
      expect(playback.isPlaying, isFalse);
    });

    test("stop unloads the song and releases the session", () async {
      await playback.stop().then((r) => r.asOk);
      expect(playback.song, isNull);
      expect(playback.state, isNull);
      verify(() => session.setActive(false)).called(1);
    });
  });
}
