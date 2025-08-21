import 'dart:io';

import 'package:dio/dio.dart';
import 'package:musbx/utils/utils.dart';

/// The task that a job performs.
enum JobTask {
  /// The job demixes an audio file into multiple stems using demucs.
  demix,

  /// The job performs chord analysis on an audio file.
  analyze,
}

/// The status of a job.
enum JobStatus {
  /// The job is running.
  running,

  /// The job is completed and has returned a result.
  completed,

  /// The job failed and has returned an error.
  error,
}

/// A status report for a job.
class JobReport<T> {
  const JobReport(
    this.id, {
    required this.task,
    required this.status,
    this.result,
    this.error,
  });

  /// The id of the job.
  final String id;

  /// The task that the job performs.
  final JobTask task;

  /// The status of the job.
  final JobStatus status;

  /// The data that the job returned, if any.
  final T? result;

  /// The error that the job has thrown, if any.
  final Object? error;

  /// Whether the job has returned a result.
  bool get hasResult => result != null;

  /// Whether the job has thrown an error.
  bool get hasError => error != null;

  factory JobReport.fromJson(Map<String, dynamic> json) {
    return JobReport(
      json["id"] as String,
      task: JobTask.values.byName(json["task"]),
      status: JobStatus.values.byName(json["status"]),
      result: json["result"] as T?,
      error: json["error"] as Object?,
    );
  }

  @override
  String toString() {
    return "JobStatus($id, task: $task, status: $status)";
  }
}

abstract class Job<T> {
  /// Representation of a job that the API performs.
  Job(this.dio, this.id);

  /// The Dio instance that handles the interaction with the API.
  final Dio dio;

  /// The id of this job.
  final String id;

  /// Get a status report for this job.
  Future<JobReport<T>> get() async {
    final response = await dio.get<Json>("/job/$id");
    return JobReport<T>.fromJson(response.data!);
  }

  /// Download a file that is a result from this job.
  Future<File> downloadResultFile(
    String name,
    File destination, {
    void Function(int received, int total)? onProgress,
  }) async {
    final response = await dio.get<List<int>>(
      "/job/$id/download/$name",
      onReceiveProgress: onProgress,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
      ),
    );

    await destination.writeAsBytes(response.data!);
    return destination;
  }

  /// Check the status of this job periodically until it completes and return it's result.
  Future<T> complete({
    Duration checkStatusInterval = const Duration(milliseconds: 500),
  }) async {
    JobReport<T> report = await get();
    while (report.status == JobStatus.running) {
      await Future.delayed(checkStatusInterval);
      report = await get();
    }

    if (report.hasError) throw report.error!;
    if (!report.hasResult) throw Exception("Job didn't return a result: $id");

    return report.result!;
  }

  @override
  String toString() {
    return "Job($id)";
  }
}
