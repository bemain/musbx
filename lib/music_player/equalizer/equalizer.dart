import 'package:just_audio/just_audio.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/music_player/music_player_component.dart';

class Equalizer extends MusicPlayerComponent {
  /// The [AndroidEqualizer] used internally to adjust the gain for different frequency bands.
  final AndroidEqualizer androidEqualizer = AndroidEqualizer();

  Future<AndroidEqualizerParameters> get parameters =>
      androidEqualizer.parameters;

  @override
  void initialize(MusicPlayer musicPlayer) {
    enabledNotifier.addListener(() {
      androidEqualizer.setEnabled(enabled);
    });
  }
}
