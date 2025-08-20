import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:musbx/songs/musbx_api/auth.dart';
import 'package:musbx/songs/musbx_api/jobs/analyze.dart';
import 'package:musbx/songs/musbx_api/jobs/demix.dart';
import 'package:musbx/utils/utils.dart';
import 'package:pub_semver/pub_semver.dart';

class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final String? data = err.response?.data is List<int>
        ? utf8.decode(err.response?.data)
        : err.response?.data.toString();
    debugPrint("[MUSBX API] Error occured: $data");

    return handler.next(err);
  }
}

/// The status of a specific server hosting the Musbx API.
class MusbxApiStatus {
  const MusbxApiStatus._(this.version, {this.activeJobs = 0});

  /// The version of the API.
  final Version version;

  /// The number
  final int activeJobs;

  factory MusbxApiStatus.fromJson(Json json) {
    return MusbxApiStatus._(
      Version.parse(json["version"] as String),
      activeJobs: json["activeJobs"] as int,
    );
  }

  @override
  String toString() {
    return "ApiStatus($version, activeJobs: $activeJobs)";
  }
}

/// Handle to a file that has been uploaded to the API.
class FileHandle {
  const FileHandle._(this.handle);

  /// The hash of the file that this points to.
  final String handle;

  factory FileHandle.fromJson(Json json) {
    return FileHandle._(json["file"]["handle"] as String);
  }
}

/// A client for interacting with a server hosting the Musbx API.
class MusbxApiClient {
  final Dio _dio;

  MusbxApiClient(String baseurl)
      : _dio = Dio(BaseOptions(
          baseUrl: baseurl,
          receiveDataWhenStatusError: true,
        )) {
    _dio.interceptors
      ..add(AuthInterceptor(_dio))
      ..add(ErrorInterceptor());
  }

  /// Get the version of the API.
  Future<Version> version() async {
    final response = await _dio.get<Json>("/version");
    return Version.parse(response.data!["version"] as String);
  }

  /// Get the status of the API.
  Future<MusbxApiStatus> status() async {
    final response = await _dio.get<Json>("/status");
    return MusbxApiStatus.fromJson(response.data!);
  }

  /// Upload a [url] to the server.
  ///
  /// Returns a handle to the uploaded file, which can be used to perform jobs
  /// on the file.
  Future<FileHandle> uploadUrl(Uri url) async {
    final response = await _dio.post<Json>("/upload/url", queryParameters: {
      "url": url.toString(),
    });
    return FileHandle.fromJson(response.data!);
  }

  /// Upload a [file] to the server.
  ///
  /// Returns a handle to the uploaded file, which can be used to perform jobs
  /// on the file.
  Future<FileHandle> uploadFile(File file) async {
    final response = await _dio.post<Json>(
      "/upload/file",
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      }),
    );
    return FileHandle.fromJson(response.data!);
  }

  /// Upload a [url] that can be processed by yt-dlp to the server.
  ///
  /// Returns a handle to the uploaded file, which can be used to perform jobs
  /// on the file.
  Future<FileHandle> uploadYtdlp(
    Uri url, {
    String fileType = "mp3",
  }) async {
    final response = await _dio.post<Json>("/upload/yt-dlp", queryParameters: {
      "url": url.toString(),
      "fileType": fileType,
    });
    return FileHandle.fromJson(response.data!);
  }

  /// Download a file that was previously uploaded from the server.
  Future<File> download(
    FileHandle file,
    File destination, {
    void Function(int received, int total)? onProgress,
  }) async {
    final response = await _dio.get<List<int>>(
      "/download",
      queryParameters: {
        "handle": file.handle,
      },
      onReceiveProgress: onProgress,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
      ),
    );

    await destination.create(recursive: true);
    await destination.writeAsBytes(response.data!);
    return destination;
  }

  /// Start a demixing job on an uploaded [file].
  Future<DemixJob> demix(
    FileHandle file, {
    DemucsModel model = DemucsModel.htdemucs_6s,
    DemixFileType fileType = DemixFileType.mp3,
  }) async {
    final response = await _dio.post<Json>("/demix", queryParameters: {
      "handle": file.handle,
      "model": model.name,
      "fileType": fileType.name,
    });
    return DemixJob(_dio, response.data!["jobId"]);
  }

  /// Start an analyzing job on an uploaded [file].
  Future<AnalyzeJob> analyze(
    FileHandle file,
  ) async {
    final response = await _dio.post<Json>("/analyze", queryParameters: {
      "handle": file.handle,
    });
    return AnalyzeJob(_dio, response.data!["jobId"]);
  }
}
