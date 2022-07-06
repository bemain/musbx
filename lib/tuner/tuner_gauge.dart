import 'package:flutter/material.dart';
import 'package:gauges/gauges.dart';

class TunerGauge extends StatelessWidget {
  const TunerGauge({super.key, required this.averagePitchOffset});

  final double averagePitchOffset;

  @override
  Widget build(BuildContext context) {
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
                value: averagePitchOffset,
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
