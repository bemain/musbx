import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/widgets.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<StatefulWidget> createState() => TunerScreenState();
}

class TunerScreenState extends State<TunerScreen> {
  final PitchDetector pitchDetector = PitchDetector(44100, 1792);
  Stream<List<int>>? audioStream;
  Stream<PitchDetectorResult>? pitchStream;

  late final Future initAudioFuture = initAudio();

  /// Create the stream for getting pitch from microphone
  Future<void> initAudio() async {
    audioStream = await MicStream.microphone(sampleRate: 44100);
    assert(
      audioStream != null,
      "TUNER: Unable to capture audio from microphone",
    );
    pitchStream = audioStream!.map((audio) => pitchDetector
        .getPitch(audio.map((int val) => val.toDouble()).toList()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initAudioFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorScreen(text: "Unable to initialize audio");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen(text: "Initializing audio...");
        }

        return StreamBuilder<PitchDetectorResult>(
          stream: pitchStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorScreen(
                text: "Unable to capture audio, ${snapshot.error}",
              );
            }
            if (!snapshot.hasData) {
              return const LoadingScreen(text: "Capturing audio...");
            }

            PitchDetectorResult pitchResult = snapshot.data!;
            return Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                    "${pitchResult.pitch.toInt()} | ${pitchResult.probability}%"));
          },
        );
      },
    );
  }
}
