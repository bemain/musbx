import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';
import 'package:musbx/music_player/demixer/host.dart';
import 'package:path_provider/path_provider.dart';

class DemixerApi {
  static const String version = "1.1";

  /// The server hosting the Demixer API.
  static const List<Host> _hosts = [
    Host("192.168.1.174:4242"),
    Host("musbx.agardh.se:4242"),
  ];

  /// The directory where stems are saved.
  static final Future<Directory> stemDirectory =
      _createTempDirectory("demixer");

  /// The directory where Youtube files are saved.
  static final Future<Directory> youtubeDirectory =
      _createTempDirectory("youtube");

  static Future<Directory> _createTempDirectory(String dirName) async {
    var dir = Directory("${(await getTemporaryDirectory()).path}/$dirName/");
    if (await dir.exists()) await dir.delete(recursive: true); // Clear
    await dir.create(recursive: true);
    return dir;
  }

  /// Find a host that is available and whose version matches [version].
  ///
  /// Throws if no such host was found.
  Future<Host> findHost() async {
    /// Whether at least one host is available.
    bool hostAvailable = false;

    for (Host host in _hosts) {
      try {
        String hostVersion = await host.getVersion();
        if (hostVersion == version) return host;

        debugPrint(
            "DEMIXER: The host's version ($hostVersion) does not match DemixerAPI's version ($version): $host");
        hostAvailable = true;
      } catch (_) {
        debugPrint("DEMIXER: Host is not available: $host");
      }
    }

    throw hostAvailable
        ? const OutOfDateException()
        : const NoHostAvailableException();
  }
}
