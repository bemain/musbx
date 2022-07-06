import 'package:flutter/material.dart';
import 'package:gauges/gauges.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/tuner/note.dart';
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
  Stream<PitchDetectorResult>? pitchStream;
  late final Future initAudioFuture = initAudio();

  /// Create the stream for getting pitch from microphone
  Future<void> initAudio() async {
    Stream<List<int>>? audioStream =
        await MicStream.microphone(sampleRate: 44100);
    assert(
      audioStream != null,
      "TUNER: Unable to capture audio from microphone",
    );
    pitchStream = audioStream!.map((audio) => pitchDetector
        .getPitch(audio.map((int val) => val.toDouble()).toList()));
  }

  /// The most recent note detected.
  List<Note> previousNotes = <Note>[Note.a4()];
  int averageN = 5;

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
            if (pitchResult.pitched) {
              // Store new note
              previousNotes.add(Note.fromFrequency(pitchResult.pitch));
              // Only keep [averageN] last notes
              while (previousNotes.length > averageN) {
                previousNotes.removeAt(0);
              }
            }

            List<double> pitchOffsets =
                previousNotes.map((note) => note.pitchOffset).toList();
            double avgPitchOffset =
                pitchOffsets.reduce((a, b) => a + b) / pitchOffsets.length;

            return RadialGauge(
              axes: [
                RadialGaugeAxis(
                    minValue: -50,
                    maxValue: 50,
                    minAngle: -90,
                    maxAngle: 90,
                    ticks: [
                      RadialTicks(
                          interval: 10,
                          alignment: RadialTickAxisAlignment.inside,
                          length: 0.1,
                          color: Theme.of(context).primaryColor,
                          children: [
                            RadialTicks(
                              ticksInBetween: 4,
                              length: 0.05,
                              color: Theme.of(context).hintColor,
                            )
                          ]),
                    ],
                    pointers: [
                      RadialNeedlePointer(
                        value: avgPitchOffset,
                        thicknessStart: 20,
                        thicknessEnd: 0,
                        length: 0.8,
                        knobRadiusAbsolute: 10,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColorDark,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.5, 0.5],
                        ),
                      ),
                    ]),
              ],
            );
          },
        );
      },
    );
  }
}
