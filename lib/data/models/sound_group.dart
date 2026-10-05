import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/domain/models/stem_type.dart';

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
