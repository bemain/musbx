import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

class AudioEngineService {
  AudioEngineService._(this.soLoud);

  final SoLoud soLoud;

  static Future<AudioEngineService> create({SoLoud? soLoud}) async {
    final s = soLoud ?? SoLoud.instance;

    await s.init(bufferSize: 512);
    return AudioEngineService._(s);
  }

  Future<void> dispose() async {
    soLoud.deinit();
  }
}
