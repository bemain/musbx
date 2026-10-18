import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/music/accidental.dart';
import 'package:musbx/domain/models/music/key.dart';
import 'package:musbx/domain/models/music/pitch_class.dart';

void main() {
  String notesOf(Key key) => key.notes.map((n) => n.abbreviation).join(" ");

  test("notes are spelled with the key's own accidentals", () {
    expect(notesOf(const Key.major(PitchClass.c())), "C D E F G A B");
    expect(notesOf(const Key.minor(PitchClass.a())), "A B C D E F G");
    expect(notesOf(const Key.major(PitchClass.d())), "D E F♯ G A B C♯");
    expect(notesOf(const Key.major(PitchClass.f())), "F G A B♭ C D E");
    expect(notesOf(const Key.major(PitchClass.eFlat())), "E♭ F G A♭ B♭ C D");
  });

  test("key signature is shared with the relative major", () {
    final cases = {
      const Key.major(PitchClass.c()): (Accidental.natural, 0),
      const Key.major(PitchClass.g()): (Accidental.sharp, 1),
      const Key.major(PitchClass.f()): (Accidental.flat, 1),
      const Key.minor(PitchClass.e()): (Accidental.sharp, 1),
      const Key.minor(PitchClass.d()): (Accidental.flat, 1),
      const Key.major(PitchClass.fSharp()): (Accidental.sharp, 6),
      const Key.minor(PitchClass.c()): (Accidental.flat, 3),
    };
    cases.forEach((key, signature) {
      expect((key.accidental, key.nAccidentals), signature, reason: "$key");
    });
  });

  test("parallel switches between relative major and minor", () {
    const cMajor = Key.major(PitchClass.c());
    expect(cMajor.parallel, const Key.minor(PitchClass.a()));
    expect(cMajor.parallel.parallel, cMajor);
    expect(
      const Key.major(PitchClass.eFlat()).parallel,
      const Key.minor(PitchClass.c()),
    );
  });

  test("transposed keeps the type", () {
    expect(
      const Key.minor(PitchClass.a()).transposed(2),
      const Key.minor(PitchClass.b()),
    );
  });

  test("abbreviation", () {
    expect(const Key.minor(PitchClass.fSharp()).abbreviation, "F♯m");
    expect(const Key.minor(PitchClass.fSharp()).toString(), "F♯m");
    expect(const Key.major(PitchClass.bFlat()).abbreviation, "B♭");
  });
}
