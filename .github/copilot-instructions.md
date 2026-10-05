# Musician's Toolbox (musbx) - AI Coding Instructions

## Project Overview

Flutter app combining a metronome, tuner, drone and music player, with
AI-powered chord detection, audio demixing (separating vocals and instruments)
and audio manipulation (pitch, speed, equalizer).

## Git Conventions (Required)

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- Format: `<type>[(scope)]: <description>` (types: feat, fix, refactor, docs,
  test, chore, perf, ci)
- Breaking changes: `BREAKING CHANGE:` footer or `!` after type/scope
- Branches: `feat/[area]/[issue-ref]/<kebab-case-description>` (areas: demixer,
  tuner, songs, metronome)
- Example: `feat/songs/issue72/configure-audio-session`

## Architecture

Layered, with UI grouped by feature and data and domain grouped by type.

```
lib/
  config/       Composition root: providers, migrations, optional-service loading
  data/
    services/   One wrapper per external system (SoLoud, Supabase, AdMob, …)
    repositories/  Single source of truth per concern; consume services
    models/     Models mirroring an external API's shape
  domain/
    models/     App models (Song, Pitch, Chord, …)
    use_case/   Logic spanning several repositories
  routing/      go_router configuration and the shell branches
  <feature>/    UI: metronome, tuner, drone, songs, settings, widgets
```

Dependencies are wired in `lib/config/dependencies.dart` and injected with
`package:provider`. Nothing is a global singleton except `Metronome.instance`,
`Tuner.instance` and `Drone.instance`, which are being migrated away from.

### Key pieces

**Songs** (`lib/songs/`, `lib/data/repositories/song/`)

- `SongRepository` — the library, backed by a `HistoryHandler` so it doubles as
  a play history.
- `AudioRepository` — turns a `Song`'s `AudioReference` (`UrlAudio`,
  `FileAudio`, `BytesAudio`) into a playable `AudioSource`, caching the audio.
- `PlaybackRepository` — the loaded song and everything the user can do to it.
  A demixed song plays as one sound per stem, driven through a single SoLoud
  voice group. Audible state is read from `SongPreferences` on load and written
  back on unload.
- `DemixRepository` — at most one `DemixingProcess` per song; processes survive
  a rebuild of the provider tree.
- `AnalysisRepository` — chords (server-side) and waveform (local, mobile only),
  both cached on disk.

**Musbx API** (`lib/data/services/musbx_api/`)

- `MusbxApi.getClient()` picks the first reachable host whose version satisfies
  `MusbxApi.version`.
- Work is submitted as a `Job` and polled for a `JobReport`; there are no push
  updates.

**Storage**

- `FileCacheService` splits files by durability: `scratch` (regenerable, the OS
  may purge it) and `persistent` (user data). Writes are atomic.
- `SongCache` names every file belonging to a song within that split.
- `SharedPreferencesService` hands out `PersistentValue` /
  `TransformedPersistentValue` notifiers rather than raw reads and writes.

### Patterns

**`Result<T>`** (`lib/utils/result.dart`) — the outcome of anything that may
fail. `Ok`, or a `Failure` subtype: `Unavailable`, `Cancelled`,
`AccessRestricted`. Switch on it; the analyzer checks exhaustiveness.

**`OptionalService`** (`lib/data/services/service.dart`) — a service that may
have nothing behind it on a given device. Disabled instances throw
`ServiceDisabled`; `OptionalService.guard` turns that into
`Result.unavailable`. `ServiceLoader` keeps a fallback in place and retries
when a failure could still pass.

**`Process<T>`** (`lib/utils/process.dart`) — a long task with progress,
cancellation and error capture. Implement `execute`, report through
`progressNotifier`, and call `breakIfCancelled` between awaits. Runs once.

**Type aliases** — `typedef Json = Map<String, dynamic>;` in
`lib/utils/utils.dart`.

## Development Workflow

```bash
flutter pub get                        # Install dependencies
dart run flutter_launcher_icons         # Update app icons
dart run flutter_native_splash:create   # Update splash screens
dart run tool/generate_icons.dart       # Rebuild the CustomIcons font
flutter run                             # Run the app
flutter build apk --release             # Android release build
```

### Dependencies of note

- Audio: `flutter_soloud`, `audio_service`, `audio_session`, `flutter_recorder`
- UI: `dynamic_color` and `material_plus` (both git forks), `google_fonts`,
  `material_symbols_icons`
- State and routing: `provider`, `go_router`, `shared_preferences`
- Backend: `dio`, `supabase_flutter`, Firebase for analytics

### Linting and formatting

- Strict analysis: `strict-casts`, `strict-inference`, `strict-raw-types`
- Formatter: `trailing_commas: preserve`, `page_width: 79`
- Run `flutter analyze` and `dart format lib/` before committing

## UI Conventions

- Navigation: four shell branches (`Routes.branches`); settings and
  announcements sit outside the shell. Use `navigatorKey.currentContext` when no
  local context is available, and `navigationShell.goBranch(index)` to switch
  tabs.
- Theming: Material 3 with dynamic colors. Read colors from
  `Theme.of(context).colorScheme`; the sliders and waveform read
  `PositionSliderStyle` out of the theme extensions.
- Theme mode is persisted through `SettingsRepository.themeModeNotifier`.
- Shared widgets live in `lib/widgets/`; `ResultBuilder` builds from a pending
  `Result`, and `PermissionBuilder` gates a feature behind a `Permission`.

## Gotchas

1. `firebase_options.dart` is generated — do not edit it by hand.
2. A song's preferences live in the persistent cache, so clearing its audio
   leaves them intact; `DeleteSong` is what removes both.
3. `SharedPreferencesService` prefixes every key with `musbx/`, so `clear()`
   cannot reach preferences written by plugins.
4. Demixing survives a provider rebuild, because `DemixRepository` holds its
   processes statically.

## Testing

Single test file: `test/widget_test.dart` (basic smoke test). No extensive test
coverage yet.

## Key Files Reference

- [lib/main.dart](../lib/main.dart) — app entry
- [lib/config/dependencies.dart](../lib/config/dependencies.dart) — composition
  root
- [lib/routing/router.dart](../lib/routing/router.dart) — router and shell
- [lib/data/repositories/song/playback_repository.dart](../lib/data/repositories/song/playback_repository.dart)
  — the loaded song and its playback
- [lib/utils/result.dart](../lib/utils/result.dart) — the `Result` type
- [lib/utils/process.dart](../lib/utils/process.dart) — cancellable async tasks
- [pubspec.yaml](../pubspec.yaml) — dependencies, note the forked packages
