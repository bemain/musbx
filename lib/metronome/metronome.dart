import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musbx/utils/notifications.dart';
import 'package:musbx/utils/persistent_value.dart';

enum BeatSound {
  accented("beat_accented.mp3"),
  primary("beat_primary.mp3"),
  subdivision("beat_subdivision.mp3");

  const BeatSound(this.fileName);

  /// Name of the file used when playing this sound.
  final String fileName;
}

/// TODO: Rewrite using flutter_soloud
class Metronome {
  Metronome._() {
    // Listen to app lifecycle
    AppLifecycleListener(
      onHide: () async {
        if (isPlaying) await updateNotification();
      },
      onDetach: () async {
        // TODO: This doesn't work... The future never completes
        await Notifications.cancelAll();
      },
    );

    player.playingStream.listen((playing) {
      isPlayingNotifier.value = playing;
    });

    player.currentIndexStream.listen((index) async {
      index ??= 0;
      countNotifier.value = (index) ~/ subdivisions;

      // TODO: Vibration doesn't work when [higher] equals 1.
      if (player.volume == 0.0) {
        // Vibrate
        if (index == 0) {
          HapticFeedback.vibrate();
        } else if (index % subdivisions == 0) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.selectionClick();
        }
      }
    });

    reset();
  }

  /// The instance of this singleton.
  static final Metronome instance = Metronome._();

  /// Minimum [bpm] allowed. [bpm] can never be less than this.
  static const int minBpm = 20;

  /// Maximum [bpm] allowed. [bpm] can never be more than this.
  static const int maxBpm = 250;

  /// Beats per minutes.
  ///
  /// Clamped between [minBpm] and [maxBpm].
  ///
  /// Does not actually update the playback. This needs to be done manually by calling [reset].
  int get bpm => bpmNotifier.value;
  set bpm(int value) => bpmNotifier.value = value.clamp(minBpm, maxBpm);
  late final PersistentValue<int> bpmNotifier =
      PersistentValue("metronome/bpm", initialValue: 60);

  /// The number of beats per bar.
  int get higher => higherNotifier.value;
  set higher(int value) => higherNotifier.value = value;
  late final PersistentValue<int> higherNotifier =
      PersistentValue("metronome/higher", initialValue: 4)..addListener(reset);

  /// The number of notes each beat is divided into.
  int get subdivisions => subdivisionsNotifier.value;
  set subdivisions(int value) => subdivisionsNotifier.value = value;
  late final PersistentValue<int> subdivisionsNotifier =
      PersistentValue("metronome/subdivisions", initialValue: 1)
        ..addListener(reset);

  /// The count of the current beat. Ranges from 0 to [higher] - 1.
  int get count => countNotifier.value;
  final ValueNotifier<int> countNotifier = ValueNotifier(0);

  /// Whether the metronome is playing.
  bool get isPlaying => isPlayingNotifier.value;
  set isPlaying(bool value) => value ? play() : pause();
  late final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false)
    ..addListener(updateNotification);

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
  ///   try { // This needs to be done in a `try` block. Otherwise when one load fails, all the following ones will fail, too.
  ///     await awaitBeforeLoading;
  ///   } catch (_) {}
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
    await updateNotification();
    loadAudioLock = _updateAudioSource(awaitBeforeLoading: loadAudioLock);
    await loadAudioLock;
  }

  /// Awaits [awaitBeforeLoading] and then updates the [player]'s audio source.
  Future<void> _updateAudioSource({Future<void>? awaitBeforeLoading}) async {
    try {
      await awaitBeforeLoading;
    } catch (_) {}

    await player.setAudioSource(ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: List.generate(higher * subdivisions, (index) {
        final beat = index == 0
            ? BeatSound.accented
            : index % subdivisions == 0
                ? BeatSound.primary
                : BeatSound.subdivision;

        return ClippingAudioSource(
          start: Duration.zero,
          end: Duration(microseconds: 60e6 ~/ (bpm * subdivisions)),
          child: AudioSource.asset("assets/sounds/metronome/${beat.fileName}"),
        );
      }),
    ));
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
