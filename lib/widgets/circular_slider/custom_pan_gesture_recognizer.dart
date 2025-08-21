import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Custom [GestureRecognizer] for detecting pan gestures.
///
/// Required to detect vertical pan gestures inside e.g. a [ListView].
class CustomPanGestureRecognizer extends OneSequenceGestureRecognizer {
  CustomPanGestureRecognizer({
    required this.onPanDown,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  final bool Function(PointerEvent) onPanDown;
  final void Function(PointerMoveEvent) onPanUpdate;
  final void Function(PointerUpEvent) onPanEnd;
  final void Function(PointerCancelEvent) onPanCancel;

  @override
  void addPointer(PointerEvent event) {
    if (onPanDown(event)) {
      startTrackingPointer(event.pointer);
      resolve(GestureDisposition.accepted);
    } else {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onPanUpdate(event);
    }
    if (event is PointerUpEvent) {
      onPanEnd(event);
      stopTrackingPointer(event.pointer);
    }

    if (event is PointerCancelEvent) {
      onPanCancel(event);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'customPan';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}

/// Convenience method for building a [RawGestureDetector] using [CustomPanGestureRecognizer].
RawGestureDetector buildCustomPanGestureDetector({
  required CustomPanGestureRecognizer recognizer,
  required Widget child,
}) {
  return RawGestureDetector(
    gestures: <Type, GestureRecognizerFactory>{
      CustomPanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<CustomPanGestureRecognizer>(
            () => recognizer,
            (instance) {},
          ),
    },
    child: child,
  );
}
