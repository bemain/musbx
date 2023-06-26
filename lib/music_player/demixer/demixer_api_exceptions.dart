class StemNotFoundException implements Exception {
  final String? msg;

  const StemNotFoundException([this.msg]);

  @override
  String toString() => msg ?? 'The requested stem was not found';
}

class JobNotFoundException implements Exception {
  final String? msg;

  const JobNotFoundException([this.msg]);

  @override
  String toString() => msg ?? 'The requested job was not found';
}

class YoutubeVideoNotFoundException implements Exception {
  final String? msg;

  const YoutubeVideoNotFoundException([this.msg]);

  @override
  String toString() => msg ?? 'The requested video was not found';
}

class ServerException implements Exception {
  final String? msg;

  const ServerException([this.msg]);

  @override
  String toString() => msg ?? 'The server encountered an internal error';
}
