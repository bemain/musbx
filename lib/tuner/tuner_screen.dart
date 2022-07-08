import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/tuner/note.dart';
import 'package:musbx/tuner/tuner_gauge.dart';
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

  /// The [averageNotesN] most recent notes detected.
  List<Note> previousNotes = <Note>[Note.a4()];

  /// The number of notes to take average of.
  static const int averageNotesN = 10;

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
              while (previousNotes.length > averageNotesN) {
                previousNotes.removeAt(0);
              }
            }

            // Calculate average pitch iffset
            List<double> previousFrequencies =
                previousNotes.map((note) => note.frequency).toList();
            double avgFrequency = previousFrequencies.reduce((a, b) => a + b) /
                previousFrequencies.length;
            Note avgNote = Note.fromFrequency(avgFrequency);

            return Stack(
              children: [
                Positioned(
                  left: 75,
                  top: 118,
                  child: Text(
                    previousNotes.last.name,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                Positioned(
                  left: 250,
                  top: 125,
                  child: Text(
                    (avgNote.pitchOffset.toInt().isNegative)
                        ? "${avgNote.pitchOffset.toInt()}¢"
                        : "+${avgNote.pitchOffset.toInt()}¢",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                TunerGauge(pitchOffset: avgNote.pitchOffset),
              ],
            );
          },
        );
      },
    );
  }
}
