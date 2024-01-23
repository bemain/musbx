import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:musbx/keys.dart';

import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';

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

/// The stems that can be requested from the server.
enum StemType {
  drums,
  bass,
  vocals,
  other,
}

class Host {
  static const Map<String, String> authHeaders = {
    "Authorization": demixerApiKey
  };

  const Host(this.address, {this.https = false});

  final String address;

  final bool https;

  Uri Function(String, [String, Map<String, dynamic>?]) get uriConstructor =>
      (https ? Uri.https : Uri.http);

  /// Check if the app version of the Demixer is up to date with the DemixerAPI.
  Future<String> getVersion({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    Uri url = uriConstructor(address, "/version");
    var response = await http.get(url, headers: authHeaders).timeout(timeout);

    if (response.statusCode != 200) throw const ServerException();
    return response.body;
  }

  /// Download the audio to a Youtube file via the server.
  Future<File> downloadYoutubeSong(
    String youtubeId,
    Directory downloadDirectory,
  ) async {
    Uri url = uriConstructor(address, "/download/$youtubeId");
    var response = await http.get(url, headers: authHeaders);

    if (response.statusCode == 497) throw const FileTooLargeException();
    if (response.statusCode != 200) throw const ServerException();

    assert(response.headers.containsKey("content-disposition"));
    String fileName =
        response.headers["content-disposition"]!.split("filename=").last.trim();
    assert(fileName.isNotEmpty);
    File file = File("${downloadDirectory.path}/$fileName");
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

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
      ...authHeaders,
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
    String songId = json["song_name"];

    return UploadResponse(songId, jobId: json["job"]);
  }

  /// Upload a YouTube song to the server.
  ///
  /// The stem files generated from the uploaded file will be of the type [desiredStemFilesType].
  Future<UploadResponse> uploadYoutubeSong(
    String youtubeId, {
    StemFileType desiredStemFilesType = StemFileType.mp3,
  }) async {
    Uri url = uriConstructor(address, "/upload/$youtubeId");
    var response = await http.post(url, headers: {
      ...authHeaders,
      "FileType": desiredStemFilesType.name,
    });

    if (response.statusCode == 499) throw const YoutubeVideoNotFoundException();
    if (response.statusCode == 488) throw const ServerOverloadedxception();
    if (response.statusCode == 497) throw const FileTooLargeException();

    Map<String, dynamic> json = jsonDecode(response.body);
    String songId = json["song_name"];

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
    Uri url = uriConstructor(address, "/job/$jobId");
    int progress = 0;

    while (true) {
      // Check job status
      var response = await http.get(url, headers: authHeaders);
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
    StemType stem,
    Directory downloadDirectory, {
    StemFileType fileType = StemFileType.mp3,
  }) async {
    Uri url = uriConstructor(address, "/stem/$songId/${stem.name}");
    var response = await http.get(url, headers: {
      ...authHeaders,
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

    File file = File("${downloadDirectory.path}/${stem.name}.$extension");
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  @override
  String toString() {
    return "Host($address)";
  }
}
