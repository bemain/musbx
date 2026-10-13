import 'package:flutter_soloud/flutter_soloud.dart';

/// The generated tones the drone plays, paused and resumed together through
/// one voice group.
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
