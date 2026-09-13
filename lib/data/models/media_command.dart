/// Something the user pressed on the media notification or lock screen.
sealed class MediaCommand {
  static Play get play => Play._();

  static Pause get pause => Pause._();

  static Stop get stop => Stop._();

  static Seek seek(Duration position) => Seek._(position);
}

class Play extends MediaCommand {
  Play._();
}

class Pause extends MediaCommand {
  Pause._();
}

class Stop extends MediaCommand {
  Stop._();
}

class Seek extends MediaCommand {
  Seek._(this.position);

  final Duration position;
}
