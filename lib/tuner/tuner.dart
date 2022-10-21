import 'package:mic_stream/mic_stream.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

/// Singleton for getting the pitch being played.
class Tuner {
  Tuner._();

  /// The instance of this singleton.
  static final Tuner instance = Tuner._();

  /// The pitch detected from the microphone.
  Stream<PitchDetectorResult>? pitchStream;

  /// Future for creating [pitchStream].
  late final Future initAudioFuture = initAudio();

  /// Create the stream for getting pitch from microphone.
  Future<void> initAudio() async {
    final Stream<List<int>>? audioStream =
        await MicStream.microphone(sampleRate: 44100);
    assert(
      audioStream != null,
      "TUNER: Unable to capture audio from microphone",
    );

    final PitchDetector pitchDetector =
        PitchDetector(44100, await MicStream.bufferSize ?? 1792);

    pitchStream = audioStream!.map((audio) => pitchDetector
        .getPitch(audio.map((int val) => val.toDouble()).toList()));
  }
}
