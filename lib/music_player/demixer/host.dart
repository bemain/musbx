import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:musbx/keys.dart';

import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';

class UploadResponse {
  /// Returned when uploading a song to the server.
  ///
  /// If [jobId] is not `null`, the server has begun separating the song.
  /// Check the job status with [jobProgress] to make sure the separation job has completed before trying to download stems.
  const UploadResponse(this.songName, {this.jobId});

  /// The name of the folder where the stems are saved. Used to download the stems.
  final String songName;

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
  static const Map<String, String> httpHeaders = {
    "Authorization": demixerApiKey
  };

  const Host(this.address);

  final String address;

  /// Check if the app version of the Demixer is up to date with the DemixerAPI.
  Future<String> getVersion({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    Uri url = Uri.http(address, "/version");
    var response = await http.get(url, headers: httpHeaders).timeout(timeout);

    if (response.statusCode != 200) throw const ServerException();
    return response.body;
  }

  /// Download the audio to a Youtube file via the server.
  Future<File> downloadYoutubeSong(
    String youtubeId,
    Directory downloadDirectory,
  ) async {
    Uri url = Uri.http(address, "/download/$youtubeId");
    var response = await http.get(url, headers: httpHeaders);

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
  Future<UploadResponse> uploadFile(File file) async {
    Uri url = Uri.http(address, "/upload");
    var request = http.MultipartRequest("POST", url);
    request.headers.addAll(httpHeaders);
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
    String songName = json["song_name"];

    return UploadResponse(songName, jobId: json["job"]);
  }

  /// Upload a YouTube song to the server.
  Future<UploadResponse> uploadYoutubeSong(String youtubeId) async {
    Uri url = Uri.http(address, "/upload/$youtubeId");
    var response = await http.post(url, headers: httpHeaders);

    if (response.statusCode == 499) throw const YoutubeVideoNotFoundException();
    if (response.statusCode == 488) throw const ServerOverloadedxception();
    if (response.statusCode == 497) throw const FileTooLargeException();

    Map<String, dynamic> json = jsonDecode(response.body);
    String songName = json["song_name"];

    if (response.statusCode == 200) {
      return UploadResponse(songName);
    }

    if (response.statusCode != 201) throw const ServerException();

    return UploadResponse(songName, jobId: json["job"]);
  }

  /// Check the progress of a separation job.
  ///
  /// The progress is checked every [checkEvery] seconds until the job can no
  /// longer be found (it is completed) and a [JobNotFoundException] is thrown.
  Stream<SeparationResponse> jobProgress(
    String jobId, {
    Duration checkEvery = const Duration(seconds: 5),
  }) async* {
    Uri url = Uri.http(address, "/job/$jobId");
    int progress = 0;

    while (true) {
      // Check job status
      var response = await http.get(url, headers: httpHeaders);
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

  /// Download a [stem] for a [songName] to the [stemDirectory].
  Future<File> downloadStem(
    String songName,
    StemType stem,
    Directory downloadDirectory,
  ) async {
    Uri url = Uri.http(address, "/stem/$songName/${stem.name}");
    var response = await http.get(url, headers: httpHeaders);
    if (response.statusCode == 479) {
      throw StemNotFoundException(
          "Stem '$stem' not found for song '$songName'");
    }

    if (response.statusCode != 200) throw const ServerException();

    File file = File("${downloadDirectory.path}/${stem.name}.mp3");
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  @override
  String toString() {
    return "Host($address)";
  }
}
