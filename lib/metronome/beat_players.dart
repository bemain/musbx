import 'package:assets_audio_player/assets_audio_player.dart';

enum SoundType {
  sticks,
  pop1,
  pop2,
}

class MetronomeBeatPlayers {
  /// Number of players.
  int get length => _players.length;
  set length(int value) {
    // Dispose old players
    for (AssetsAudioPlayer player in _players) {
      player.dispose();
    }
    // Create new ones
    _players =
        List.generate(value, ((sound) => _soundPlayer(SoundType.sticks)));
  }

  late List<AssetsAudioPlayer> _players =
      List.generate(4, ((sound) => _soundPlayer(SoundType.sticks)));

  /// Get player with [index].
  AssetsAudioPlayer operator [](int index) {
    return _players[index];
  }

  /// Set [soundType] of player with [index].
  void operator []=(int index, SoundType soundType) {
    _players[index].open(
      Audio("assets/${soundType.index}.mp3"),
      autoStart: false,
    );
  }

  /// Create new player with [soundType].
  static AssetsAudioPlayer _soundPlayer(SoundType soundType) {
    return AssetsAudioPlayer.newPlayer()
      ..open(
        Audio("assets/${soundType.index}.mp3"),
        autoStart: false,
      );
  }
}
