import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/music/chroma.dart';

void main() {
  test("transposed wraps around the octave in both directions", () {
    expect(Chroma.c.transposed(7), Chroma.g);
    expect(Chroma.b.transposed(1), Chroma.c);
    expect(Chroma.c.transposed(-1), Chroma.b);
    expect(Chroma.a.transposed(-21), Chroma.c);
  });

  test("fifthsFromC follows the circle of fifths", () {
    expect(Chroma.c.fifthsFromC, 0);
    expect(Chroma.g.fifthsFromC, 1);
    expect(Chroma.f.fifthsFromC, -1);
    expect(Chroma.aSharp.fifthsFromC, -2);
    expect(Chroma.fSharp.fifthsFromC, 6);
  });
}
