class StemNotFoundException implements Exception {
  final String? msg;

  const StemNotFoundException([this.msg]);

  @override
  String toString() => msg ?? 'StemNotFoundException';
}

class JobNotFoundException implements Exception {
  final String? msg;

  const JobNotFoundException([this.msg]);

  @override
  String toString() => msg ?? 'JobNotFoundException';
}

class YoutubeVideoNotFoundException implements Exception {
  final String? msg;

  const YoutubeVideoNotFoundException([this.msg]);

  @override
  String toString() => msg ?? 'YoutubeVideoNotFoundException';
}

class ServerException implements Exception {
  final String? msg;

  const ServerException([this.msg]);

  @override
  String toString() => msg ?? 'ServerException';
}
