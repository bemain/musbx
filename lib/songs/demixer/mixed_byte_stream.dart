import 'dart:async';

/// A stream that combines the values of other byte streams.
///
/// This emits lists of collected values from each input stream.
/// It accumulates a number of bytes from each stream before emitting, so that
/// all the lists have the same length.
///
/// Any errors from any of the streams are forwarded directly to this stream.
class MixedByteStream extends Stream<List<List<int>>> {
  final Iterable<Stream<List<int>>> _streams;

  MixedByteStream(Iterable<Stream<List<int>>> streams) : _streams = streams;

  @override
  StreamSubscription<List<List<int>>> listen(
    void Function(List<List<int>>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    cancelOnError = identical(true, cancelOnError);
    final subscriptions = <StreamSubscription<List<int>>>[];
    late final StreamController<List<List<int>>> controller;

    /// The last value emitted from each byte stream.
    /// After the first iteration, contains the overflow from the previous value emitted.
    late List<List<int>?> current;
    int dataCount = 0;

    /// Called for each data from a subscription in [subscriptions].
    void handleData(int index, List<int> data) {
      current[index] = (current[index] ?? []) + data;
      dataCount++;
      if (dataCount == subscriptions.length) {
        /// The minimum value among the byte lists' length
        final int chunkSize =
            current.reduce((a, b) => a!.length < b!.length ? a : b)!.length;

        var data = current.map((l) => l!.sublist(0, chunkSize)).toList();
        current = current.map((l) => l?.sublist(chunkSize)).toList();
        dataCount = 0;
        for (var i = 0; i < subscriptions.length; i++) {
          if (i != index) subscriptions[i].resume();
        }
        controller.add(data);
      } else {
        subscriptions[index].pause();
      }
    }

    /// Called for each error from a subscription in [subscriptions].
    /// Except if [cancelOnError] is true, in which case the function below
    /// is used instead.
    void handleError(Object error, StackTrace stackTrace) {
      controller.addError(error, stackTrace);
    }

    /// Called when a subscription has an error and [cancelOnError] is true.
    ///
    /// Prematurely cancels all subscriptions since we know that we won't
    /// be needing any more values.
    void handleErrorCancel(Object error, StackTrace stackTrace) {
      for (var i = 0; i < subscriptions.length; i++) {
        subscriptions[i].cancel();
      }
      controller.addError(error, stackTrace);
    }

    void handleDone() {
      for (var i = 0; i < subscriptions.length; i++) {
        subscriptions[i].cancel();
      }
      controller.close();
    }

    try {
      for (var stream in _streams) {
        var index = subscriptions.length;
        subscriptions.add(stream.listen((data) {
          handleData(index, data);
        },
            onError: cancelOnError ? handleError : handleErrorCancel,
            onDone: handleDone,
            cancelOnError: cancelOnError));
      }
    } catch (e) {
      for (var i = subscriptions.length - 1; i >= 0; i--) {
        subscriptions[i].cancel();
      }
      rethrow;
    }

    current = List<List<int>?>.filled(subscriptions.length, null);

    controller = StreamController<List<List<int>>>(onPause: () {
      for (var i = 0; i < subscriptions.length; i++) {
        // This may pause some subscriptions more than once.
        // These will not be resumed by onResume below, but must wait for the
        // next round.
        subscriptions[i].pause();
      }
    }, onResume: () {
      for (var i = 0; i < subscriptions.length; i++) {
        subscriptions[i].resume();
      }
    }, onCancel: () {
      for (var i = 0; i < subscriptions.length; i++) {
        // Canceling more than once is safe.
        subscriptions[i].cancel();
      }
    });

    if (subscriptions.isEmpty) {
      controller.close();
    }
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
