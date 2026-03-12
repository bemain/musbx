import 'package:json_annotation/json_annotation.dart';
import 'package:musbx/utils/utils.dart';
import 'package:uuid/uuid.dart';

/// A model with an [id] property that can be serialized to json and stored
/// on the database.
abstract class Model {
  Model({
    String? id,
    DateTime? createdAt,
  }) : id = id ?? Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// The unique uuid of this object.
  @JsonKey(required: true)
  final String id;

  /// When this object was created.
  @JsonKey(required: true, name: "created_at")
  final DateTime createdAt;

  /// Serialize this object as json.
  Json toJson();

  @override
  String toString() => "Model($id)";
}
