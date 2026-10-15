import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/chroma.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';

void main() {
  group("PitchClass.fromChroma", () {
    test("spells natural chromas without an accidental", () {
      for (final accidental in Accidental.values) {
        expect(
          PitchClass.fromChroma(Chroma.f, preferredAccidental: accidental),
          const PitchClass.f(),
        );
        expect(
          PitchClass.fromChroma(Chroma.e, preferredAccidental: accidental),
          const PitchClass.e(),
        );
      }
    });

    test("uses the preferred accidental for non-natural chromas", () {
      expect(
        PitchClass.fromChroma(
          Chroma.fSharp,
          preferredAccidental: Accidental.flat,
        ),
        const PitchClass.gFlat(),
      );
      expect(
        PitchClass.fromChroma(
          Chroma.aSharp,
          preferredAccidental: Accidental.sharp,
        ),
        const PitchClass.aSharp(),
      );
    });
  });
}
