import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:musbx/editable_screen/card_list.dart';
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
  /// The pitch detected from the microphone.
  Stream<PitchDetectorResult>? pitchStream;

  /// Future for creating [pitchStream].
  late final Future initAudioFuture = initAudio();

  /// The [averageNotesN] most recent notes detected.
  List<Note> previousNotes = <Note>[Note.a4()];

  /// The number of notes to take average of.
  static const int averageNotesN = 10;

  /// Create the stream for getting pitch from microphone.
  Future<void> initAudio() async {
    final Stream<List<int>>? audioStream =
        await MicStream.microphone(sampleRate: 44100);
    assert(
      audioStream != null,
      "TUNER: Unable to capture audio from microphone",
    );

    final PitchDetector pitchDetector = PitchDetector(44100, 1792);
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
            if (pitchResult.pitched) {
              // Store new note
              previousNotes.add(Note.fromFrequency(pitchResult.pitch));
              // Only keep [averageN] last notes
              while (previousNotes.length > averageNotesN) {
                previousNotes.removeAt(0);
              }
            }

            // Calculate average note
            List<double> previousFrequencies =
                previousNotes.map((note) => note.frequency).toList();
            double avgFrequency = previousFrequencies.reduce((a, b) => a + b) /
                previousFrequencies.length;
            Note avgNote = Note.fromFrequency(avgFrequency);

            return CardList(
              children: [
                TunerGauge(note: avgNote),
              ],
            );
          },
        );
      },
    );
  }
}
