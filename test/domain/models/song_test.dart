import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:musbx/domain/models/song.dart';
import 'package:musbx/utils/utils.dart';

/// Through a JSON string, as the song library is persisted.
Song roundTrip(Song song) =>
    Song.fromJson(jsonDecode(jsonEncode(song.toJson())) as Json);

void main() {
  group("JSON", () {
    test("round-trips a song with URL audio and every field", () {
      final song = Song(
        id: "abc",
        title: "Title",
        album: "Album",
        artist: "Artist",
        genre: "Jazz",
        artUri: Uri.parse("https://example.com/art.png"),
        audio: UrlAudio(Uri.parse("https://youtu.be/xyz")),
      );

      final restored = roundTrip(song);

      expect(restored.title, "Title");
      expect(restored.album, "Album");
      expect(restored.artist, "Artist");
      expect(restored.genre, "Jazz");
      expect(restored.artUri, song.artUri);
      expect(restored.audio, isA<UrlAudio>());
      expect(
        (restored.audio as UrlAudio).url,
        Uri.parse("https://youtu.be/xyz"),
      );
    });

    test("round-trips file audio", () {
      final song = Song(
        id: "f",
        title: "F",
        audio: FileAudio(File("/music/song.mp3")),
      );
      expect(
        (roundTrip(song).audio as FileAudio).file.path,
        "/music/song.mp3",
      );
    });

    test("refuses to read back bytes audio", () {
      final song = Song(
        id: "b",
        title: "B",
        audio: BytesAudio(Uint8List(4)),
      );
      expect(() => roundTrip(song), throwsFormatException);
    });

    test("rejects unknown audio types", () {
      expect(
        () => AudioReference.fromJson({"type": "cassette"}),
        throwsFormatException,
      );
    });
  });

  test("songs are equal when their ids are", () {
    final song = Song(id: "a", title: "A", audio: BytesAudio(null));
    expect(song.copyWith(title: "Renamed"), song);
    expect(song.copyWith(id: "b"), isNot(song));
  });
}
