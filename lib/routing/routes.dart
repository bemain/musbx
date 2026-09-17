/// Every location in the app, so that no route is written out as a string twice.
abstract final class Routes {
  static const String metronome = "/metronome";
  static const String library = "/songs";

  /// The page for one song in the library.
  static String song(String songId) => "$library/$songId";
  static const String tuner = "/tuner";
  static const String drone = "/drone";

  static const String settings = "/settings";
  static String get metronomeSettings => "$settings$metronome";
  static String get songsSettings => "$settings$library";
  static String get tunerSettings => "$settings$tuner";
  static String get droneSettings => "$settings$drone";

  static const String licenses = "/settings/licenses";
  static const String contact = "/settings/contact";
  static const String announcements = "/announcements";

  /// The top-level shell branches.
  static const List<String> branches = [metronome, library, tuner, drone];
}
