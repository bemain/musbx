import 'package:flutter_soloud/flutter_soloud.dart';

class ToneGroup {
  ToneGroup({
    required this.sources,
    required this.handles,
    required this.groupHandle,
  });

  final List<AudioSource> sources;
  final List<SoundHandle> handles;
  final SoundHandle groupHandle;
}
