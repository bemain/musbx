import 'package:flutter/foundation.dart';

final class ServiceDisabled implements Exception {}

abstract class OptionalService {
  /// Whether this service is currently active.
  bool get isEnabled;

  @protected
  void throwIfDisabled() {
    if (!isEnabled) throw ServiceDisabled();
  }
}
