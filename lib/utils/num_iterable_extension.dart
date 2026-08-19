extension NumIterableExtension on Iterable<num> {
  /// The sum of all the elements in this list.
  num sum() {
    return fold(0, (a, b) => a + b);
  }

  /// The mean of the elements in this list, or `null` if empty.
  double? mean() {
    var sum = 0.0;
    var count = 0;
    for (final value in this) {
      sum += value;
      count++;
    }
    return count == 0 ? null : sum / count;
  }
}
