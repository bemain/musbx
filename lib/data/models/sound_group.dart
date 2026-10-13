import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/domain/models/stem_type.dart';

/// The sounds a song is played as, driven together through one voice group.
///
/// Keyed by stem, with a single `null` entry for a song that is not demixed.
class SoundGroup {
  SoundGroup({
    required this.sources,
    required this.handles,
    required this.groupHandle,
  });

  final Map<StemType?, AudioSource> sources;
  final Map<StemType?, SoundHandle> handles;
  final SoundHandle groupHandle;
}
