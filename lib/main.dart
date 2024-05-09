import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musbx/music_player/music_player.dart';
import 'package:musbx/navigation_screen.dart';
import 'package:musbx/notifications.dart';
import 'package:musbx/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create audio service
  await MusicPlayer.instance.initAudioService();
  await Notifications.initialize();

  // Lock screen orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Generate themes
  await generateThemes(onThemesGenerated: (lightTheme, darkTheme) {
    // Run app
    runApp(MyApp(
      lightTheme: lightTheme,
      darkTheme: darkTheme,
    ));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.lightTheme, required this.darkTheme});

  /// The light [ColorScheme] obtained from the device, if any.
  final ThemeData lightTheme;

  /// The dark [ColorScheme] obtained from the device, if any.
  final ThemeData darkTheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Musician's Toolbox",
        theme: lightTheme.copyWith(
          sliderTheme: lightTheme.sliderTheme.copyWith(
            showValueIndicator: ShowValueIndicator.always,
          ),
        ),
        darkTheme: darkTheme.copyWith(
          sliderTheme: darkTheme.sliderTheme.copyWith(
            showValueIndicator: ShowValueIndicator.always,
          ),
        ),
        home: const NavigationScreen());
  }
}
