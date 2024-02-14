import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:musbx/keys.dart';

import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';
import 'package:path_provider/path_provider.dart';

enum StemFileType {
  mp3,
  wav,
}

class UploadResponse {
  /// Returned when uploading a song to the server.
  ///
  /// If [jobId] is not `null`, the server has begun separating the song.
  /// Check the job status with [jobProgress] to make sure the separation job has completed before trying to download stems.
  const UploadResponse(this.songId, {this.jobId});

  /// The name of the folder where the stems are saved. Used to download the stems.
  final String songId;

  /// The name of the job that separates the song into stems,
  /// if the stems were not found in the cache.
  final String? jobId;
}

/// A response from a source separation stream.
class SeparationResponse {
  /// Returned when checking the status of a job.
  const SeparationResponse(this.progress);

  /// The current progress of the separation job.
  final int progress;
}

class MusbxApiVersion {
  const MusbxApiVersion({
    required this.youtubeApiVersion,
    required this.demixerApiVersion,
  });

  /// The version of the Youtube API.
  final String youtubeApiVersion;

  /// The version of the Demixer API.
  final String demixerApiVersion;

  @override
  bool operator ==(Object other) {
    return other is MusbxApiVersion &&
        other.youtubeApiVersion == youtubeApiVersion &&
        other.demixerApiVersion == demixerApiVersion;
  }

  @override
  int get hashCode => Object.hash(youtubeApiVersion, demixerApiVersion);
}

/// The stems that can be requested from the server.
enum StemType {
  drums,
  bass,
  vocals,
  other,
}

/// Creates a temporary directory with the given [name].
/// If the directory already exists, does nothing.
Future<Directory> _createTempDirectory(String name) async {
  var dir = Directory("${(await getTemporaryDirectory()).path}/$name/");
  await dir.create(recursive: true);
  return dir;
}

abstract class MusbxApiHost {
  static const Map<String, String> _authHeaders = {
    "Authorization": musbxApiKey
  };

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
      headers: {...MusbxApiHost._authHeaders, ...?headers},
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
      headers: {...MusbxApiHost._authHeaders, ...?headers},
    );
  }

  /// Get the version of this host's MusbxApi.
  Future<MusbxApiVersion> getVersion({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final response = await get("/version").timeout(timeout);

    if (response.statusCode != 200) throw const ServerException();
    Map<String, dynamic> json = jsonDecode(response.body);

    return MusbxApiVersion(
      youtubeApiVersion: json["youtube"],
      demixerApiVersion: json["demixer"],
    );
  }

  @override
  String toString() {
    return "MusbxApiHost($address)";
  }
}

class YoutubeApiHost extends MusbxApiHost {
  YoutubeApiHost(super.address, {super.https});

  /// The directory where Youtube files are saved.
  static final Future<Directory> youtubeDirectory =
      _createTempDirectory("youtube");

  /// Download the audio for a Youtube video.
  Future<File> downloadYoutubeSong(String youtubeId) async {
    var response = await get("/download/$youtubeId");

    if (response.statusCode == 497) throw const FileTooLargeException();
    if (response.statusCode != 200) throw const ServerException();

    assert(response.headers.containsKey("content-disposition"));
    String fileName =
        response.headers["content-disposition"]!.split("filename=").last.trim();
    assert(fileName.isNotEmpty);
    File file = File("${(await youtubeDirectory).path}/$fileName");
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}

class DemixerApiHost extends MusbxApiHost {
  DemixerApiHost(super.address, {super.https});

  /// The directory where demixer saves files.
  static final Future<Directory> demixerDirectory =
      _createTempDirectory("demixer");

  /// The directory where stems for song with name [songId] are saved.
  /// Will be a subdirectory of [demixerDirectory].
  static Future<Directory> getSongDirectory(String songId) async =>
      _createTempDirectory("demixer/$songId");

  /// Upload a local [file] to the server.
  ///
  /// The stem files generated from the uploaded file will be of the type [desiredStemFilesType].
  Future<UploadResponse> uploadFile(
    File file, {
    StemFileType desiredStemFilesType = StemFileType.mp3,
  }) async {
    Uri url = uriConstructor(address, "/upload");
    var request = http.MultipartRequest("POST", url);
    request.headers.addAll({
      ...MusbxApiHost._authHeaders,
      "FileType": desiredStemFilesType.name,
    });
    request.files.add(await http.MultipartFile.fromPath(
      "file",
      file.path,
      contentType: MediaType("audio", file.path.split('.').last),
    ));

    var response = await request.send();

    if (response.statusCode == 488) throw const ServerOverloadedxception();
    if (response.statusCode == 497) throw const FileTooLargeException();
    if (response.statusCode != 201) throw const ServerException();

    Map<String, dynamic> json =
        jsonDecode(await response.stream.bytesToString());
    String songId = json["song_id"];

    return UploadResponse(songId, jobId: json["job"]);
  }

  /// Upload a YouTube song to the server.
  ///
  /// The stem files generated from the uploaded file will be of the type [desiredStemFilesType].
  Future<UploadResponse> uploadYoutubeSong(
    String youtubeId, {
    StemFileType desiredStemFilesType = StemFileType.mp3,
  }) async {
    var response = await post("/upload/$youtubeId", headers: {
      "FileType": desiredStemFilesType.name,
    });

    if (response.statusCode == 499) throw const YoutubeVideoNotFoundException();
    if (response.statusCode == 488) throw const ServerOverloadedxception();
    if (response.statusCode == 497) throw const FileTooLargeException();

    Map<String, dynamic> json = jsonDecode(response.body);
    String songId = json["song_id"];

    if (response.statusCode == 200) {
      return UploadResponse(songId);
    }

    if (response.statusCode != 201) throw const ServerException();

    return UploadResponse(songId, jobId: json["job"]);
  }

  /// Check the progress of a separation job.
  ///
  /// The progress is checked every [checkEvery] seconds until the job can no
  /// longer be found (it is completed) and a [JobNotFoundException] is thrown.
  Stream<SeparationResponse> jobProgress(
    String jobId, {
    Duration checkEvery = const Duration(seconds: 5),
  }) async* {
    int progress = 0;

    while (true) {
      // Check job status
      var response = await get("/job/$jobId");
      if (response.statusCode == 489) {
        yield* Stream.error(JobNotFoundException("Job '$jobId' was not found"));
        return;
      }

      if (response.statusCode != 200) throw const ServerException();

      progress = int.tryParse(response.body) ?? progress;
      yield SeparationResponse(progress);

      await Future.delayed(checkEvery);
    }
  }

  /// Download a [stem] for song with [songId] to the [downloadDirectory].
  Future<File> downloadStem(
    String songId,
    StemType stem, {
    StemFileType fileType = StemFileType.mp3,
  }) async {
    var response = await get("/stem/$songId/${stem.name}", headers: {
      "FileType": fileType.name,
    });
    if (response.statusCode == 479) {
      throw StemNotFoundException("Stem '$stem' not found for song '$songId'");
    }

    if (response.statusCode != 200) throw const ServerException();

    // Determine file extension
    assert(response.headers.containsKey("content-disposition"));
    String fileName =
        response.headers["content-disposition"]!.split("filename=").last.trim();
    assert(fileName.isNotEmpty);
    String extension = fileName.split(".").last;
    assert(extension == fileType.name,
        "The returned stem file ('$fileName') was not of the requested type (.${fileType.name}).");

    File file = File(
        "${(await getSongDirectory(songId)).path}/${stem.name}.$extension");
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
