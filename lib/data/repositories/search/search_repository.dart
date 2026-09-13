import 'package:flutter/widgets.dart';
import 'package:musbx/utils/result.dart';

/// A place to search for songs to add to the library.
/// Let the user pick a song, starting from [query] if one is given.
///
/// Completes once they have picked one or backed out.
abstract class SearchRepository {
  Future<Result<void>> pickSong(BuildContext context, {String? query});
}
