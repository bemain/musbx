import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/domain/models/stem_type.dart';

/// Sounds played through one voice group, so that they are paused, resumed and
/// sped up together.
///
/// [sources] and [handles] are parallel: each handle plays the source at the
/// same index.
abstract class SoundGroup {
  SoundGroup({
    required this.sources,
    required this.handles,
    required this.groupHandle,
  });

  final List<AudioSource> sources;
  final List<SoundHandle> handles;
  final SoundHandle groupHandle;
}

/// The sounds a song is played as.
///
/// [parts] is parallel to [sources] and [handles], and holds a single `null`
/// for a song that is not demixed.
class SongPartsGroup extends SoundGroup {
  SongPartsGroup({
    required this.parts,
    required super.sources,
    required super.handles,
    required super.groupHandle,
  });

  final List<StemType?> parts;
}

/// The generated tones the drone plays.
class ToneGroup extends SoundGroup {
  ToneGroup({
    required super.sources,
    required super.handles,
    required super.groupHandle,
  });
}
