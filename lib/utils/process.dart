import 'dart:async';
import 'dart:core';
import 'dart:core' as core;

import 'package:flutter/material.dart';

/// The outcome of a [Process]: the value it produced, the error it failed with,
/// or cancellation.
///
/// Evaluate the outcome using a switch statement, which the compiler checks for
/// exhaustiveness:
/// ```dart
/// switch (process.result) {
///   case Ok(:final value):
///     print("Produced $value");
///   case Error(:final error):
///     print("Failed with $error");
///   case Cancelled():
///     print("Cancelled before it finished");
///   case null:
///     print("Still running");
/// }
/// ```
sealed class ProcessResult<T> {
  const ProcessResult();

  /// Creates a successful [ProcessResult], completed with the specified [value].
  const factory ProcessResult.ok(T value) = Ok._;

  /// Creates an error [ProcessResult], completed with the specified [error].
  ///
  /// If no [stackTrace] is given, the trace of this call is used.
  factory ProcessResult.error(Object error, StackTrace? stackTrace) =>
      Error._(error, stackTrace ?? StackTrace.current);

  /// Creates a [ProcessResult] for a process that was cancelled.
  const factory ProcessResult.cancelled() = Cancelled._;
}

/// The [ProcessResult] of a process that completed successfully.
final class Ok<T> extends ProcessResult<T> {
  const Ok._(this.value);

  /// The value that the process produced.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// The [ProcessResult] of a process that failed.
final class Error<T> extends ProcessResult<T> {
  const Error._(this.error, this.stackTrace);

  /// The error that the process threw.
  final Object error;

  /// The stack trace of where [error] occurred.
  final StackTrace stackTrace;

  @override
  String toString() => 'Result<$T>.error($error)';
}

/// The [ProcessResult] of a process that was cancelled before it produced a
/// value or an error. See [Process.cancel].
final class Cancelled<T> extends ProcessResult<T> {
  const Cancelled._();

  @override
  String toString() => "Result<$T>.cancelled()";
}

/// Thrown by [Process.breakIfCancelled] to unwind [Process.execute] once the
/// process has been cancelled. Never escapes [Process.future].
final class _CancelledException implements Exception {
  @override
  String toString() => "This process was cancelled before it returned a value";
}

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
  /// [Error] result instead.
  late final Future<ProcessResult<T>> future = _execute();

  /// The progress of the process, as reported by [execute].
  /// Should be a value between `0.0` and `1.0`.
  double get progress => progressNotifier.value;
  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

  ProcessResult<T>? _result;

  /// The outcome of this process, or `null` if it hasn't finished yet.
  ProcessResult<T>? get result => _result;

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
    Error<T>(:final error) => error,
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
    _result = ProcessResult.cancelled();
    notifyListeners();
  }

  /// Run [execute] and capture its outcome in [result].
  Future<ProcessResult<T>> _execute() async {
    try {
      final value = await execute();
      if (_result != null) return _result!;
      _result = ProcessResult.ok(value);
    } on _CancelledException catch (_) {
      if (_result != null) return _result!;
      _result = ProcessResult.cancelled();
    } catch (e, s) {
      assert(e is Exception);
      if (_result != null) return _result!;
      _result = ProcessResult.error(e, s);
    }

    notifyListeners();
    return _result!;
  }

  /// The task that this process performs.
  ///
  /// Throw to fail the process; whatever is thrown is caught and exposed as an
  /// [Error] result. Report progress through [progressNotifier], and call
  /// [breakIfCancelled] periodically so that the process can be cancelled.
  Future<T> execute();

  /// If this process has been cancelled, abort [execute].
  ///
  /// Should be called periodically between asynchronous operations to introduce
  /// "breakpoints" where the process can be cancelled.
  void breakIfCancelled() {
    if (result case Cancelled()) throw _CancelledException();
  }
}
