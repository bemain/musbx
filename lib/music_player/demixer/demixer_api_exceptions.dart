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

class FileTooLargeException implements Exception {
  final String? msg;

  const FileTooLargeException([this.msg]);

  @override
  String toString() => msg ?? 'The selected file is too large';
}

class ServerOverloadedxception implements Exception {
  final String? msg;

  const ServerOverloadedxception([this.msg]);

  @override
  String toString() => msg ?? 'The server is overloaded';
}

class ServerException implements Exception {
  final String? msg;

  const ServerException([this.msg]);

  @override
  String toString() => msg ?? 'The server encountered an internal error';
}

class NoHostAvailableException implements Exception {
  final String? msg;

  const NoHostAvailableException([this.msg]);

  @override
  String toString() => msg ?? 'No host is available';
}

class OutOfDateException implements Exception {
  final String? msg;

  const OutOfDateException([this.msg]);

  @override
  String toString() => msg ?? 'The app is out of date with the server';
}
