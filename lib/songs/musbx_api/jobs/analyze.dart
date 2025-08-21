import 'package:musbx/songs/musbx_api/jobs/job.dart';
import 'package:musbx/utils/utils.dart';

/// Result from an analyzing job.
/// The keys are timestamps, and the values are chords.
typedef AnalyzeJobResult = Map<double, String>;

class AnalyzeJobReport extends JobReport<AnalyzeJobResult> {
  const AnalyzeJobReport._(
    super.id, {
    required super.status,
    super.result,
    super.error,
  }) : super(task: JobTask.analyze);

  factory AnalyzeJobReport.fromJson(Json json) {
    assert(json['task'] == JobTask.analyze.name);

    final List<dynamic>? result = json['result'] as List?;

    return AnalyzeJobReport._(
      json['id'] as String,
      status: JobStatus.values.byName(json['status'] as String),
      result: result == null
          ? null
          : {
              for (var data in result)
                data['timestamp'] as double: data['chord'] as String,
            },
      error: json['error'] as Object?,
    );
  }

  @override
  String toString() {
    return "AnalyzeJobStatus($id, task: ${task.name}, status: $status)";
  }
}

/// A job that performs chord analysis on an audio file.
class AnalyzeJob extends Job<AnalyzeJobResult> {
  AnalyzeJob(super.dio, super.id);

  @override
  Future<AnalyzeJobReport> get() async {
    final response = await dio.get<Json>("/job/$id");
    return AnalyzeJobReport.fromJson(response.data!);
  }
}
