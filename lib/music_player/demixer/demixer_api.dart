import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:musbx/music_player/demixer/demixer_api_exceptions.dart';
import 'package:path_provider/path_provider.dart';

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

class DemixerApi {
  /// The server hosting the Demixer API.
  final String host = "musbx.agardh.se:8080";

  /// The directory where stems are saved.
  static Directory? stemDirectory;

  /// Upload a YouTube song to the server.
  Future<UploadResponse> uploadYoutubeSong(String youtubeId) async {
    Uri url = Uri.http(host, "/upload/$youtubeId");
    var response = await http.post(url);
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
    Uri url = Uri.http(host, "/job/$jobId");
    int progress = 0;

    while (true) {
      // Check job status
      var response = await http.get(url);
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

  /// Download a [stem] for a [song] to the [stemDirectory].
  Future<File?> downloadStem(String song, StemType stem) async {
    Uri url = Uri.http(host, "/stem/$song/${stem.name}");
    var response = await http.get(url);
    if (response.statusCode == 479) {
      throw StemNotFoundException("Stem '$stem' not found for song '$song'");
    }

    if (response.statusCode != 200) throw const ServerException();

    stemDirectory ??=
        Directory("${(await getTemporaryDirectory()).path}/demixer/")..create();
    File file = File("${stemDirectory!.path}/${stem.name}.wav");

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
