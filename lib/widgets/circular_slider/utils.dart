import 'dart:math';

import 'package:flutter/material.dart';

Offset angleToPoint(double angle, Offset center, double radius) {
  return center + Offset(cos(angle), sin(angle)) * radius;
}

double pointToAngle(Offset point, Offset center) {
  return atan2(point.dx - center.dx, center.dy - point.dy);
}

bool isPointInsideCircle(Offset point, Offset center, double rradius) {
  var radius = rradius * 1.2;
  return point.dx < (center.dx + radius) &&
      point.dx > (center.dx - radius) &&
      point.dy < (center.dy + radius) &&
      point.dy > (center.dy - radius);
}

bool isPointAlongCircle(
  Offset point,
  Offset center,
  double radius,
  double trackWidth,
) {
  var d1 = pow(point.dx - center.dx, 2);
  var d2 = pow(point.dy - center.dy, 2);
  var distance = sqrt(d1 + d2);
  return (distance - radius).abs() < trackWidth / 2;
}
