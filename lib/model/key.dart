import 'package:musbx/model/pitch_class.dart';

enum KeyType {
  major("", [0, 2, 4, 5, 7, 9, 11]),
  minor("m", [0, 2, 3, 5, 7, 8, 10]);

  const KeyType(this.abbreviation, this.intervalPattern);

  final String abbreviation;

  final List<int> intervalPattern;

  @override
  String toString() => abbreviation;
}

/// Representation of a musical key.
///
/// A key is the group of pitches that forms the basis of most western music.
/// A key is characterised by its [tonic] which provides a sense of arrival or rest,
/// and its [type] which describes the relationship between the [tonic] and the remaining [notes] in the key.
class Key {
  const Key(this.tonic, this.type);

  const Key.major(this.tonic) : type = KeyType.major;
  const Key.minor(this.tonic) : type = KeyType.minor;

  final PitchClass tonic;
  final KeyType type;

  List<PitchClass> get notes => type.intervalPattern
      .map((int interval) => tonic.transposed(interval))
      .toList();

  String get abbreviation => "$tonic${type.abbreviation}";

  @override
  String toString() => abbreviation;
}
