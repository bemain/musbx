import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/metronome/beat_sound.dart';
import 'package:musbx/widgets.dart';

class Metronome {
  Metronome._() {
    player.playingStream.listen((playing) {
      isPlayingNotifier.value = playing;
    });

    player.currentIndexStream.listen((index) async {
      count = index ?? 0;

      if (await FlutterVolumeController.getMute() == true) {
        _vibrate();
      }
    });

    reset();
  }

  /// The instance of this singleton.
  static final Metronome instance = Metronome._();

  /// Minimum [bpm] allowed. [bpm] can never be less than this.
  static const int minBpm = 20;

  /// Maximum [bpm] allowed. [bpm] can never be more than this.
  static const int maxBpm = 400;

  /// Used internally to show notifications.
  static final AwesomeNotifications _notifications = AwesomeNotifications();

  /// Beats per minutes.
  ///
  /// Clamped between [minBpm] and [maxBpm].
  ///
  /// Does not actually update the playback. This needs to be done manually by calling [reset].
  int get bpm => bpmNotifier.value;
  set bpm(int value) => bpmNotifier.value = value.clamp(minBpm, maxBpm);
  final ValueNotifier<int> bpmNotifier = ValueNotifier(60);

  /// The number of beats per bar.
  int get higher => beats.value.length;

  /// The beats played by the metronome.
  ///
  /// Automatically resets [count] when changed.
  late final ListNotifier<BeatSound> beats =
      ListNotifier(List.generate(4, (i) => BeatSound.primary))
        ..addListener(reset);

  /// The count of the current beat. Ranges from 0 to [higher] - 1.
  int get count => countNotifier.value;
  set count(int value) => countNotifier.value = value;
  final ValueNotifier<int> countNotifier = ValueNotifier(0);

  /// Whether the metronome is playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? play() : pause();
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);

  /// The [AudioPlayer] used for playback.
  final AudioPlayer player = AudioPlayer()..setLoopMode(LoopMode.all);

  /// The process currently loading an [AudioSource], or `null` if no source has been loaded.
  ///
  /// This is used to make sure two processes don't try to load a song at the same time.
  /// Every process wanting to set [player]'s audio source must:
  ///  1. Create a future that first awaits [loadAudioLock] and then sets [player]'s audio source.
  ///  2. Override [loadAudioLock] with the newly created future.
  ///  3. Await the future it created.
  ///
  /// Here is an example of how that could be done:
  /// ```
  /// Future<void> loadAudioSource() async {
  ///   loadSongLock = _loadAudioSource(loadSongLock);
  ///   await loadSongLock;
  /// }
  ///
  /// Future<void> _loadAudioSource(Future<void>? awaitBeforeLoading) async {
  ///   await awaitBeforeLoading;
  ///   await player.setAudioSource(...)
  /// }
  ///
  /// ```
  Future<void>? loadAudioLock;

  /// Start the metronome.
  Future<void> play() async => await player.play();

  /// Pause the metronome.
  Future<void> pause() async => await player.pause();

  /// Reset [count] and restart playback.
  Future<void> reset() async {
    loadAudioLock = _updateAudioSource(awaitBeforeLoading: loadAudioLock);
    await loadAudioLock;
  }

  /// Awaits [awaitBeforeLoading] and then updates the [player]'s audio source.
  Future<void> _updateAudioSource({Future<void>? awaitBeforeLoading}) async {
    await awaitBeforeLoading;
    await player.setAudioSource(ConcatenatingAudioSource(
      useLazyPreparation: false,
      children: beats.value
          .map((beat) => ClippingAudioSource(
                start: Duration.zero,
                end: Duration(milliseconds: 60000 ~/ bpm),
                child: AudioSource.asset("assets/sounds/${beat.fileName}"),
              ))
          .toList(),
    ));
  }

  /// Trigger a vibration based on [count].
  void _vibrate() {
    switch (beats[count]) {
      case BeatSound.primary:
        HapticFeedback.vibrate();
        break;
      case BeatSound.accented:
        HapticFeedback.heavyImpact();
        break;
      case BeatSound.none:
    }
  }

  /// Callback for when the user taps an action on the notification while the app is the background
  @pragma("vm:entry-point")
  static Future<void> _onNotificationActionReceived(
    ReceivedAction action,
  ) async {
    print(action);
  }

  Future<void> intializeNotification() async {
    await _notifications.initialize(
      'resource://drawable/ic_notification',
      [
        NotificationChannel(
          channelGroupKey: "metronome-group",
          channelKey: "metronome-controls",
          channelName: "Quick Access",
          channelDescription:
              "Control the Metronome directly from your notifications drawer",
          importance: NotificationImportance.Low,
          enableLights: false,
          enableVibration: false,
          playSound: false,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: "metronome-group",
          channelGroupName: "Metronome",
        ),
      ],
      debug: true,
    );

    await _notifications.setListeners(
      onActionReceivedMethod: _onNotificationActionReceived,
    );

    // TODO: Don't request during intialization
    await _notifications.requestPermissionToSendNotifications(
      channelKey: "metronome-controls",
      permissions: [NotificationPermission.Alert],
    );

    await _notifications.createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: "metronome-controls",
        title: 'Metronome',
        color: Colors.transparent,
        category: NotificationCategory.Service,
        actionType: ActionType.Default,
        autoDismissible: false,
      ),
    );
  }
}
