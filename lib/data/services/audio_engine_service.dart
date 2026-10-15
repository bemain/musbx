import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/data/models/sound_group.dart';
import 'package:musbx/domain/models/part.dart';

/// Owns the SoLoud audio engine, which has to be initialized once before any
/// sound can be played.
class AudioEngineService {
  AudioEngineService._(this._soLoud);

  final SoLoud _soLoud;

  /// Create the service, initializing the engine.
  static Future<AudioEngineService> create({SoLoud? soLoud}) async {
    final s = soLoud ?? SoLoud.instance;

    await s.init(bufferSize: 512);
    return AudioEngineService._(s);
  }

  Future<AudioSource> loadFile(File file) => _soLoud.loadFile(file.path);
  Future<AudioSource> loadAsset(String key) => _soLoud.loadAsset(key);
  Future<void> unload(AudioSource source) => _soLoud.disposeSource(source);

  /// Start every one of [sources] paused and looping, in one voice group so
  /// that they are paused, resumed and sped up together.
  SongPartsGroup createSound(Map<Part?, AudioSource> sources) {
    // Activate filters. This needs to be done before the sound is played.
    sources.forEach((part, source) {
      for (var filter in [
        source.filters.pitchShiftFilter,
        source.filters.parametricEqFilter,
      ]) {
        if (!filter.isActive) filter.activate();
      }
    });

    final Map<Part?, SoundHandle> handles = {
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
    return SongPartsGroup(
      parts: sources.keys.toList(),
      sources: sources.values.toList(),
      handles: handles.values.toList(),
      groupHandle: groupHandle,
    );
  }

  /// Play [source] once at [atTime] on the engine's clock.
  ///
  /// See [getEngineTime].
  SoundHandle schedule(
    AudioSource source,
    Duration atTime, {
    double volume = 1.0,
  }) => _soLoud.playScheduled(source, atTime, volume: volume);

  /// Stop [sound] and free its sources.
  Future<void> stop(SoundGroup sound) async {
    await Future.wait([
      for (var handle in sound.handles) _soLoud.stop(handle),
      for (var source in sound.sources) unload(source),
    ]);
    _soLoud.destroyVoiceGroup(sound.groupHandle);
  }

  void unschedule(SoundHandle handle) => _soLoud.stop(handle);

  void resume(SoundGroup sound) => _soLoud.setPause(sound.groupHandle, false);
  void pause(SoundGroup sound) => _soLoud.setPause(sound.groupHandle, true);

  Duration getDuration(SongPartsGroup sound) =>
      _soLoud.getLength(sound.sources.first);

  Duration getPosition(SongPartsGroup sound) =>
      _soLoud.getPosition(sound.handles.first);

  /// The mixer's clock, which sounds are scheduled against. Only advances
  /// while the engine is mixing.
  Duration getEngineTime() => _soLoud.getEngineTime();

  /// The time on [getEngineTime]'s clock of what is being heard right now.
  Duration getPlayheadTime() => _soLoud.getPlayheadTime();

  void seek(SongPartsGroup sound, Duration position) {
    for (final handle in sound.handles) {
      _soLoud.seek(handle, position);
    }
  }

  double getSpeed(SoundGroup sound) =>
      _soLoud.getRelativePlaySpeed(sound.groupHandle);
  void setSpeed(SoundGroup sound, double speed) {
    _soLoud.setRelativePlaySpeed(sound.groupHandle, speed);
  }

  double getPitch(SoundGroup sound) {
    return sound.sources.first.filters.pitchShiftFilter
        .semitones(soundHandle: sound.handles.first)
        .value;
  }

  /// Transpose [sound] by [value] semitones.
  ///
  /// Compensates for the pitch shift the current speed causes, so this has to
  /// be called again whenever the speed changes.
  void setPitch(SoundGroup sound, double value) {
    for (int i = 0; i < sound.handles.length; i += 1) {
      sound.sources[i].filters.pitchShiftFilter
              .semitones(soundHandle: sound.handles[i])
              .value =
          value - 12 * (log(getSpeed(sound)) / ln2);
    }
  }

  int getNumBands(SoundGroup sound) {
    return sound.sources.first.filters.parametricEqFilter
        .numBands(soundHandle: sound.handles.first)
        .value
        .toInt();
  }

  void setNumBands(SoundGroup sound, int value) {
    for (int i = 0; i < sound.handles.length; i += 1) {
      sound.sources[i].filters.parametricEqFilter
          .numBands(soundHandle: sound.handles[i])
          .value = value
          .toDouble();
    }
  }

  void setBandGain(SoundGroup sound, int band, double gain) {
    for (int i = 0; i < sound.handles.length; i += 1) {
      sound.sources[i].filters.parametricEqFilter
              .bandGain(band, soundHandle: sound.handles[i])
              .value =
          gain;
    }
  }

  double? getPartVolume(SongPartsGroup sound, Part? part) =>
      !sound.parts.contains(part)
      ? null
      : _soLoud.getVolume(sound.handles[sound.parts.indexOf(part)]);
  void setPartVolume(SongPartsGroup sound, Part? part, double volume) {
    if (!sound.parts.contains(part)) return;
    _soLoud.setVolume(sound.handles[sound.parts.indexOf(part)], volume);
  }

  /// An empty, paused group of tones. See [setTones].
  ToneGroup createTones() {
    final SoundHandle groupHandle = _soLoud.createVoiceGroup();
    if (groupHandle.isError) {
      throw Exception("Failed to create voice group");
    }

    return ToneGroup(
      sources: [],
      handles: [],
      groupHandle: groupHandle,
    );
  }

  /// Make [group] sound one tone per entry in [frequencies], adding and
  /// removing tones as needed.
  ///
  /// Returns the updated group, which replaces [group]. Tones that are added
  /// start paused.
  Future<ToneGroup> setTones(
    ToneGroup group,
    List<double> frequencies,
    WaveForm waveform,
  ) async {
    final List<AudioSource> sources = [...group.sources];
    final List<SoundHandle> handles = [...group.handles];
    for (int i = handles.length; i < frequencies.length; i++) {
      final source = await _soLoud.loadWaveform(waveform, false, 1.0, 0.0);
      final handle = _soLoud.play(source, paused: true);
      _soLoud.addVoicesToGroup(group.groupHandle, [handle]);
      sources.add(source);
      handles.add(handle);
    }

    // Remove excess players
    for (int i = handles.length - 1; i >= frequencies.length; i--) {
      await _soLoud.stop(handles[i]);
      await _soLoud.disposeSource(sources[i]);

      handles.removeAt(i);
      sources.removeAt(i);
    }

    // Set frequencies
    for (int i = 0; i < sources.length; i++) {
      _soLoud.setWaveform(sources[i], waveform);
      _soLoud.setWaveformFreq(sources[i], frequencies[i]);
    }
    return ToneGroup(
      sources: sources,
      handles: handles,
      groupHandle: group.groupHandle,
    );
  }

  Future<void> dispose() async {
    _soLoud.deinit();
  }
}
