import 'dart:convert';
import 'dart:io';

import 'package:musbx/songs/musbx_api/musbx_api.dart';
import 'package:musbx/widgets/widgets.dart';

class YoutubeApiHost extends MusbxApiHost {
  YoutubeApiHost(super.address, {super.https});

  /// The default file where the audio for Youtube song with id [youtubeId] is saved.
  static File getYoutubeFile(
    String youtubeId,
    String extension,
  ) =>
      File("${Directories.temporaryDir("youtube").path}/$youtubeId.$extension");

  /// Download the audio for a Youtube video.
  Future<File> downloadYoutubeSong(
    String youtubeId, {
    File? destination,
    String fileType = "mp3",
  }) async {
    var response = await get("/download/$youtubeId", headers: {
      "FileType": fileType,
    });

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
    destination ??= getYoutubeFile(youtubeId, fileExtension);
    await destination.create(recursive: true);
    await destination.writeAsBytes(response.bodyBytes);
    return destination;
  }
}
