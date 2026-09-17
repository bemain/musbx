import 'package:flutter/foundation.dart';
import 'package:musbx/data/services/service.dart';

/// How far a service got the last time it was created.
enum ServiceAvailability {
  /// Not attempted yet, or an attempt is in flight.
  unknown,

  /// Created, and usable.
  ready,

  /// The service reported that it cannot run here — no store on this platform,
  /// no Firebase configuration. Terminal: another attempt cannot change it.
  unsupported,

  /// Creating it threw. Assumed transient — a device offline at launch is the
  /// ordinary case — so another attempt is worth making.
  failed,
}

/// Holds an [OptionalService] that may not have been created successfully, and
/// allows another attempt when it failed for a reason that could pass.
///
/// [value] is always usable: a fallback stands in until `create` succeeds, so
/// callers never handle `null` and never see the swap. What they do see is
/// [availability].
///
/// Attempts only happen when someone asks. Nothing here polls.
class ServiceLoader<T extends OptionalService> extends ChangeNotifier {
  ServiceLoader({
    required Future<T> Function() create,
    required T Function() fallback,
    this.retryCooldown = const Duration(seconds: 30),
  }) : _create = create,
       _value = fallback();

  final Future<T> Function() _create;

  /// The shortest time between two attempts, so that a widget calling
  /// [ensureAvailable] as it builds cannot hammer the network.
  final Duration retryCooldown;

  T _value;
  T get value => _value;

  ServiceAvailability _availability = ServiceAvailability.unknown;
  ServiceAvailability get availability => _availability;

  /// Whether another attempt could still change [availability].
  bool get canRetry =>
      _availability == ServiceAvailability.unknown ||
      _availability == ServiceAvailability.failed;

  DateTime? _lastAttempt;
  Future<void>? _attempt;

  /// Create the service unless it is already available or known unsupported.
  ///
  /// Concurrent calls share one attempt, and a call within [retryCooldown] of a
  /// failed one does nothing. Never throws: a failure leaves the fallback in
  /// place and is reported through [availability].
  Future<void> ensureAvailable() {
    if (!canRetry) return Future.value();
    if (_attempt case final attempt?) return attempt;

    final last = _lastAttempt;
    if (last != null && DateTime.now().difference(last) < retryCooldown) {
      return Future.value();
    }

    return _attempt = _run();
  }

  Future<void> _run() async {
    _lastAttempt = DateTime.now();
    final previous = _availability;

    try {
      final service = await _create();
      _value = service;
      _availability = service.isEnabled
          ? ServiceAvailability.ready
          : ServiceAvailability.unsupported;
    } catch (error) {
      debugPrint("[SERVICES] Creating $T failed: $error");
      _availability = ServiceAvailability.failed;
    } finally {
      _attempt = null;
    }

    if (_availability != previous) notifyListeners();
  }
}
