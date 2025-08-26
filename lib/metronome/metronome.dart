import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/utils/notifications.dart';
import 'package:musbx/utils/persistent_value.dart';

/// A sound used by the metronome.
class Tick {
  const Tick._(this.source, this.handle);

  /// Create a [Tick] by loading an audio file.
  static Future<Tick> load(String filename) async {
    final source = await SoLoud.instance.loadAsset(
      "assets/sounds/metronome/$filename",
      mode: LoadMode.memory,
    );
    final handle = await SoLoud.instance.play(source, paused: true);
    return Tick._(source, handle);
  }

  final AudioSource source;

  final SoundHandle handle;
}

class Ticks {
  const Ticks({
    required this.accented,
    required this.primary,
    required this.subdivision,
  });

  final Tick accented;
  final Tick primary;
  final Tick subdivision;

  List<Tick> get all => [accented, primary, subdivision];
}

class Metronome {
  Metronome._(this.ticks) {
    // Listen to app lifecycle
    AppLifecycleListener(
      onHide: () async {
        if (isPlaying) await updateNotification();
      },
      onDetach: () async {
        // FIXME: This doesn't work... The future never completes
        await Notifications.cancelAll();
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
  static Future<void> initialize() async {
    print(isInitialized);
    if (isInitialized) return;

    final ticks = Ticks(
      accented: await Tick.load("beat_accented.wav"),
      primary: await Tick.load("beat_primary.wav"),
      subdivision: await Tick.load("beat_subdivision.wav"),
    );
    instance = Metronome._(ticks);
    isInitialized = true;
  }

  /// Beats per minutes.
  ///
  /// Clamped between [minBpm] and [maxBpm].
  ///
  /// Does not actually update the playback. This needs to be done manually by calling [reset].
  int get bpm => bpmNotifier.value;
  set bpm(int value) => bpmNotifier.value = value.clamp(minBpm, maxBpm);
  late final PersistentValue<int> bpmNotifier = PersistentValue(
    "metronome/bpm",
    initialValue: 60,
  );

  /// The duration of a beat.
  Duration get beatDuration =>
      Duration(microseconds: 60e6 ~/ (bpm * subdivisions));

  /// The number of beats per bar.
  int get higher => higherNotifier.value;
  set higher(int value) => higherNotifier.value = value;
  late final PersistentValue<int> higherNotifier = PersistentValue(
    "metronome/higher",
    initialValue: 4,
  )..addListener(reset);

  /// The number of notes each beat is divided into.
  int get subdivisions => subdivisionsNotifier.value;
  set subdivisions(int value) => subdivisionsNotifier.value = value;
  late final PersistentValue<int> subdivisionsNotifier = PersistentValue(
    "metronome/subdivisions",
    initialValue: 1,
  )..addListener(reset);

  /// The count of the current beat. Ranges from 0 to [higher] - 1.
  int get count => countNotifier.value;
  final ValueNotifier<int> countNotifier = ValueNotifier(0);

  final Ticks ticks;

  /// The volume of the metronome. Should be between `0.0` and `1.0`.
  double get volume => volumeNotifier.value;
  set volume(double value) => volumeNotifier.value = value;
  late final ValueNotifier<double> volumeNotifier = ValueNotifier(1.0)
    ..addListener(() {
      for (Tick tick in ticks.all) {
        SoLoud.instance.setVolume(tick.handle, volume);
      }
    });

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
    pause();
    countNotifier.value = 0;
    await updateNotification();
  }

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
      SoLoud.instance.seek(tick.handle, Duration.zero);
      SoLoud.instance.setPause(tick.handle, false);
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

  Future<void> updateNotification() async {
    await Notifications.create(
      content: NotificationContent(
        id: 0,
        channelKey: "metronome-controls",
        title: 'Metronome',
        summary: isPlaying ? "Playing" : "Paused",
        body: "$higher ${higher == 1 ? "beat" : "beats"} • $bpm bpm",
        color: Colors.transparent,
        category: NotificationCategory.Transport,
        actionType: ActionType.Default,
        notificationLayout: NotificationLayout.Default,
        showWhen: false,
        autoDismissible: false,
        displayOnForeground: Platform.isIOS ? false : true,
      ),
      actionButtons: [
        if (!isPlaying)
          NotificationActionButton(
            key: "play",
            label: "Play",
            actionType: ActionType.KeepOnTop,
            autoDismissible: false,
            showInCompactView: true,
          ),
        if (isPlaying)
          NotificationActionButton(
            key: "pause",
            label: "Pause",
            actionType: ActionType.KeepOnTop,
            autoDismissible: false,
            showInCompactView: true,
          ),
      ],
    );
  }
}
