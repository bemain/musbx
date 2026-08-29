abstract interface class ServiceDisabled {}

abstract class OptionalService {
  /// Whether this service is currently active.
  bool get isEnabled;
}
