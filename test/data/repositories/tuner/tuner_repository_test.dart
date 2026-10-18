import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/repositories/tuner/tuner_repository.dart';
import 'package:musbx/data/services/audio_capture_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/domain/models/audio_frame.dart';
import 'package:musbx/domain/models/frequency_detection.dart';

import '../../../helpers/fixtures.dart';

class MockAudioCaptureService extends Mock implements AudioCaptureService {}

void main() {
  late MockAudioCaptureService microphone;
  late StreamController<AudioFrame> frames;
  late TunerRepository tuner;

  AudioFrame frame(Float32List data) =>
      AudioFrame(data: data, wave: Float32List(0), fft: Float32List(0));

  TunerRepository create(AudioCaptureService service) {
    final repository = TunerRepository(
      audioCapture: ServiceLoader(
        create: () async => service,
        fallback: () => service,
      ),
    );
    addTearDown(repository.dispose);
    return repository;
  }

  setUp(() {
    microphone = MockAudioCaptureService();
    frames = StreamController.broadcast();
    addTearDown(frames.close);
    when(() => microphone.sampleRate).thenReturn(22050);
    when(() => microphone.dataStream).thenAnswer((_) => frames.stream);
    tuner = create(microphone);
  });

  test("does not touch the microphone until listened to", () {
    verifyNever(() => microphone.dataStream);
  });

  test("detects the frequency in each frame", () async {
    final readings = <FrequencyDetection>[];
    final subscription = tuner.dataStream.listen(readings.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    frames.add(frame(sine(440)));
    await pumpEventQueue();

    expect(readings.single.frequency, closeTo(440, 1));
    expect(tuner.latestReading, same(readings.single));
  });

  test("buffers only the most recent readings", () async {
    final subscription = tuner.dataStream.listen((_) {});
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    for (var i = 0; i < TunerRepository.bufferLength + 5; i++) {
      frames.add(frame(Float32List(2048)));
    }
    await pumpEventQueue();

    expect(tuner.dataBuffer, hasLength(TunerRepository.bufferLength));
  });

  test("a disabled microphone surfaces as a stream error", () async {
    tuner = create(AudioCaptureService.disabled());
    await expectLater(tuner.dataStream, emitsError(isA<ServiceDisabled>()));
  });
}
