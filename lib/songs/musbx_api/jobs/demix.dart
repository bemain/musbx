import 'package:musbx/songs/musbx_api/jobs/job.dart';
import 'package:musbx/utils/utils.dart';

/// Available models for demucs processing.
enum DemucsModel {
  htdemucs,
  htdemucs_6s,
}

/// Available file formats for files returned from the demixing job.
enum DemixFileType {
  mp3,
  wav,
}

/// The steps of the demixing job.
enum DemixStep {
  idle,
  loadingModel,
  demixing,
  saving,
}

/// Result from a demixing job.
/// The keys are the name of the separated stems, and the values are the download URLs.
typedef DemixJobResult = Map<String, String>;

class DemixJobReport extends JobReport<DemixJobResult> {
  const DemixJobReport._(
    super.id, {
    required super.status,
    super.result,
    Object? error,
    required this.step,
    this.progress = 0,
  }) : super(task: JobTask.demix);

  /// The current step of the job.
  final DemixStep step;

  /// The progress of the current [step], as a fraction between `0.0` and `1.0`.
  final double progress;

  factory DemixJobReport.fromJson(Map<String, dynamic> json) {
    assert(json["task"] == JobTask.demix.name);

    return DemixJobReport._(
      json["id"] as String,
      status: JobStatus.values.byName(json["status"]),
      result: (json["result"] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
      error: json["error"] as Object?,
      step: DemixStep.values.byName(json["step"]),
      progress: json["progress"] as double,
    );
  }

  @override
  String toString() {
    return "DemixJobStatus($id, task: ${task.name}, status: $status, step: $step, progress: ${progress.toStringAsFixed(2)})";
  }
}

/// A job that demixes an audio file into multiple stems using demucs.
class DemixJob extends Job<DemixJobResult> {
  DemixJob(super.dio, super.id);

  @override
  Future<DemixJobReport> get() async {
    final response = await dio.get<Json>("/job/$id");
    return DemixJobReport.fromJson(response.data!);
  }
}
