import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/services/audio_session_service.dart';

class MockAudioSession extends Mock implements AudioSession {}

void main() {
  setUpAll(() => registerFallbackValue(const AudioSessionConfiguration()));

  late MockAudioSession session;
  late StreamController<AudioInterruptionEvent> interruptions;
  late StreamController<void> noisy;
  late AudioSessionService service;

  setUp(() async {
    session = MockAudioSession();
    interruptions = StreamController();
    noisy = StreamController();
    addTearDown(interruptions.close);
    addTearDown(noisy.close);
    when(
      () => session.interruptionEventStream,
    ).thenAnswer((_) => interruptions.stream);
    when(
      () => session.becomingNoisyEventStream,
    ).thenAnswer((_) => noisy.stream);
    when(() => session.configure(any())).thenAnswer((_) async {});
    when(() => session.setActive(any())).thenAnswer((_) async => true);

    service = await AudioSessionService.createWith(session);
  });

  test("create configures the session for playback and recording", () {
    final configuration =
        verify(() => session.configure(captureAny())).captured.single
            as AudioSessionConfiguration;
    expect(
      configuration.avAudioSessionCategory,
      AVAudioSessionCategory.playAndRecord,
    );
    expect(configuration.androidWillPauseWhenDucked, isTrue);
  });

  test("setActive claims and releases focus", () async {
    await service.setActive(true);
    await service.setActive(false);

    verifyInOrder([
      () => session.setActive(true),
      () => session.setActive(false),
    ]);
  });

  test("interruptions become events", () async {
    final events = service.eventStream.take(4).toList();

    for (final (begin, type) in [
      (true, AudioInterruptionType.duck),
      (false, AudioInterruptionType.duck),
      (true, AudioInterruptionType.unknown),
      (true, AudioInterruptionType.pause),
      (false, AudioInterruptionType.unknown),
      (false, AudioInterruptionType.pause),
    ]) {
      interruptions.add(AudioInterruptionEvent(begin, type));
    }

    expect(await events, [
      AudioSessionEvent.duck,
      AudioSessionEvent.unduck,
      AudioSessionEvent.pause,
      AudioSessionEvent.resume,
    ]);
  });

  test("unplugged headphones pause playback", () async {
    final event = service.eventStream.first;
    noisy.add(null);
    expect(await event, AudioSessionEvent.pause);
  });
}
