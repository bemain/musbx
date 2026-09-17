import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/data/models/sound_group.dart';
import 'package:musbx/domain/models/stem_type.dart';

/// Owns the SoLoud audio engine, which has to be initialized once before any
/// sound can be played.
class AudioEngineService {
  AudioEngineService._(this._soLoud);

  final SoLoud _soLoud;

  static Future<AudioEngineService> create({SoLoud? soLoud}) async {
    final s = soLoud ?? SoLoud.instance;

    await s.init(bufferSize: 512);
    return AudioEngineService._(s);
  }

  Future<AudioSource> loadFile(File file) => _soLoud.loadFile(file.path);
  Future<void> unload(AudioSource source) => _soLoud.disposeSource(source);

  SoundGroup play(Map<StemType?, AudioSource> sources) {
    // Activate filters. This needs to be done before the sound is played.
    sources.forEach((stem, source) {
      for (var filter in [
        source.filters.pitchShiftFilter,
        source.filters.parametricEqFilter,
      ]) {
        if (!filter.isActive) filter.activate();
      }
    });

    final Map<StemType?, SoundHandle> handles = {
      for (final e in sources.entries)
        e.key: _soLoud.play(
          e.value,
          paused: true,
          looping: true,
        ),
    };

    // Create group
    final SoundHandle groupHandle = _soLoud.createVoiceGroup();
    if (groupHandle.isError) {
      throw Exception("Failed to create voice group");
    }

    _soLoud.addVoicesToGroup(
      groupHandle,
      handles.values.toList(),
    );
    return SoundGroup(
      sources: sources,
      handles: handles,
      groupHandle: groupHandle,
    );
  }

  Future<void> stop(SoundGroup sound) async {
    await Future.wait([
      for (var handle in sound.handles.values) _soLoud.stop(handle),
      for (var source in sound.sources.values) unload(source),
    ]);
    _soLoud.destroyVoiceGroup(sound.groupHandle);
  }

  void resume(SoundGroup sound) => _soLoud.setPause(sound.groupHandle, false);
  void pause(SoundGroup sound) => _soLoud.setPause(sound.groupHandle, true);

  Duration getDuration(SoundGroup sound) =>
      _soLoud.getLength(sound.sources.values.first);

  Duration getPosition(SoundGroup sound) =>
      _soLoud.getPosition(sound.handles.values.first);

  void seek(SoundGroup sound, Duration position) {
    sound.handles.forEach((stem, handle) {
      _soLoud.seek(handle, position);
    });
  }

  double getSpeed(SoundGroup sound) =>
      _soLoud.getRelativePlaySpeed(sound.groupHandle);
  void setSpeed(SoundGroup sound, double speed) {
    _soLoud.setRelativePlaySpeed(sound.groupHandle, speed);
  }

  double getPitch(SoundGroup sound) {
    return sound.sources.values.first.filters.pitchShiftFilter
        .semitones(soundHandle: sound.handles.values.first)
        .value;
  }

  void setPitch(SoundGroup sound, double value) {
    for (final stem in sound.sources.keys) {
      sound.sources[stem]?.filters.pitchShiftFilter
              .semitones(soundHandle: sound.handles[stem])
              .value =
          value - 12 * (log(getSpeed(sound)) / ln2);
    }
  }

  int getNumBands(SoundGroup sound) {
    return sound.sources.values.first.filters.parametricEqFilter
        .numBands(soundHandle: sound.handles.values.first)
        .value
        .toInt();
  }

  void setNumBands(SoundGroup sound, int value) {
    sound.sources.values.first.filters.parametricEqFilter
        .numBands(soundHandle: sound.handles.values.first)
        .value = value
        .toDouble();
  }

  double getBandGain(SoundGroup sound, int band) {
    return sound.sources.values.first.filters.parametricEqFilter
        .bandGain(band, soundHandle: sound.handles.values.first)
        .value;
  }

  void setBandGain(SoundGroup sound, int band, double gain) {
    sound.sources.forEach((type, source) {
      source.filters.parametricEqFilter
              .bandGain(band, soundHandle: sound.handles[type])
              .value =
          gain;
    });
  }

  double? getStemVolume(SoundGroup sound, StemType? stem) =>
      sound.handles[stem] == null
      ? null
      : _soLoud.getVolume(sound.handles[stem]!);
  void setStemVolume(SoundGroup sound, StemType? stem, double volume) {
    if (sound.handles[stem] == null) return;
    _soLoud.setVolume(sound.handles[stem]!, volume);
  }

  Future<void> dispose() async {
    _soLoud.deinit();
  }
}
