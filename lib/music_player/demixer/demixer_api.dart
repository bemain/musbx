import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';
import 'package:musbx/music_player/demixer/host.dart';

class MusbxApi {
  /// The version of the server that this is compatible with.
  static const MusbxApiVersion version = MusbxApiVersion(
    youtubeApiVersion: "1",
    demixerApiVersion: "2",
  );

  /// The servers hosting the Musbx API.
  static final List<String> _hostUrls = [
    "192.168.1.174:4242",
    "brunnby.homeip.net:4242",
    "musbx.agardh.se:4242",
  ];

  /// Find a host that is available and whose YoutubeApi version matches [version].
  ///
  /// Throws if no such host was found.
  static Future<YoutubeApiHost> findYoutubeHost() async {
    /// Whether at least one host is available.
    bool hostAvailable = false;

    for (String hostUrl in _hostUrls) {
      YoutubeApiHost host = YoutubeApiHost(hostUrl);
      try {
        MusbxApiVersion hostVersion = await host.getVersion();
        if (hostVersion.youtubeApiVersion == version.youtubeApiVersion) {
          return host;
        }

        debugPrint(
            "[YOUTUBE] The host's YoutubeApi version (${hostVersion.youtubeApiVersion}) does not match the app's YoutubeApi version (${version.youtubeApiVersion}): $hostUrl");
        hostAvailable = true;
      } catch (_) {
        debugPrint("[YOUTUBE] Host is not available: $host");
      }
    }

    throw hostAvailable
        ? const OutOfDateException()
        : const NoHostAvailableException();
  }

  /// Find a host that is available and whose DemixerApi version matches [version].
  ///
  /// Throws if no such host was found.
  static Future<DemixerApiHost> findDemixerHost() async {
    /// Whether at least one host is available.
    bool hostAvailable = false;

    for (String hostUrl in _hostUrls) {
      DemixerApiHost host = DemixerApiHost(hostUrl);
      try {
        MusbxApiVersion hostVersion = await host.getVersion();
        if (hostVersion.demixerApiVersion == version.demixerApiVersion) {
          return host;
        }

        debugPrint(
            "[DEMIXER] The host's DemixerApi version (${hostVersion.demixerApiVersion}) does not match the app's DemixerApi version (${version.demixerApiVersion}): $host");
        hostAvailable = true;
      } catch (_) {
        debugPrint("[DEMIXER] Host is not available: $host");
      }
    }

    throw hostAvailable
        ? const OutOfDateException()
        : const NoHostAvailableException();
  }
}
