import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:musbx/music_player/musbx_api/musbx_api.dart';
import 'package:musbx/music_player/song.dart';
import 'package:musbx/widgets.dart';
import 'package:http/http.dart' as http;

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

class DemixerApiHost extends MusbxApiHost {
  DemixerApiHost(super.address, {super.https});

  /// The directory where stems for a [song] are saved.
  static Future<Directory> getStemsDirectory(Song song) async {
    final dir = Directory("${(await song.cacheDirectory).path}/stems");
    await dir.create(recursive: true);
    return dir;
  }

  static final Future<Directory> extractedFilesDirectory =
      createTempDirectory("demixer/extracted");

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
      ...MusbxApiHost.authHeaders,
      "FileType": desiredStemFilesType.name,
    });
    request.files.add(await http.MultipartFile.fromPath(
      "file",
      file.path,
      contentType: MediaType("audio", file.path.split('.').last),
    ));

    var response = await request.send();
    Map<String, dynamic> json =
        jsonDecode(await response.stream.bytesToString());

    if (response.statusCode != 201) {
      throw HttpException(json["message"], uri: url);
    }

    return UploadResponse(json["song_id"], jobId: json["job"]);
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
    Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw HttpException(json["message"], uri: response.request?.url);
    }

    if (response.statusCode == 200) {
      return UploadResponse(json["song_id"]);
    }
    return UploadResponse(json["song_id"], jobId: json["job"]);
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
      final json = jsonDecode(response.body);

      if (response.statusCode != 200) {
        yield* Stream.error(HttpException(
          json["message"],
          uri: response.request?.url,
        ));
        return;
      }

      progress = int.tryParse(json["progress"]) ?? progress;
      yield SeparationResponse(progress);

      await Future.delayed(checkEvery);
    }
  }

  /// Download a [stem] for a [song].
  Future<File> downloadStem(
    Song song,
    StemType stem, {
    StemFileType fileType = StemFileType.mp3,
  }) async {
    var response = await get("/stem/${song.id}/${stem.name}", headers: {
      "FileType": fileType.name,
    });
    if (response.statusCode != 200) {
      throw HttpException(
        jsonDecode(response.body)["message"],
        uri: response.request?.url,
      );
    }

    // Determine file extension
    assert(response.headers.containsKey("content-disposition"));
    String fileName =
        response.headers["content-disposition"]!.split("filename=").last.trim();
    assert(fileName.isNotEmpty);
    String extension = fileName.split(".").last;
    assert(extension == fileType.name,
        "The returned stem file ('$fileName') was not of the requested type (.${fileType.name}).");

    File file =
        File("${(await getStemsDirectory(song)).path}/${stem.name}.$extension");
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
