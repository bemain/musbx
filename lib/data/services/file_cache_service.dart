import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileCacheService {
  FileCacheService._(this._temporary, this._applicationDocuments);

  final Directory _temporary;

  final Directory _applicationDocuments;

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

  /// Get a temporary directory with the given [name].
  ///
  /// This does not check to make sure that the directory actually exists.
  Directory temporaryDir(String name) =>
      Directory("${_temporary.path}/$name/");

  /// Get a application documents directory with the given [name].
  ///
  /// This does not check to make sure that the directory actually exists.
  Directory applicationDocumentsDir(String name) =>
      Directory("${_applicationDocuments.path}/$name/");
}
