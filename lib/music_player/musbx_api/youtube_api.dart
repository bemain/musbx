import 'dart:io';

import 'package:musbx/music_player/musbx_api/musbx_api.dart';
import 'package:musbx/music_player/musbx_api/exceptions.dart';
import 'package:musbx/widgets.dart';

class YoutubeApiHost extends MusbxApiHost {
  YoutubeApiHost(super.address, {super.https});

  /// The directory where Youtube files are saved.
  static final Future<Directory> youtubeDirectory =
      createTempDirectory("youtube");

  /// Download the audio for a Youtube video.
  Future<File> downloadYoutubeSong(String youtubeId) async {
    var response = await get("/download/$youtubeId");

    if (response.statusCode == 497) throw const FileTooLargeException();
    if (response.statusCode != 200) throw const ServerException();

    assert(response.headers.containsKey("content-disposition"));
    String fileName =
        response.headers["content-disposition"]!.split("filename=").last.trim();
    assert(fileName.isNotEmpty);
    File file = File("${(await youtubeDirectory).path}/$fileName");
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
