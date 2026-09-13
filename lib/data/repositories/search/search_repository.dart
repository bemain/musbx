import 'package:flutter/widgets.dart';
import 'package:musbx/utils/result.dart';

abstract class SearchRepository {
  Future<Result<void>> pickSong(BuildContext context, {String? query});
}
