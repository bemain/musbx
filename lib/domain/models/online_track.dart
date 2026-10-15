/// A track found online that can be added to the library as a [Song].
///
/// Text fields are already unescaped and ready to display.
final class OnlineTrack {
  const OnlineTrack({
    required this.id,
    required this.title,
    this.artist,
    this.artUri,
    this.duration,
    required this.sourceUrl,
    this.isPreview = false,
  });

  /// Identifies this track with the provider it was found on. Becomes the
  /// [Song.id] when added.
  final String id;

  /// The title of the track.
  final String title;

  /// The name of whoever published the track, if known.
  final String? artist;

  /// The track's artwork, if it has any.
  final Uri? artUri;

  /// The length of the track, if known.
  final Duration? duration;

  /// The page the audio is streamed from.
  final Uri sourceUrl;

  /// Whether only a short excerpt of the track can be streamed.
  final bool isPreview;
}
