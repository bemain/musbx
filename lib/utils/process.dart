import 'dart:async';

import 'package:flutter/material.dart';

class Cancelled implements Exception {
  /// Exception thrown when a process has been cancelled early.
  const Cancelled([this.msg]);

  final String? msg;

  @override
  String toString() => msg ?? 'This process has been cancelled';
}

/// A helper class for handling lengthy tasks.
/// Features progress tracking, cancellation and automatic error handling.
abstract class Process<T extends Object> extends ChangeNotifier {
  Process() {
    // Begin executing the future.
    future;
  }

  /// The future that completes with this task.
  late final Future<T> future = _processAndReportErrors();

  /// The progress of the process.
  /// Should be a fraction between 0 and 1.
  double? get progress => progressNotifier.value;
  final ValueNotifier<double?> progressNotifier = ValueNotifier(null);

  /// Whether this process is still active.
  bool get isActive => !(hasResult || hasError || isCancelled);

  /// Whether this process has completed with a result.
  bool get hasResult => result != null;

  /// The result that this process produced.
  /// `null` if the process hasn't compelted yet.
  T? get result => resultNotifier.value;
  late final ValueNotifier<T?> resultNotifier = ValueNotifier(null)
    ..addListener(notifyListeners);

  /// Whether this process has encountered an error.
  bool get hasError => error != null;

  /// The error encountered by this process, if any.
  Object? get error => errorNotifier.value;
  late final ValueNotifier<Object?> errorNotifier = ValueNotifier(null)
    ..addListener(notifyListeners);

  /// Whether this process has been cancelled.
  bool get isCancelled => isCancelledNotifier.value;
  set isCancelled(bool value) => isCancelledNotifier.value = value;
  late final ValueNotifier<bool> isCancelledNotifier = ValueNotifier(false)
    ..addListener(notifyListeners);

  /// Tell this process stop as soon as possible.
  void cancel() => isCancelled = true;

  /// Start the [process] and catch any errors that occur.
  Future<T> _processAndReportErrors() async {
    try {
      final T res = await process();
      resultNotifier.value = res;
      return res;
    } catch (e) {
      errorNotifier.value = e;
      rethrow;
    }
  }

  /// The method that this process executes.
  Future<T> process();

  /// If this process has been cancelled, throw a [Cancelled] error.
  ///
  /// Should be called periodically between asynchronous operations to introduce
  /// "breakpoints" where the process can be cancelled.
  void breakIfCancelled() {
    if (isCancelled) throw const Cancelled();
  }
}
