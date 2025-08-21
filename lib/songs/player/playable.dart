import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:musbx/songs/demixer/demixer.dart';
import 'package:musbx/songs/player/filter.dart';
import 'package:musbx/songs/player/song_player.dart';
import 'package:musbx/songs/player/source.dart';

/// An object that can be played by [SongPlayer].
///
/// It wraps around [SoLoud]'s [AudioSource] and exposes a [play] method that
/// the [SongPlayer] calls when it wants to start playing the song.
///
/// Note that this class is not instantiable directly but should be obtained
/// through a [SongSource], which containes instructions on how a Playable is created.
/// When you are done playing this sound you should [dispose] it to free up resources.
abstract class Playable {
  /// Play this sound using [SoLoud] and return the handle to the sound.
  FutureOr<SoundHandle> play({bool paused = true, bool looping = true});

  /// The length of the audio that this plays.
  ///
  /// Before accessing this, make sure [play] has been called.
  Duration get duration;

  /// Get the filters for this audio.
  ///
  /// A [handle] can optionally be passed to get the filter of a specific song.
  Filters filters({SoundHandle? handle});

  /// Free the resources used by this object.
  FutureOr<void> dispose() {}
}

class SinglePlayable extends Playable {
  /// A [Playable] that plays a single [source].
  SinglePlayable(this.source);

  /// The source of the sound that is played.
  final AudioSource source;

  @override
  Filters filters({SoundHandle? handle}) => Filters((apply) {
    apply(source.filters, handle: handle);
  });

  @override
  Duration get duration => SoLoud.instance.getLength(source);

  @override
  Future<SoundHandle> play({bool paused = true, bool looping = true}) async {
    return await SoLoud.instance.play(
      source,
      paused: paused,
      looping: looping,
    );
  }
}

class MultiPlayable extends Playable {
  /// A [Playable] that plays multiple [sources] simultaneously.
  ///
  /// This allows the files to play simultaneously while the volume can be controlled individually.
  MultiPlayable(this.sources);

  /// The sources of the individual sounds that are played simultaneously.
  final Map<StemType, AudioSource> sources;

  /// The handles of the individual sounds that are played simultaneously.
  Map<StemType, SoundHandle>? handles;

  @override
  Filters filters({SoundHandle? handle}) => Filters((apply) {
    sources.forEach((stem, source) {
      apply(source.filters, handle: handles?[stem]);
    });
  });

  @override
  Duration get duration => SoLoud.instance.getLength(sources.values.first);

  /// Play the underlying sounds using [SoLoud], add them all to a group and return the group handle.
  @override
  Future<SoundHandle> play({bool paused = true, bool looping = true}) async {
    handles ??= {
      for (final e in sources.entries)
        e.key: await SoLoud.instance.play(
          e.value,
          paused: paused,
          looping: looping,
        ),
    };

    final SoundHandle groupHandle = SoLoud.instance.createVoiceGroup();
    if (groupHandle.isError) {
      throw Exception("[DEMIXER] Failed to create voice group");
    }

    SoLoud.instance.addVoicesToGroup(
      groupHandle,
      handles!.values.toList(),
    );
    return groupHandle;
  }

  @override
  Future<void> dispose() async {
    if (handles != null) {
      for (final handle in handles!.values) {
        await SoLoud.instance.stop(handle);
      }
      handles = null;
    }
  }
}
