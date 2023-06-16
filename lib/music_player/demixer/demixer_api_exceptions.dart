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

class ServerException implements Exception {
  final String? msg;

  const ServerException([this.msg]);

  @override
  String toString() => msg ?? 'ServerException';
}
