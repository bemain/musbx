import 'dart:async';
import 'dart:io';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/models/sound_group.dart';
import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/demix/demixing_process.dart';
import 'package:musbx/data/repositories/entitlement/entitlement_repository.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/audio_session_service.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/domain/models/part.dart';
import 'package:musbx/utils/result.dart';

import 'fixtures.dart';

/// Register the fallback values `any()` needs for the types used in tests.
void registerFallbacks() {
  registerFallbackValue(File(""));
  registerFallbackValue(MockAudioSource());
  registerFallbackValue(Duration.zero);
  registerFallbackValue(WaveForm.sin);
  registerFallbackValue(<double>[]);
  registerFallbackValue(<Part?, AudioSource>{});
  registerFallbackValue(urlSong("fallback"));
  final group = SongPartsGroup(
    parts: const [null],
    sources: const [],
    handles: const [],
    groupHandle: const SoundHandle(0),
  );
  registerFallbackValue(group);
  registerFallbackValue(_tones());
}

ToneGroup _tones([int count = 0]) => ToneGroup(
  sources: [for (var i = 0; i < count; i++) MockAudioSource()],
  handles: [for (var i = 0; i < count; i++) SoundHandle(i + 1)],
  groupHandle: const SoundHandle(100),
);

/// An audio engine where every operation succeeds and every loaded song is
/// [duration] long. Restub individual methods to change that.
class MockAudioEngine extends Mock implements AudioEngineService {
  MockAudioEngine({Duration duration = const Duration(minutes: 3)}) {
    Future<AudioSource> load(Invocation _) async => MockAudioSource();

    when(() => loadFile(any())).thenAnswer(load);
    when(() => loadAsset(any())).thenAnswer(load);
    when(() => unload(any())).thenAnswer((_) async {});
    when(() => stop(any())).thenAnswer((_) async {});
    when(() => createSound(any())).thenAnswer((invocation) {
      final sources =
          invocation.positionalArguments.first as Map<Part?, AudioSource>;
      return SongPartsGroup(
        parts: sources.keys.toList(),
        sources: sources.values.toList(),
        handles: [for (var i = 0; i < sources.length; i++) SoundHandle(i + 1)],
        groupHandle: const SoundHandle(100),
      );
    });
    when(() => getDuration(any())).thenReturn(duration);
    when(() => getPosition(any())).thenReturn(Duration.zero);
    when(createTones).thenReturn(_tones());
    when(() => setTones(any(), any(), any())).thenAnswer(
      (invocation) async => _tones(
        (invocation.positionalArguments[1] as List<double>).length,
      ),
    );
    when(getEngineTime).thenReturn(Duration.zero);
    when(getPlayheadTime).thenReturn(Duration.zero);
    when(
      () => schedule(any(), any(), volume: any(named: "volume")),
    ).thenReturn(const SoundHandle(1));
  }
}

/// An audio session whose events are sent through [events].
class MockAudioSource extends Mock implements AudioSource {}

class MockAudioSession extends Mock implements AudioSessionService {
  MockAudioSession() {
    when(() => eventStream).thenAnswer((_) => events.stream);
    when(() => setActive(any())).thenAnswer((_) async {});
  }

  // ignore: close_sinks, lives as long as the mock
  final StreamController<AudioSessionEvent> events =
      StreamController.broadcast();
}

/// A demix repository with nothing cached, which never contacts a server.
class MockDemixRepository extends Mock implements DemixRepository {
  MockDemixRepository() {
    when(() => partsFor(any())).thenAnswer((_) async => null);
    when(() => start(any())).thenAnswer(
      (invocation) => Result.ok(MockDemixingProcess()),
    );
  }
}

class MockDemixingProcess extends Mock implements DemixingProcess {}

/// An enabled Supabase backend with no signed-in user.
class MockSupabaseService extends Mock implements SupabaseService {
  MockSupabaseService() {
    when(() => isEnabled).thenReturn(true);
    when(() => currentUser).thenReturn(null);
  }
}

class FakeEntitlementRepository extends EntitlementRepository {
  FakeEntitlementRepository({this.hasPremium = false});

  @override
  bool hasPremium;

  @override
  Future<Result<bool>> buyPremium() async => Result.ok(hasPremium = true);

  @override
  Future<Result<void>> restore() async => Result.ok(null);
}
