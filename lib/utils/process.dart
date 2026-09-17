import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musbx/utils/result.dart';

/// A lengthy task, with progress tracking, cancellation and error handling.
///
/// Subclasses implement [execute], which begins running as soon as the process
/// is constructed. Its outcome is captured in [result], so observers never have
/// to catch anything themselves.
///
/// This is a [ChangeNotifier] that notifies its listeners whenever [result]
/// changes, that is, when the process finishes or is cancelled. Progress
/// updates are reported through [progressNotifier] instead.
///
/// A process runs exactly once and cannot be restarted; construct a new
/// instance to perform the task again.
abstract class Process<T extends Object> extends ChangeNotifier {
  Process() {
    // Begin executing the future.
    unawaited(future);
  }

  /// Completes with the [result] of this process.
  ///
  /// Never completes with an error; anything [execute] throws is captured as an
  /// [Failure] result instead.
  late final Future<Result<T>> future = _execute();

  /// The progress of the process, as reported by [execute].
  /// Should be a value between `0.0` and `1.0`.
  double get progress => progressNotifier.value;
  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

  Result<T>? _result;

  /// The outcome of this process, or `null` if it hasn't finished yet.
  Result<T>? get result => _result;

  /// Whether this process is still running, that is, it has neither finished
  /// nor been cancelled.
  bool get isRunning => result == null;

  /// Whether this process has completed with a value.
  bool get hasValue => value != null;

  /// The value that this process produced, if any.
  T? get value => switch (_result) {
    Ok<T>(:final value) => value,
    _ => null,
  };

  /// Whether this process has encountered an error.
  bool get hasError => error != null;

  /// The error encountered by this process, if any.
  Object? get error => switch (_result) {
    Failure<T>(:final error) => error,
    _ => null,
  };

  /// Whether this process was cancelled before it finished.
  bool get isCancelled => switch (_result) {
    Cancelled<T>() => true,
    _ => false,
  };

  /// Tell this process to terminate as soon as possible.
  ///
  /// [result] becomes [Cancelled] immediately, but [execute] keeps running
  /// until it reaches its next [breakIfCancelled].
  void cancel() {
    _result = Result.cancelled();
    notifyListeners();
  }

  /// Run [execute] and capture its outcome in [result].
  Future<Result<T>> _execute() async {
    try {
      final value = await execute();
      if (_result != null) return _result!;
      _result = Result.ok(value);
    } on CancelledException catch (_) {
      if (_result != null) return _result!;
      _result = Result.cancelled();
    } catch (e, s) {
      assert(e is Exception);
      if (_result != null) return _result!;
      _result = Result.failed(e, s);
    }

    notifyListeners();
    return _result!;
  }

  /// The task that this process performs.
  ///
  /// Throw to fail the process; whatever is thrown is caught and exposed as an
  /// [Failure] result. Report progress through [progressNotifier], and call
  /// [breakIfCancelled] periodically so that the process can be cancelled.
  Future<T> execute();

  /// If this process has been cancelled, abort [execute].
  ///
  /// Should be called periodically between asynchronous operations to introduce
  /// "breakpoints" where the process can be cancelled.
  void breakIfCancelled() {
    if (result case Cancelled()) throw CancelledException();
  }
}
