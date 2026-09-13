import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/data/repositories/notification/notification_repository.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/domain/models/notification.dart';

/// A sound used by the metronome.
class Tick {
  const Tick._(this.source);

  /// Create a [Tick] by loading an audio file.
  static Future<Tick> load(String filename) async {
    final source = await SoLoud.instance.loadAsset(
      "assets/sounds/metronome/$filename",
      mode: LoadMode.memory,
    );
    return Tick._(source);
  }

  final AudioSource source;
}

/// The three sounds a beat can be marked with.
class Ticks {
  const Ticks({
    required this.accented,
    required this.primary,
    required this.subdivision,
  });

  /// The first beat of a bar.
  final Tick accented;

  /// A beat that is not the first of the bar.
  final Tick primary;

  /// A note between two beats.
  final Tick subdivision;

  /// Every tick, for loading or disposing them together.
  List<Tick> get all => [accented, primary, subdivision];
}

/// The metronome, ticking on a timer and reporting where in the bar it is.
///
/// A singleton, because the notification it posts can be acted on while the app
/// is in the background and so has to reach one known instance. Every setting is
/// persisted; changing one that affects timing restarts the tick through
/// [reset].
///
/// With the volume at zero it vibrates instead of playing, so it can be followed
/// without sound.
class Metronome {
  Metronome._(this._sharedPreferences, this._notifications) {
    // Listen to app lifecycle
    AppLifecycleListener(
      onHide: () async {
        if (isPlaying) await updateNotification();
      },
      onDetach: () async {
        // FIXME: This doesn't work... The future never completes
        await _notifications.cancelAll();
      },
    );

    reset();
  }

  /// The instance of this singleton.
  static late final Metronome instance;

  /// Minimum [bpm] allowed. [bpm] can never be less than this.
  static const int minBpm = 20;

  /// Maximum [bpm] allowed. [bpm] can never be more than this.
  static const int maxBpm = 250;

  /// Whether this has been initialized.
  ///
  /// See [initialize].
  static bool isInitialized = false;

  /// Initialize the [Metronome] and prepare playback.
  static Future<void> initialize({
    required SharedPreferencesService sharedPreferences,
    required NotificationRepository notifications,
  }) async {
    if (isInitialized) return;

    final metronome = Metronome._(sharedPreferences, notifications);
    metronome.ticks = Ticks(
      accented: await Tick.load("beat_accented.mp3"),
      primary: await Tick.load("beat_primary.mp3"),
      subdivision: await Tick.load("beat_subdivision.mp3"),
    );

    instance = metronome;

    isInitialized = true;
  }

  final SharedPreferencesService _sharedPreferences;
  final NotificationRepository _notifications;

  /// Whether to show a notification while the Metronome is playing.
  bool get showNotification => showNotificationNotifier.value;
  set showNotification(bool value) => showNotificationNotifier.value = value;
  late final PersistentValue<bool> showNotificationNotifier =
      _sharedPreferences.value(
        "metronome/notification",
        initialValue: true,
      )..addListener(reset);

  /// Beats per minutes.
  ///
  /// Clamped between [minBpm] and [maxBpm].
  ///
  /// Does not actually update the playback. This needs to be done manually by calling [reset].
  int get bpm => bpmNotifier.value;
  set bpm(int value) => bpmNotifier.value = value.clamp(minBpm, maxBpm);
  late final PersistentValue<int> bpmNotifier = _sharedPreferences.value(
    "metronome/bpm",
    initialValue: 60,
  );

  /// The duration of a beat.
  Duration get beatDuration =>
      Duration(microseconds: 60e6 ~/ (bpm * subdivisions));

  /// The number of beats per bar.
  int get higher => higherNotifier.value;
  set higher(int value) => higherNotifier.value = value;
  late final PersistentValue<int> higherNotifier = _sharedPreferences.value(
    "metronome/higher",
    initialValue: 4,
  )..addListener(reset);

  /// The number of notes each beat is divided into.
  int get subdivisions => subdivisionsNotifier.value;
  set subdivisions(int value) => subdivisionsNotifier.value = value;
  late final PersistentValue<int> subdivisionsNotifier =
      _sharedPreferences.value(
        "metronome/subdivisions",
        initialValue: 1,
      )..addListener(reset);

  /// The count of the current beat. Ranges from 0 to [higher] - 1.
  int get count => countNotifier.value;
  final ValueNotifier<int> countNotifier = ValueNotifier(0);

  late final Ticks ticks;

  /// The volume of the metronome. Should be between `0.0` and `1.0`.
  double get volume => volumeNotifier.value;
  set volume(double value) => volumeNotifier.value = value;
  late final ValueNotifier<double> volumeNotifier = ValueNotifier(1.0);

  /// Whether the metronome is playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? resume() : pause();
  late final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false)
    ..addListener(updateNotification);

  Stream<int>? _stream;
  StreamSubscription<int>? _subscription;

  /// Start the metronome.
  void resume() {
    _subscription?.resume();
    isPlayingNotifier.value = true;
  }

  /// Pause the metronome.
  void pause() {
    _subscription?.pause();
    isPlayingNotifier.value = false;
  }

  /// Reset [count] and restart playback.
  Future<void> reset() async {
    await _subscription?.cancel();
    _stream = Stream.periodic(beatDuration, (i) => i);
    _subscription = _stream?.listen(_timeout);

    final bool wasPlaying = isPlaying;
    pause();
    countNotifier.value = 0;
    if (wasPlaying) resume();

    await updateNotification();
  }

  /// Play or vibrate the beat at [index], and advance [count].
  Future<void> _timeout(int index) async {
    countNotifier.value = (index ~/ subdivisions) % higher;
    final int subcount = index % subdivisions;

    if (volume != 0.0) {
      // Play sound
      final Tick tick = (count == 0 && subcount == 0)
          ? ticks.accented
          : (subcount == 0)
          ? ticks.primary
          : ticks.subdivision;
      SoLoud.instance.play(tick.source, volume: volume);
    } else {
      // Vibrate
      final feedback = (count == 0 && subcount == 0)
          ? HapticFeedback.vibrate
          : (subcount == 0)
          ? HapticFeedback.heavyImpact
          : HapticFeedback.selectionClick;
      await feedback();
    }
  }

  /// Push the current tempo and play state to the notification. Does nothing if
  /// the user has turned the notification off.
  Future<void> updateNotification() async {
    if (!showNotification) return;

    await _notifications.post(
      AppNotification(
        channel: NotificationChannel.metronomeControls,
        title: "Metronome",
        summary: isPlaying ? "Playing" : "Paused",
        body: "$higher ${higher == 1 ? "beat" : "beats"} • $bpm bpm",
        actions: [
          if (!isPlaying)
            NotificationAction(
              key: "play",
              label: "Play",
            ),
          if (isPlaying)
            NotificationAction(
              key: "pause",
              label: "Pause",
            ),
        ],
      ),
    );
  }
}
