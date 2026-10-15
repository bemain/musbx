import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:meta/meta.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/models/soundcloud_track.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/soundcloud_api_client.dart';
import 'package:musbx/domain/models/online_track.dart';
import 'package:musbx/utils/history_handler.dart';
import 'package:musbx/utils/result.dart';

/// Finds tracks online to add to the library, and remembers what was searched
/// for.
///
/// Notifies listeners when [history] changes.
abstract class TrackSearchRepository extends ChangeNotifier {
  TrackSearchRepository({required FileCacheService fileCache})
    : _fileCache = fileCache {
    history.fetch();
  }

  final FileCacheService _fileCache;

  /// Previous queries that led to a track being picked.
  late final HistoryHandler<String> history = HistoryHandler<String>(
    file: _fileCache.persistent.file(
      "search_history.json",
    ),
    fromJson: (json) => json as String,
    toJson: (value) => value,
  )..addListener(notifyListeners);

  /// The tracks matching [query].
  ///
  /// [Unavailable] when there is no search service on this device.
  @useResult
  Future<Result<List<OnlineTrack>>> searchTracks(String query);
}

/// Searches SoundCloud.
class TrackSearchRepositorySoundCloud extends TrackSearchRepository {
  TrackSearchRepositorySoundCloud({
    required ServiceLoader<SoundCloudApiClient> apiClient,
    required super.fileCache,
  }) : _apiClient = apiClient;

  final ServiceLoader<SoundCloudApiClient> _apiClient;

  @override
  Future<Result<List<OnlineTrack>>> searchTracks(String query) =>
      OptionalService.guard(
        () async => (await _apiClient.value.searchTracks(
          query,
        )).map(_fromSoundCloud).toList(),
        "SoundCloud search service disabled",
      );

  OnlineTrack _fromSoundCloud(SoundCloudTrack track) {
    final unescape = HtmlUnescape();

    return OnlineTrack(
      id: track.id.toString(),
      title: unescape.convert(track.title),
      artist: track.username == null
          ? null
          : unescape.convert(track.username!),
      artUri: track.artworkUrl == null
          ? null
          : Uri.tryParse(track.artworkUrl!),
      duration: track.duration,
      sourceUrl: Uri.parse(track.permalinkUrl),
      isPreview: track.isPreview,
    );
  }
}
