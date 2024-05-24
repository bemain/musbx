import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:musbx/keys.dart';
import 'package:musbx/music_player/musbx_api/chords_api.dart';
import 'package:musbx/music_player/musbx_api/demixer_api.dart';
import 'package:musbx/music_player/musbx_api/youtube_api.dart';

class NoHostAvailableException implements Exception {
  final String? msg;

  const NoHostAvailableException([this.msg]);

  @override
  String toString() => msg ?? 'No host is available';
}

class OutOfDateException implements Exception {
  final String? msg;

  const OutOfDateException([this.msg]);

  @override
  String toString() => msg ?? 'The app is out of date with the server';
}

class MusbxApi {
  /// The version of the server that this is compatible with.
  static const MusbxApiVersion version = MusbxApiVersion(
      youtubeApiVersion: "1", demixerApiVersion: "2", chordsApiVersion: "1");

  /// The servers hosting the Musbx API.
  static final List<String> _hostUrls = [
    "192.168.100.200:4242",
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

  /// Find a host that is available and whose ChordsApi version matches [version].
  ///
  /// Throws if no such host was found.
  static Future<ChordsApiHost> findChordsHost() async {
    /// Whether at least one host is available.
    bool hostAvailable = false;

    for (String hostUrl in _hostUrls) {
      ChordsApiHost host = ChordsApiHost(hostUrl);
      try {
        MusbxApiVersion hostVersion = await host.getVersion();
        if (hostVersion.chordsApiVersion == version.chordsApiVersion) {
          return host;
        }

        debugPrint(
            "[DEMIXER] The host's ChordsApi version (${hostVersion.chordsApiVersion}) does not match the app's ChordsApi version (${version.chordsApiVersion}): $host");
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

class MusbxApiVersion {
  const MusbxApiVersion({
    required this.youtubeApiVersion,
    required this.demixerApiVersion,
    required this.chordsApiVersion,
  });

  /// The version of the Youtube API.
  final String youtubeApiVersion;

  /// The version of the Demixer API.
  final String demixerApiVersion;

  /// The version of the Chords API.
  final String chordsApiVersion;

  @override
  bool operator ==(Object other) {
    return other is MusbxApiVersion &&
        other.youtubeApiVersion == youtubeApiVersion &&
        other.demixerApiVersion == demixerApiVersion &&
        other.chordsApiVersion == chordsApiVersion;
  }

  @override
  int get hashCode => Object.hash(youtubeApiVersion, demixerApiVersion);
}

abstract class MusbxApiHost {
  static const Map<String, String> authHeaders = {"Authorization": musbxApiKey};

  MusbxApiHost(this.address, {this.https = false});

  final String address;

  final bool https;

  Uri Function(String, [String, Map<String, dynamic>?]) get uriConstructor =>
      (https ? Uri.https : Uri.http);

  /// Perform a `GET` request to the server at the requested [route].
  /// The [route] should begin with a leading slash ("/").
  Future<http.Response> get(String route, {Map<String, String>? headers}) {
    return http.get(
      uriConstructor(address, route),
      headers: {...MusbxApiHost.authHeaders, ...?headers},
    );
  }

  /// Perform a `POST` request to the server at the requested [route].
  /// The [route] should begin with a leading slash ("/").
  Future<http.Response> post(
    String route, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return http.post(
      uriConstructor(address, route),
      body: body,
      headers: {...MusbxApiHost.authHeaders, ...?headers},
    );
  }

  /// Get the version of this host's MusbxApi.
  Future<MusbxApiVersion> getVersion({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final response = await get("/version").timeout(timeout);

    Map<String, dynamic> json = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw HttpException(
        jsonDecode(response.body)["message"],
        uri: response.request?.url,
      );
    }

    return MusbxApiVersion(
      youtubeApiVersion: json["youtube"],
      demixerApiVersion: json["demixer"],
      chordsApiVersion: json["chords"],
    );
  }

  @override
  String toString() {
    return "MusbxApiHost($address)";
  }
}
