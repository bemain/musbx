extension NumIterableExtension on Iterable<num> {
  /// The sum of all the elements in this list.
  num get sum {
    return fold(0, (sum, value) => sum + value);
  }

  /// The mean of the elements in this list, or `null` if empty.
  double? get mean {
    var sum = 0.0;
    var count = 0;
    for (final value in this) {
      sum += value;
      count++;
    }
    return count == 0 ? null : sum / count;
  }

  /// The maximum value of all elements in this list, or `null` if empty.
  num? get max {
    if (isEmpty) return null;

    num max = first;
    for (final value in this) {
      if (value > max) max = value;
    }
    return max;
  }
}
