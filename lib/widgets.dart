import 'dart:async';
import 'dart:io';
import 'dart:collection';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class ContinuousButton extends StatelessWidget {
  /// Button that can be held down to yield continuous presses.
  const ContinuousButton({
    super.key,
    required this.onContinuousPress,
    this.onContinuousPressEnd,
    this.interval = const Duration(milliseconds: 100),
    required this.child,
  });

  /// Callback for when this button is pressed.
  final void Function()? onContinuousPress;

  /// Callback for when the user stops pressing this button.
  final void Function()? onContinuousPressEnd;

  /// Interval between callbacks if the button is held pressed.
  final Duration interval;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Timer timer = Timer(const Duration(), () {});
    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        timer = Timer.periodic(interval, (_) => onContinuousPress?.call());
      },
      onLongPressUp: () {
        timer.cancel();
        onContinuousPressEnd?.call();
      },
      onLongPressCancel: () {
        timer.cancel();
        onContinuousPressEnd?.call();
      },
      child: child,
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key, required this.icon, required this.text})
      : super(key: key);

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[icon, Text(text)]));
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoScreen(
      icon: const Icon(Icons.error_rounded),
      text: text,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoScreen(
      icon: const CircularProgressIndicator(),
      text: text,
    );
  }
}

T? tryCast<T>(dynamic x, {T? fallback}) => x is T ? x : fallback;

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

/// Whether the phone is connected to a mobile network.
Future<bool> isOnCellular() async {
  final connectivity = await (Connectivity().checkConnectivity());
  return connectivity != ConnectivityResult.wifi &&
      connectivity != ConnectivityResult.ethernet;
}

class MeasureSizeRenderObject extends RenderProxyBox {
  void Function(Size size) onChange;
  Size? oldSize;

  MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();

    Size newSize = child!.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final void Function(Size size) onSizeChanged;

  /// Provides a callback for when the size of [child] changes.
  const MeasureSize({
    super.key,
    required this.onSizeChanged,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return MeasureSizeRenderObject(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onSizeChanged;
  }
}

/// Creates a temporary directory with the given [name].
/// If the directory already exists, does nothing.
Future<Directory> createTempDirectory(String name) async {
  var dir = Directory("${(await getTemporaryDirectory()).path}/$name/");
  await dir.create(recursive: true);
  return dir;
}

class ListNotifier<T> extends ChangeNotifier {
  ListNotifier(this._value);

  final List<T> _value;

  /// The current value stored in this notifier.
  UnmodifiableListView<T> get value => UnmodifiableListView(_value);

  T operator [](int index) => _value[index];
  operator []=(int index, T value) {
    _value[index] = value;
    notifyListeners();
  }

  void add(T element) {
    _value.add(element);
    notifyListeners();
  }

  void addAll(Iterable<T> iterable) {
    _value.addAll(iterable);
    notifyListeners();
  }

  bool remove(T element) {
    final ret = _value.remove(element);
    notifyListeners();
    return ret;
  }

  T removeAt(int index) {
    final ret = _value.removeAt(index);
    notifyListeners();
    return ret;
  }
}

class ExpandedIcon extends StatelessWidget {
  const ExpandedIcon(this.icon, {super.key});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) => Icon(
        icon,
        size: constraint.biggest.shortestSide,
      ),
    );
  }
}
