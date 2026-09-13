import 'package:musbx/config/migrations.dart';
import 'package:musbx/config/service_loader.dart';
import 'package:musbx/data/repositories/analysis/analysis_repository.dart';
import 'package:musbx/data/repositories/analysis/analysis_repository_remote.dart';
import 'package:musbx/data/repositories/announcement/announcement_repository.dart';
import 'package:musbx/data/repositories/announcement/announcement_repository_remote.dart';
import 'package:musbx/data/repositories/demix/demix_repository.dart';
import 'package:musbx/data/repositories/entitlement/entitlement_repository.dart';
import 'package:musbx/data/repositories/entitlement/entitlement_repository_remote.dart';
import 'package:musbx/data/repositories/feedback/feedback_repository.dart';
import 'package:musbx/data/repositories/feedback/feedback_repository_remote.dart';
import 'package:musbx/data/repositories/notification/notification_repository.dart';
import 'package:musbx/data/repositories/notification/notification_repository_remote.dart';
import 'package:musbx/data/repositories/settings_repository.dart';
import 'package:musbx/data/repositories/song/audio_repository.dart';
import 'package:musbx/data/repositories/song/playback_repository.dart';
import 'package:musbx/data/repositories/song/song_preferences_repository.dart';
import 'package:musbx/data/repositories/song/song_repository.dart';
import 'package:musbx/data/services/ad_service.dart';
import 'package:musbx/data/services/analytics_service.dart';
import 'package:musbx/data/services/audio_capture_service.dart';
import 'package:musbx/data/services/audio_engine_service.dart';
import 'package:musbx/data/services/audio_session_service.dart';
import 'package:musbx/data/services/deep_links_service.dart';
import 'package:musbx/data/services/file_cache_service.dart';
import 'package:musbx/data/services/media_notification_service.dart';
import 'package:musbx/data/services/notification_service.dart';
import 'package:musbx/data/services/permission_service.dart';
import 'package:musbx/data/services/purchase_service.dart';
import 'package:musbx/data/services/service.dart';
import 'package:musbx/data/services/shared_preferences_service.dart';
import 'package:musbx/data/services/song_cache.dart';
import 'package:musbx/data/services/soundcloud_api_client.dart';
import 'package:musbx/data/services/supabase_service.dart';
import 'package:musbx/domain/use_case/add_song_to_library.dart';
import 'package:musbx/domain/use_case/check_song_access.dart';
import 'package:musbx/domain/use_case/clear_song_cache.dart';
import 'package:musbx/domain/use_case/delete_song.dart';
import 'package:musbx/domain/use_case/pitch_detector.dart';
import 'package:musbx/domain/use_case/play_song.dart';
import 'package:musbx/domain/use_case/resume_demixing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Build the object graph the whole app runs on.
///
/// Everything that cannot fail and that something else needs immediately is
/// created here, before the first frame. Optional services are wrapped in a
/// [ServiceLoader] instead, so a missing store or a device offline at launch
/// delays nothing. Repositories and use cases are created lazily from what is
/// already in the tree.
Future<List<SingleChildWidget>> loadProviders() async {
  final packageInfo = await PackageInfo.fromPlatform();

  final fileCache = await FileCacheService.create();
  final sharedPreferences = await SharedPreferencesService.create();

  await Migrations(
    fileCache: fileCache,
    sharedPreferences: sharedPreferences,
    packageInfo: packageInfo,
  ).run();

  final audioEngine = await AudioEngineService.create();
  final audioSession = await AudioSessionService.create();
  final permission = await PermissionService.create();

  final songs = await SongRepository.create(fileCache: fileCache);

  return [
    Provider.value(value: packageInfo),

    Provider.value(value: audioEngine),
    Provider.value(value: audioSession),
    Provider.value(value: fileCache),
    Provider.value(value: sharedPreferences),
    Provider.value(value: permission),
    ..._services,

    ChangeNotifierProvider.value(value: songs),
    ..._repositories,

    ..._useCases,
  ];
}

