import 'dart:async';

import 'package:audio_session/audio_session.dart';

/// Something the system wants playback to do, because of another app or a
/// change in audio hardware.
enum AudioSessionEvent {
  /// Lower the volume; another app is playing something short over ours.
  duck,

  /// Stop playing; another app has taken over the audio output, or the headphones
  /// were unplugged.
  pause,

  /// The interruption that caused a [duck] is over.
  unduck,

  /// The interruption that caused a [pause] is over.
  resume,
}

/// Negotiates audio focus with the rest of the system.
///
/// Configures the session once for both playback and recording, and reports
/// interruptions — a phone call, another app, headphones being unplugged — as
/// [AudioSessionEvent]s for playback to react to.
class AudioSessionService {
  AudioSessionService(this._session) {
    _session.interruptionEventStream.listen(_handleInterruption);
    _session.becomingNoisyEventStream.listen((_) {
      // The user unplugged the headphones, so we should pause or lower the volume.
      _controller.add(AudioSessionEvent.pause);
    });
  }

  final AudioSession _session;

  static Future<AudioSessionService> create({AudioSession? session}) async {
    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    return AudioSessionService(session);
  }

  /// Claim or release audio focus. Claim it before playing, release it when
  /// stopping, so other apps are not kept ducked.
  Future<void> setActive(bool value) => _session.setActive(value);

  final StreamController<AudioSessionEvent> _controller =
      StreamController.broadcast();

  late final Stream<AudioSessionEvent> eventStream = _controller.stream;

  void _handleInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          _controller.add(AudioSessionEvent.duck);
        case AudioInterruptionType.pause:
          _controller.add(AudioSessionEvent.pause);
        case AudioInterruptionType.unknown:
          break;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          _controller.add(AudioSessionEvent.unduck);
        case AudioInterruptionType.pause:
          _controller.add(AudioSessionEvent.resume);
        case AudioInterruptionType.unknown:
          break;
      }
    }
  }
}
