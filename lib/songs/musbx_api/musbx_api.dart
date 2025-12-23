import 'package:flutter/material.dart';
import 'package:musbx/songs/musbx_api/client.dart';
import 'package:pub_semver/pub_semver.dart';

class NoHostAvailableException implements Exception {
  final String? msg;

  const NoHostAvailableException([this.msg]);

  @override
  String toString() => msg ?? "No host is available";
}

class OutOfDateException implements Exception {
  final String? msg;

  const OutOfDateException([this.msg]);

  @override
  String toString() => msg ?? "The app is out of date with the server";
}

class MusbxApi {
  /// The version of the API that this is compatible with.
  static final VersionConstraint version = VersionConstraint.parse("^0.4.0");

  /// The servers hosting the Musbx API.
  static final List<String> _hostUrls = [
    "http://brunnby.homeip.net:4242",
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

    throw hostAvailable
        ? const OutOfDateException()
        : const NoHostAvailableException();
  }
}
