import 'dart:io';

import 'package:flutter/material.dart';
import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';
import 'package:musbx/music_player/demixer/host.dart';
import 'package:path_provider/path_provider.dart';

class DemixerApi {
  /// The version of the server that this is compatible with.
  static const String version = "1.0";

  /// The server hosting the Demixer API.
  static const List<Host> _hosts = [
    // Host("192.168.1.174:4242"),
    Host("musbx.agardh.se:4242"),
    Host("brunnby.homeip.net:4242"),
  ];

  /// The directory where stems are saved.
  static final Future<Directory> demixerDirectory =
      _createTempDirectory("demixer");

  static Future<Directory> getSongDirectory(String songName) async =>
      _createTempDirectory("${(await demixerDirectory).path}/$songName");

  /// The directory where Youtube files are saved.
  static final Future<Directory> youtubeDirectory =
      _createTempDirectory("youtube");

  /// Creates a temporary directory with the given [name].
  /// If the directory already exists, does nothing.
  static Future<Directory> _createTempDirectory(String name) async {
    var dir = Directory("${(await getTemporaryDirectory()).path}/$name/");
    await dir.create(recursive: true);
    return dir;
  }

  /// Find a host that is available and whose version matches [version].
  ///
  /// Throws if no such host was found.
  static Future<Host> findHost() async {
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
