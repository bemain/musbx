import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/services/audio_capture_service.dart';
import 'package:musbx/data/services/service.dart';

class MockRecorder extends Mock implements Recorder {}

void main() {
  setUpAll(() {
    registerFallbackValue(PCMFormat.f32le);
    registerFallbackValue(RecorderChannels.mono);
  });

  late MockRecorder recorder;
  late StreamController<AudioDataContainer> captured;
  late AudioCaptureService microphone;

  setUp(() async {
    recorder = MockRecorder();
    captured = StreamController.broadcast();
    addTearDown(captured.close);
    when(
      () => recorder.init(
        format: any(named: "format"),
        sampleRate: any(named: "sampleRate"),
        channels: any(named: "channels"),
      ),
    ).thenAnswer((_) async {});
    when(() => recorder.uint8ListStream).thenAnswer((_) => captured.stream);
    when(() => recorder.getWave()).thenReturn(Float32List.fromList([0.5]));
    when(() => recorder.getFft()).thenReturn(Float32List.fromList([0.25]));

    microphone = await AudioCaptureService.createWith(
      recorder,
      sampleRate: 44100,
    );
    addTearDown(microphone.dispose);
  });

  test("create claims the microphone in mono at the sample rate", () {
    verify(
      () => recorder.init(
        format: PCMFormat.f32le,
        sampleRate: 44100,
        channels: RecorderChannels.mono,
      ),
    );
    expect(microphone.sampleRate, 44100);
    verifyNever(recorder.start);
  });

  test("the microphone runs only while dataStream is listened to", () async {
    final subscription = microphone.dataStream.listen((_) {});
    verify(recorder.start);
    verify(recorder.startStreamingData);

    await subscription.cancel();
    verify(recorder.stopStreamingData);
    verify(recorder.stop);
  });

  test("each frame carries copies of the wave and spectrum", () async {
    final wave = Float32List.fromList([0.5]);
    when(() => recorder.getWave()).thenReturn(wave);
    final frame = microphone.dataStream.first;

    captured.add(
      AudioDataContainer(Float32List.fromList([1, -1]).buffer.asUint8List()),
    );
    final received = await frame;
    wave[0] = 0;

    expect(received.data, [1, -1]);
    expect(received.wave, [0.5]);
    expect(received.fft, [0.25]);
  });

  test("dataStream can be listened to again after a screen leaves", () async {
    await microphone.dataStream.listen((_) {}).cancel();
    await microphone.dataStream.listen((_) {}).cancel();

    verify(recorder.start).called(2);
  });

  group("disabled", () {
    final disabled = AudioCaptureService.disabled();

    test("is not enabled", () => expect(disabled.isEnabled, isFalse));

    test("refuses dataStream", () {
      expect(() => disabled.dataStream, throwsA(isA<ServiceDisabled>()));
    });

    test("can still be disposed", () => expect(disabled.dispose(), completes));
  });
}
