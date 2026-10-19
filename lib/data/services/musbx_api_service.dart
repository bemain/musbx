import 'package:flutter/material.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:pub_semver/pub_semver.dart';

/// A reason why no Musbx API server could be used.
sealed class MusbxApiError implements Exception {}

/// None of the known hosts answered.
final class NoHostAvailable extends MusbxApiError {
  @override
  String toString() => "No Musbx API host is available";
}

/// A host answered, but speaks a version of the API this app does not.
final class OutOfDate extends MusbxApiError {
  @override
  String toString() => "The app is out of date with the Musbx API server";
}

/// The known Musbx API servers, and which of them this app can talk to.
class MusbxApiService {
  /// Create a service that talks to the first of [hostUrls] whose API version
  /// [version] allows.
  ///
  /// No request is made until [client] is first called. [clientFor] builds the
  /// client for a host, so a test can hand out fakes instead of reaching the
  /// network.
  MusbxApiService({
    List<String> hostUrls = const [
      "http://nextcloud.agardh.se:4242",
      "http://musbx.agardh.se:4242",
    ],
    VersionConstraint? version,
    @visibleForTesting
    MusbxApiClient Function(String) clientFor = MusbxApiClient.new,
  }) : _hostUrls = hostUrls,
       _version = version ?? VersionConstraint.parse("^0.5.0"),
       _clientFor = clientFor;

  /// The servers hosting the Musbx API, tried in order.
  final List<String> _hostUrls;

  /// The version of the API that this is compatible with.
  final VersionConstraint _version;

  /// Builds the client for the host at a given URL.
  final MusbxApiClient Function(String) _clientFor;

  /// The latest search for a host, or `null` before the first search and after
  /// a failed one.
  Future<MusbxApiClient>? _client;

  /// A client for the first compatible host, found once and then reused.
  ///
  /// Callers that ask while a search is running share it. A failed search is
  /// forgotten, so the next call searches again.
  ///
  /// Throws [OutOfDate] if a host answered but none was compatible, and
  /// [NoHostAvailable] if none answered.
  Future<MusbxApiClient> client() async {
    final search = _client ??= _findHost();
    try {
      return await search;
    } on MusbxApiError {
      if (identical(_client, search)) _client = null;
      rethrow;
    }
  }

  /// A client for the first host that answers and is compatible with
  /// [_version].
  ///
  /// Throws [OutOfDate] if a host answered but none was compatible, and
  /// [NoHostAvailable] if none answered.
  Future<MusbxApiClient> _findHost() async {
    // Whether at least one host answered.
    bool hostAvailable = false;

    for (String hostUrl in _hostUrls) {
      final client = _clientFor(hostUrl);
      try {
        final Version v = await client.version();
        if (_version.allows(v)) {
          return client;
        }

        debugPrint(
          "[MUSBX API] The host's version ($v) is not compatible with the app's version ($_version): $hostUrl",
        );
        hostAvailable = true;
      } catch (_) {
        debugPrint("[MUSBX API] Host is not available: $hostUrl");
      }
    }

    throw hostAvailable ? OutOfDate() : NoHostAvailable();
  }
}
