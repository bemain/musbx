import 'dart:convert';
import 'dart:io';

import 'package:musbx/music_player/musbx_api/musbx_api.dart';
import 'package:musbx/widgets.dart';

class YoutubeApiHost extends MusbxApiHost {
  YoutubeApiHost(super.address, {super.https});

  /// The directory where Youtube files are saved.
  static final Future<Directory> youtubeDirectory =
      createTempDirectory("youtube");

  /// The file where the audio for Youtube song with id [youtubeId] is saved.
  static Future<File> getYoutubeFile(
    String youtubeId,
    String extension,
  ) async =>
      File("${(await youtubeDirectory).path}/$youtubeId.$extension");

  /// Download the audio for a Youtube video.
  Future<File> downloadYoutubeSong(String youtubeId) async {
    var response = await get("/download/$youtubeId");

    if (response.statusCode != 200) {
      throw HttpException(
        jsonDecode(response.body)["message"],
        uri: response.request?.url,
      );
    }
    assert(response.headers.containsKey("content-disposition"));
    String fileName =
        response.headers["content-disposition"]!.split("filename=").last.trim();
    assert(fileName.isNotEmpty);
    String fileExtension = fileName.split(".").last;
    print(fileExtension);
    File file = await getYoutubeFile(youtubeId, fileExtension);
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
