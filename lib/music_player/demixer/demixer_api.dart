import 'dart:io';

import 'package:http/http.dart' as http;

/// A response from a source separation stream.
///
/// If [complete] is `true`, [stemFolderName] is not `null`. Otherwise, progress is not `null`.
class SeparationResponse {
  SeparationResponse.complete(this.stemFolderName)
      : complete = true,
        progress = null;
  SeparationResponse.active(this.progress)
      : complete = false,
        stemFolderName = null;

  final bool complete;
  final String? stemFolderName;
  final int? progress;
}

enum StemName {
  drums,
  bass,
  vocals,
  other,
}

class DemixerApi {
  final String host = "127.0.0.1:5000";

  /// Separate a Youtube song with the specified [youtubeId].
  Stream<SeparationResponse> separateYoutubeSong(String youtubeId) async* {
    Uri url = Uri.http(host, "/upload/$youtubeId");
    var response = await http.post(url);

    print('Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      yield SeparationResponse.complete(response.body);
      return;
    }
    assert(response.statusCode == 201);

    final int jobId = int.parse(response.body);
    url = Uri.http(host, "/job/$jobId");
    int progress = 0;

    while (true) {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        yield SeparationResponse.complete(response.body);
        return;
      }

      assert(response.statusCode == 289);
      progress = int.tryParse(response.body) ?? progress;
      print("Progress: $progress%");
      yield SeparationResponse.active(progress);

      await Future.delayed(const Duration(seconds: 10));
    }
  }

  /// Download a [stem] for a [song].
  Future<File?> downloadStem(String song, StemName stem) async {
    Uri url = Uri.http(host, "/stem/$song/${stem.name}");
    var response = await http.get(url);
    if (response.statusCode != 200) return null;
    File file = File("$stem.mp3");

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
