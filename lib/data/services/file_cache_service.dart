import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:musbx/utils/num_iterable_extension.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Provides access to the app's on-disk caches.
///
/// Files are split by durability: [scratch] holds regenerable data that the
/// operating system may purge at any time, while [persistent] holds user data
/// that has to survive.
class FileCacheService {
  FileCacheService._(this._temporary, this._applicationDocuments);

  final Directory _temporary;

  final Directory _applicationDocuments;

  /// The write operations currently being performed.
  final Map<String, Future<File>> _operations = {};

  /// Create the service and resolve the directories it caches files in.
  static Future<FileCacheService> create() async {
    final temp = await getTemporaryDirectory();
    final appDocs = await getApplicationDocumentsDirectory();
    debugPrint(
      "[DIRECTORIES] Initialized with temporary directory at ${temp.path}, application documents at ${appDocs.path}",
    );

    return FileCacheService._(
      temp,
      appDocs,
    );
  }

  // TODO: Remove once we introduce `provider`.
  static late final FileCacheService instance;
  static Future<void> initialize() async {
    instance = await create();
  }

  /// The root directory for regenerable data, such as downloaded audio and
  /// analysis results. The operating system may delete this at any time.
  CacheDirectory get scratch => CacheDirectory._(this, _temporary);

  /// The root directory for data that has to survive, such as audio provided
  /// by the user. Included in device backups, so avoid storing large
  /// regenerable files here.
  CacheDirectory get persistent =>
      CacheDirectory._(this, _applicationDocuments);
}

/// A directory in the cache. Does not have to exist on disk.
///
/// Names passed to [directory] and [file] are resolved relative to this
/// directory, and rejected if they would escape it.
class CacheDirectory {
  CacheDirectory._(this._service, this._dir);

  final FileCacheService _service;

  final Directory _dir;

  /// Sanitize and join [name] onto the current [_dir] path.
  String _joinName(String name) {
    final joined = path.normalize(path.join(_dir.path, name.trim()));

    if (!path.isWithin(_dir.path, joined)) {
      throw ArgumentError.value(name, 'name', 'escapes the cache directory');
    }
    return joined;
  }

  /// Get a nested directory with the given [name].
  CacheDirectory directory(String name) =>
      CacheDirectory._(_service, Directory(_joinName(name)));

  /// Get a file in this directory with the given [name].
  CacheFile file(String name) => CacheFile._(_service, File(_joinName(name)));

  /// The size of this directory in bytes, or 0 if it doesn't exist.
  Future<int> size() async {
    final files = await children();
    return (await Future.wait(files.map((child) => child.size()))).sum as int;
  }

  /// When this directory was last written to, or `null` if it doesn't exist.
  Future<DateTime?> lastModified() async {
    if (!await _dir.exists()) return null;

    final stat = await _dir.stat();
    return stat.modified;
  }

  /// All files cached in this directory.
  ///
  /// Returns an empty list if this directory doesn't exist.
  Future<List<CacheFile>> children({bool recursive = true}) async {
    if (!await _dir.exists()) return [];

    final List<CacheFile> children = [];
    await for (var child in _dir.list(recursive: recursive)) {
      if (child is File) {
        children.add(CacheFile._(_service, child));
      }
    }
    return children;
  }

  /// Delete the directory.
  Future<void> delete({bool recursive = true}) async {
    if (!await _dir.exists()) return;
    await _dir.delete(recursive: recursive);
  }
}

/// A file in the cache. Does not have to exist on disk.
///
/// Writes are atomic: content is staged in a temporary part file and renamed
/// into place only once it is complete, so a reader never observes a partially
/// written file. Operations on the same path are coordinated by the service,
/// so writes are serialized and concurrent [ensure] calls share one execution.
class CacheFile {
  CacheFile._(this._service, this._file);

  final FileCacheService _service;

  final File _file;

  /// The path of the file.
  String get path => _file.path;

  /// Whether this file is on disk.
  ///
  /// Because writes are staged in [_part] and renamed into place, this is never
  /// true of a half-written file: it answers "is this cached and complete",
  /// which is what makes it a safe cache-hit test.
  Future<bool> exists() async => _file.exists();

  /// The size of this file in bytes, or 0 if it doesn't exist.
  Future<int> size() async {
    final stat = await _file.stat();
    return stat.type == FileSystemEntityType.notFound ? 0 : stat.size;
  }

  /// Read this file as a `String`, or `null` if it doesn't exist.
  Future<String?> readString() async {
    if (!await _file.exists()) return null;
    return await _file.readAsString();
  }

  /// Read this file as bytes, or `null` if it doesn't exist.
  Future<Uint8List?> readBytes() async {
    if (!await _file.exists()) return null;
    return await _file.readAsBytes();
  }

  /// Temporary file that writes are staged in, so that they can be made atomic.
  File get _part => File("$path.part");

  /// Write to the file atomically, by staging the content in [_part] and
  /// renaming it into place once [produce] has completed.
  ///
  /// Not concurrent-safe on its own; callers coordinate through the service.
  Future<File> _write(Future<void> Function(File scratch) produce) async {
    await _part.create(recursive: true);
    try {
      await produce(_part);
      final stat = await _part.stat();
      // Reject an empty part file
      if (stat.type != FileSystemEntityType.notFound && stat.size > 0) {
        await _part.rename(path);
      }
    } catch (_) {
      if (await _part.exists()) await _part.delete();
      rethrow;
    }

    return _file;
  }

  /// Write `String` [content] to the file. Creates the file if it doesn't exist.
  Future<File> writeString(String content) async {
    final op = () async {
      await _service._operations[path]?.catchError((_) => _file);
      return _write((scratch) async {
        await scratch.writeAsString(content);
      });
    }();
    _service._operations[path] = op;
    await op.whenComplete(() {
      if (_service._operations[path] == op) _service._operations.remove(path);
    });
    return await op;
  }

  /// Write bytes [content] to the file. Creates the file if it doesn't exist.
  Future<File> writeBytes(List<int> content) async {
    final op = () async {
      await _service._operations[path]?.catchError((_) => _file);
      return _write((scratch) async {
        await scratch.writeAsBytes(content);
      });
    }();
    _service._operations[path] = op;
    await op.whenComplete(() {
      if (_service._operations[path] == op) _service._operations.remove(path);
    });
    return await op;
  }

  /// The file, produced first if absent. [produce] writes into [scratch], which is
  /// renamed into place only on success — a partial write is never observable as a hit.
  /// Concurrent calls for the same path share one execution.
  Future<File> ensure(
    Future<void> Function(File scratch) produce,
  ) async {
    // Hook onto a running operation, if any
    final running = _service._operations[path];
    if (running != null) return running;

    final op = () async {
      if (await _file.exists()) return _file;
      return await _write(produce);
    }();
    _service._operations[path] = op;

    await op.whenComplete(() {
      if (_service._operations[path] == op) _service._operations.remove(path);
    });
    return op;
  }

  /// Delete the file.
  Future<void> delete() async {
    if (!await _file.exists()) return;
    await _file.delete();
  }
}
