import 'package:flutter/material.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:pub_semver/pub_semver.dart';

sealed class MusbxApiError implements Exception {}

final class NoHostAvailable extends MusbxApiError {
  @override
  String toString() => "No Musbx API host is available";
}

final class OutOfDate extends MusbxApiError {
  @override
  String toString() => "The app is out of date with the Musbx API server";
}

class MusbxApi {
  /// The version of the API that this is compatible with.
  static final VersionConstraint version = VersionConstraint.parse("^0.4.0");

  /// The servers hosting the Musbx API.
  static final List<String> _hostUrls = [
    "http://nextcloud.agardh.se:4242",
    "http://musbx.agardh.se:4242",
  ];

  /// Find a host that is available and version is compatible with the app's [version].
  ///
  /// Throws if no such host was found.
  static Future<MusbxApiClient> getClient() async {
    /// Whether at least one host is available.
    bool hostAvailable = false;

    for (String hostUrl in _hostUrls) {
      final client = MusbxApiClient(hostUrl);
      try {
        final Version clientVersion = await client.version();
        if (version.allows(clientVersion)) {
          return client;
        }

        debugPrint(
          "[MUSBX API] The host's version ($clientVersion) is not compatible with the app's version ($version): $hostUrl",
        );
        hostAvailable = true;
      } catch (_) {
        debugPrint("[MUSBX API] Host is not available: $hostUrl");
      }
    }

    return throw hostAvailable ? OutOfDate() : NoHostAvailable();
  }
}
