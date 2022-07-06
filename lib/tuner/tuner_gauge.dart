import 'package:flutter/material.dart';
import 'package:gauges/gauges.dart';
import 'package:musbx/tuner/note.dart';

class TunerGauge extends StatelessWidget {
  const TunerGauge({super.key, required this.previousNotes});

  final List<Note> previousNotes;

  @override
  Widget build(BuildContext context) {
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
  }
}
