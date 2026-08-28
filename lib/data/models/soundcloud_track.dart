import 'package:musbx/utils/utils.dart';

/// Represents a SoundCloud track with all its metadata and streaming information.
class SoundCloudTrack {
  const SoundCloudTrack({
    required this.id,
    required this.title,
    required this.username,
    this.artworkUrl,
    this.waveformUrl,
    required this.permalinkUrl,
    required this.duration,
    bool? streamable,
    bool? downloadable,
    required this.policy,
    required this.transcodings,
  }) : streamable = streamable ?? false,
       downloadable = downloadable ?? false;

  /// The unique identifier for this track on SoundCloud.
  final int id;

  /// The title of the track.
  final String title;

  /// The username of the track's creator/artist.
  final String? username;

  /// URL to the track's artwork image, if available.
  final String? artworkUrl;

  /// URL to the track's waveform.
  final String? waveformUrl;

  /// The permalink URL to view this track on SoundCloud.
  final String permalinkUrl;

  /// The duration of the track.
  final Duration? duration;

  /// Whether the track can be streamed.
  final bool streamable;

  /// Whether the track is available for download.
  final bool downloadable;

  /// The policy of the track (e.g. SNIP for tracks that only provide a preview).
  final String? policy;

  /// List of available transcoding formats for this track.
  final List<SoundCloudTrackTranscoding> transcodings;

  /// Creates a [SoundCloudTrack] from a JSON object.
  factory SoundCloudTrack.fromJson(Json json) {
    return SoundCloudTrack(
      id: json['id'] as int,
      title: json['title'] as String,
      username: json['user']?['username'] as String?,
      artworkUrl: json['artwork_url'] as String?,
      waveformUrl: json['waveform_url'] as String?,
      permalinkUrl: json['permalink_url'] as String,
      duration: json['duration'] == null
          ? null
          : Duration(milliseconds: json['duration'] as int),
      streamable: json['streamable'] as bool?,
      downloadable: json['downloadable'] as bool?,
      policy: json['policy'] as String?,
      transcodings:
          (json['media']?['transcodings'] as List<dynamic>?)
              ?.map((e) => SoundCloudTrackTranscoding.fromJson(e as Json))
              .toList() ??
          [],
    );
  }
}

/// Represents a transcoding format for a SoundCloud track.
class SoundCloudTrackTranscoding {
  /// Creates a new [SoundCloudTrackTranscoding] instance.
  const SoundCloudTrackTranscoding({
    required this.url,
    required this.mimeType,
    required this.protocol,
    required this.quality,
  });

  /// The URL to access this transcoding format.
  final String url;

  /// The MIME type of the audio format (e.g., "audio/mpeg").
  final String mimeType;

  /// The protocol used for streaming (e.g., "progressive" for direct download).
  final String protocol;

  /// The quality level of this transcoding (e.g., "sq", "hq").
  final String quality;

  /// Creates a [SoundCloudTrackTranscoding] from a JSON object.
  factory SoundCloudTrackTranscoding.fromJson(Json json) {
    return SoundCloudTrackTranscoding(
      url: json['url'] as String,
      mimeType: json['format']?['mime_type'] as String,
      protocol: json['format']?['protocol'] as String,
      quality: json['quality'] as String,
    );
  }
}
