import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

enum StemType {
  drums,
  bass,
  vocals,
  other,
}

class DemixerApi {
  final String host = "90.224.55.38:8080";

  Directory? stemDirectory;

  /// Separate a Youtube song with the specified [youtubeId].
  Stream<SeparationResponse> separateYoutubeSong(
    String youtubeId, {
    Duration checkProgressInterval = const Duration(seconds: 5),
  }) async* {
    Uri url = Uri.http(host, "/upload/$youtubeId");
    var response = await http.post(url);

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
      yield SeparationResponse.active(progress);

      await Future.delayed(checkProgressInterval);
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
