import 'package:flutter/material.dart';
import 'package:gauges/gauges.dart';

class TunerGauge extends StatelessWidget {
  const TunerGauge({super.key, required this.pitchOffset});

  final double pitchOffset;

  @override
  Widget build(BuildContext context) {
    List<Color> needleColors = (pitchOffset.abs() < 10)
        ? [Colors.lightGreen, Colors.green]
        : [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColorDark,
          ];

    return RadialGauge(
      axes: [
        RadialGaugeAxis(
          minValue: -1,
          maxValue: 1,
          minAngle: -18,
          maxAngle: 18,
          radius: 0,
          width: 0.8,
          color: Colors.green.withOpacity(0.1),
        ),
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
              ],
            ),
            RadialTicks(
              values: [for (double i = -9; i <= 9; i++) i]..remove(0),
              length: 0.05,
              color: Colors.green,
            )
          ],
          pointers: [
            RadialNeedlePointer(
              value: pitchOffset,
              thicknessStart: 20,
              thicknessEnd: 0,
              length: 0.8,
              knobRadiusAbsolute: 10,
              gradient: LinearGradient(
                colors: needleColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 0.5],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
