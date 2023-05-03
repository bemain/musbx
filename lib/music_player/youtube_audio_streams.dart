import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Used internally to get audio streams from YouTube.
final YoutubeExplode _youtubeExplode = YoutubeExplode();

/// Get the audio stream of a YouTube video with [videoId].
Future<Uri> getAudioStream(String videoId) async {
  StreamManifest manifest =
      await _youtubeExplode.videos.streams.getManifest(videoId);
  AudioOnlyStreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();

  return streamInfo.url;
}
