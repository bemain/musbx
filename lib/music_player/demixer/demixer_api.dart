import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UploadResponse {
  const UploadResponse(this.songName, {this.jobId});

  /// The name of the folder where the stems are saved. Used to download the stems.
  final String songName;

  /// The name of the job that separates the song into stems,
  /// if the stems were not found in the cache.
  final String? jobId;
}

/// A response from a source separation stream.
class SeparationResponse {
  const SeparationResponse(this.progress);

  /// The current progress of the separation.
  final int progress;
}

enum StemType {
  drums,
  bass,
  vocals,
  other,
}

class DemixerApi {
  /// The server hosting the Demixer API.
  final String host = "musbx.agardh.se:8080";

  Directory? stemDirectory;

  Future<UploadResponse> uploadYoutubeSong(String youtubeId) async {
    Uri url = Uri.http(host, "/upload/$youtubeId");
    var response = await http.post(url);
    Map<String, dynamic> json = jsonDecode(response.body);

    assert(json.containsKey("song_name"));
    String songName = json["song_name"];

    if (response.statusCode == 200) {
      return UploadResponse(songName);
    }

    assert(response.statusCode == 201);

    assert(json.containsKey("job"));
    return UploadResponse(songName, jobId: json["job"]);
  }

  /// Check the progress of a separation job.
  Stream<SeparationResponse> jobProgress(
    String jobId, {
    Duration checkEvery = const Duration(seconds: 5),
  }) async* {
    Uri url = Uri.http(host, "/job/$jobId");
    int progress = 0;

    while (true) {
      // Check job status
      var response = await http.get(url);
      if (response.statusCode == 489) return;

      assert(response.statusCode == 200);

      progress = int.tryParse(response.body) ?? progress;
      yield SeparationResponse(progress);

      await Future.delayed(checkEvery);
    }
  }

  /// Download a [stem] for a [song].
  Future<File?> downloadStem(String song, StemType stem) async {
    Uri url = Uri.http(host, "/stem/$song/${stem.name}");
    var response = await http.get(url);
    if (response.statusCode != 200) return null;

    stemDirectory ??=
        Directory("${(await getTemporaryDirectory()).path}/demixer/")..create();
    File file = File("${stemDirectory!.path}/${stem.name}.wav");

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
