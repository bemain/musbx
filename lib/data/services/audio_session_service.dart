import 'dart:async';

import 'package:audio_session/audio_session.dart';

enum AudioSessionEvent {
  duck,
  pause,
  unduck,
  resume,
}

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

  // TODO: Remove once we introduce `provider`.
  static late final AudioSessionService instance;
  static Future<void> initialize() async {
    instance = await create();
  }

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
