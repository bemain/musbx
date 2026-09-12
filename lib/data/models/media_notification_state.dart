class MediaNotificationState {
  MediaNotificationState({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.genre,
    this.artUri,
    required this.duration,
    required this.isPlaying,
    required this.position,
    required this.speed,
  });

  final String id;

  final String title;
  final String? artist;
  final String? album;
  final String? genre;

  final Uri? artUri;
  final Duration? duration;

  final bool isPlaying;

  final Duration position;

  final double speed;
}
