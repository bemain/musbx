import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:musbx/songs/musbx_api/musbx_api.dart';

class ChordsApiHost extends MusbxApiHost {
  ChordsApiHost(super.address, {super.https});

  Future<Map> analyzeFile(File file) async {
    Uri url = uriConstructor(address, "/analyze");
    var request = http.MultipartRequest("POST", url);
    request.headers.addAll({
      ...MusbxApiHost.authHeaders,
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

    final chords = json["chords"] as Map;
    return chords;
  }

  Future<Map> analyzeYoutubeSong(String youtubeId) async {
    var response = await post("/analyze/$youtubeId");
    Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw HttpException(json["message"], uri: response.request?.url);
    }

    final chords = json["chords"] as Map;
    return chords;
  }
}