List<SingleChildWidget> _services = [
  ..._optional(AdService.create, AdService.disabled),
  ..._optional(AnalyticsService.create, AnalyticsService.disabled),
  ..._optional(AudioCaptureService.create, AudioCaptureService.disabled),
  ..._optional(DeepLinksService.create, DeepLinksService.disabled),
  ..._optional(
    MediaNotificationService.create,
    MediaNotificationService.disabled,
  ),
  ..._optional(NotificationService.create, NotificationService.disabled),
  ..._optional(PurchaseService.create, PurchaseService.disabled),
  ..._optional(SoundCloudApiClient.create, SoundCloudApiClient.disabled),
  ..._optional(SupabaseService.create, SupabaseService.disabled),

  Provider(create: (context) => SongCache(fileCache: context.read())),
];

/// Providers for a service that may fail or be unsupported: the [ServiceLoader]
/// holding it, and the service itself, swapped in as soon as one is created.
List<SingleChildWidget> _optional<T extends OptionalService>(
  Future<T> Function() create,
  T Function() fallback,
) => [
  ChangeNotifierProvider<ServiceLoader<T>>(
    create: (_) =>
        ServiceLoader<T>(create: create, fallback: fallback)
          ..ensureAvailable(),
  ),
  ProxyProvider<ServiceLoader<T>, T>(update: (_, loader, _) => loader.value),
];

List<SingleChildWidget> _repositories = [
  Provider(
    create: (context) =>
        AnalysisRepositoryRemote(cache: context.read()) as AnalysisRepository,
  ),
  ChangeNotifierProvider(
    create: (context) =>
        AnnouncementRepositoryRemote(
              sharedPreferences: context.read(),
              supabaseService: context.read(),
            )
            as AnnouncementRepository,
  ),
  ChangeNotifierProvider(
    create: (context) => DemixRepository(cache: context.read()),
  ),
  ChangeNotifierProvider(
    create: (context) =>
        EntitlementRepositoryRemote(purchase: context.read())
            as EntitlementRepository,
  ),
  Provider(
    create: (context) =>
        FeedbackRepositoryRemote(supabaseService: context.read())
            as FeedbackRepository,
  ),
  Provider(
    create: (context) =>
        NotificationRepositoryRemote(
              sharedPreferences: context.read(),
              notificationService: context.read(),
              permissionService: context.read(),
            )
            as NotificationRepository,
  ),
  Provider(create: (context) => AudioRepository(songCache: context.read())),
  Provider(
    create: (context) => SongPreferencesRepository(songCache: context.read()),
  ),
  ChangeNotifierProvider(
    create: (context) => PlaybackRepository(
      audio: context.read(),
      audioEngine: context.read(),
      audioSession: context.read(),
      songPreferences: context.read(),
      mediaNotification: context.read(),
      demix: context.read(),
    ),
  ),

  Provider(
    create: (context) => SettingsRepository(sharedPreferences: context.read()),
  ),
];

List<SingleChildWidget> _useCases = [
  Provider(
    lazy: true,
    create: (context) => AddSongToLibrary(
      songs: context.read(),
      settings: context.read(),
      demixing: context.read(),
    ),
  ),
  Provider(
    lazy: true,
    create: (context) =>
        CheckSongAccess(entitlement: context.read(), songs: context.read()),
  ),
  Provider(
    lazy: true,
    create: (context) => ClearSongCache(
      cache: context.read(),
      preferences: context.read(),
      playback: context.read(),
      demixing: context.read(),
    ),
  ),
  Provider(
    lazy: true,
    create: (context) => DeleteSong(
      cache: context.read(),
      songs: context.read(),
      playback: context.read(),
      demixing: context.read(),
    ),
  ),
  Provider(lazy: true, create: (context) => PitchDetector()),
  Provider(
    lazy: true,
    create: (context) => PlaySong(
      access: context.read(),
      playback: context.read(),
      songs: context.read(),
    ),
  ),
  Provider(
    lazy: true,
    create: (context) => ResumeDemixing(
      songs: context.read(),
      settings: context.read(),
      preferences: context.read(),
      demixing: context.read(),
    ),
  ),
];
