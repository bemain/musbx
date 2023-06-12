import 'dart:io';

import 'package:http/http.dart' as http;

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

class DemixerApi {
  Stream<SeparationResponse> separateYoutubeSong(String youtubeId) async* {
    Uri url = Uri.parse("http://127.0.0.1:5000/upload/$youtubeId");
    var response = await http.post(url);

    print('Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      yield SeparationResponse.complete(response.body);
      return;
    }
    assert(response.statusCode == 201);

    final int jobId = int.parse(response.body);
    url = Uri.parse("http://127.0.0.1:5000/job/$jobId");
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

  Future<File?> downloadStem(String songName, String stemName) async {
    Uri url = Uri.parse("http://127.0.0.1:5000/stem/$songName/$stemName");
    var response = await http.get(url);
    if (response.statusCode != 200) return null;
    File file = File("$stemName.mp3");

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
