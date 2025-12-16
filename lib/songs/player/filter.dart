// ignore_for_file: implementation_imports

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_soloud/src/filters/filters.dart';
import 'package:flutter_soloud/src/filters/parametric_eq.dart';
import 'package:flutter_soloud/src/filters/pitchshift_filter.dart';

class Filters {
  /// Wrapper around [SoLoud]'s filters, providing a consistent interface no
  /// matter which type of [SongPlayer] we are currently working with.
  Filters(this.modify);

  /// The function used to manipulate the underlying [SoLoud] filter(s).
  /// [apply] should be called on each underlying [SoLoud] filter.
  ///
  /// The [apply] method can potentially be called multiple times on multiple
  /// different [AudioSource]s, allowing implementations like the [MultiPlayer].
  final void Function(
    void Function(FiltersSingle filters, {SoundHandle? handle}) apply,
  )
  modify;

  late final Filter<PitchShiftSingle> pitchShift = Filter(
    (modifySingle) => modify(
      (filters, {handle}) =>
          modifySingle(filters.pitchShiftFilter, handle: handle),
    ),
  );
  late final Filter<ParametricEqSingle> equalizer = Filter(
    (modifySingle) => modify(
      (filters, {handle}) =>
          modifySingle(filters.parametricEq, handle: handle),
    ),
  );
}

class Filter<T extends FilterBase> {
  /// Wrapper around a specific [SoLoud] filter, providing a consistent interface no
  /// matter which type of [SongPlayer] we are currently working with.
  Filter(this.modify);

  /// The function used to manipulate the underlying [SoLoud] filter(s).
  ///
  /// The [apply] method can potentially be called multiple times on multiple
  /// different [AudioSource]s, allowing implementations like the [MultiPlayer].
  final void Function(void Function(T filter, {SoundHandle? handle}) apply)
  modify;

  /// Whether this filter is active.
  bool get isActive => isActiveNotifier.value;
  final ValueNotifier<bool> isActiveNotifier = ValueNotifier(false);

  /// Activate this filter.
  ///
  /// If this filter is already active, does nothing.
  void activate() {
    modify((filter, {handle}) {
      if (!filter.isActive) filter.activate();
    });
    isActiveNotifier.value = true;
  }

  /// Deactivate this filter.
  ///
  /// If this filter is not active, does nothing.
  void deactivate() {
    modify((filter, {handle}) {
      if (filter.isActive) filter.deactivate();
    });
    isActiveNotifier.value = false;
  }
}
