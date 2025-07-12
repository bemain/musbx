import 'dart:async';
import 'dart:io';
import 'dart:collection';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
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

class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          icon,
          Text(text),
        ],
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      icon: const Icon(Symbols.error_rounded),
      text: text,
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InfoPage(
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
  return !connectivity.contains(ConnectivityResult.wifi) &&
      !connectivity.contains(ConnectivityResult.ethernet);
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

class Directories {
  Directories._();

  static late final Directory _tempDir;

  static late final Directory _appDocsDir;

  /// Get a temporary directory with the given [name].
  ///
  /// This does not check to make sure that the directory actually exists.
  static Directory temporaryDir(String name) =>
      Directory("${_tempDir.path}/$name/");

  /// Get a application documents directory with the given [name].
  ///
  /// This does not check to make sure that the directory actually exists.
  static Directory applicationDocumentsDir(String name) =>
      Directory("${_appDocsDir.path}/$name/");

  /// Resolve the paths to commonly used locations on the filesystem, which are
  /// used by the methods provided by this class.
  ///
  /// Should be called during app launch.
  static Future<void> initialize() async {
    _tempDir = await getTemporaryDirectory();
    try {
      _appDocsDir = await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint(
          "[DIRECTORIES] Unable to get application documents; falling back to temporary directory. $e");
      _appDocsDir = _tempDir;
    }

    debugPrint(
        "[DIRECTORIES] Initialized with temporary directory at ${_tempDir.path}, application documents at ${_appDocsDir.path}");
  }
}

class ListNotifier<T> extends ChangeNotifier {
  ListNotifier(this._value);

  final List<T> _value;

  /// The current value stored in this notifier.
  UnmodifiableListView<T> get value => UnmodifiableListView(_value);

  T operator [](int index) => _value[index];
  void operator []=(int index, T value) {
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

  void clear() {
    _value.clear();
    notifyListeners();
  }
}

class ExpandedIcon extends StatelessWidget {
  const ExpandedIcon(this.icon, {super.key, this.color, this.fill});

  final IconData? icon;
  final Color? color;
  final double? fill;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) => Icon(
        icon,
        size: constraint.biggest.shortestSide,
        color: color,
        fill: fill,
      ),
    );
  }
}

class NumberField<T extends num> extends StatelessWidget {
  NumberField({
    super.key,
    this.value,
    this.min,
    this.max,
    required this.onSubmitted,
    this.prefixWithSign = false,
    this.style,
    this.inputFormatters,
  });

  final T? value;
  final T? min;
  final T? max;

  /// If `true`, automatically prefixes the value with the correct sign.
  ///
  /// When the user starts editing the value, the prefix is removed so that the sign can be edited.
  final bool prefixWithSign;
  final TextStyle? style;
  final List<TextInputFormatter>? inputFormatters;

  final void Function(T value)? onSubmitted;

  late final TextEditingController controller = TextEditingController(
    text: prefixWithSign ? value?.abs().toString() : value?.toString(),
  );

  /// Optional text prefix to place on the line before the input.
  late final ValueNotifier<String?> prefixText =
      ValueNotifier(!prefixWithSign || value == null
          ? null
          : value! >= 0
              ? "+"
              : "-");

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: prefixText,
      builder: (context, child) => TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixText: prefixText.value,
          border: const UnderlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
        ),
        style: style,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType:
            const TextInputType.numberWithOptions(signed: true, decimal: true),
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(
              r"^(-|-?\d+(?:\.\d*)?)$")), // Allow positive and negative decimal numbers, as well as just a minus sign
          ...?inputFormatters,
        ],
        maxLines: 1,
        enabled: onSubmitted != null,
        onChanged: (value) {
          /// Remove prefix and instead add the minus sign to the text, so that it can be edited.
          if (prefixText.value == "-" && !value.startsWith("-")) {
            controller.text = "-${controller.text}";
          }
          prefixText.value = null;
        },
        onSubmitted: (value) {
          num? parsed = num.tryParse(value);
          if (parsed == null) {
            // Reset to the actual value
            if (this.value != null) controller.text = this.value.toString();
            return;
          }

          T clamped = parsed.clamp(
            min ?? double.negativeInfinity,
            max ?? double.infinity,
          ) as T;
          controller.text = clamped.toString();
          onSubmitted?.call(clamped);
        },
      ),
    );
  }
}

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
