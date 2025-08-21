import 'package:flutter/widgets.dart';

extension ClampDuration on Duration {
  /// Clamp this to between [lowerLimit] and [upperLimit].
  Duration clamp(Duration lowerLimit, Duration upperLimit) {
    return Duration(
      microseconds: inMicroseconds.clamp(
        lowerLimit.inMicroseconds,
        upperLimit.inMicroseconds,
      ),
    );
  }
}

extension MapValueNotifier<T> on ValueNotifier<T> {
  /// Create a new [ValueNotifier] by passing each value that this receives
  /// through the [convert] method and then feeding that to the notifier.
  ValueNotifier<S> map<S>(S Function(T) convert) {
    final ValueNotifier<S> notifier = ValueNotifier<S>(convert(value));
    addListener(() => notifier.value = convert(value));
    return notifier;
  }
}

extension IfNotNull<T extends Object?> on T {
  /// Returns `null` if this is `null`, and [value] otherwise.
  S? ifNotNull<S>(S value) => this == null ? null : value;
}

Type typeOf<T>() => T;

typedef Json = Map<String, dynamic>;
