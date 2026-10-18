import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/utils/result.dart';

void main() {
  test("wraps a value", () async {
    final result = await OptionalService.guard(() async => 1, "reason");
    expect(result.asOk, 1);
  });

  test("turns ServiceDisabled into Unavailable", () async {
    final result = await OptionalService.guard<int>(
      () async => throw ServiceDisabled(),
      "it is off",
    );
    expect(
      result,
      isA<Unavailable<int>>()
          .having((r) => r.reason, "reason", "it is off")
          .having((r) => r.isRetryable, "isRetryable", isFalse),
    );
  });

  test("turns anything else into a retryable Failure", () async {
    final result = await OptionalService.guard<int>(
      () async => throw Exception("boom"),
      "reason",
    );
    expect(result, isNot(isA<Unavailable<int>>()));
    expect(
      result,
      isA<Failure<int>>().having((r) => r.isRetryable, "retryable", isTrue),
    );
  });
}
