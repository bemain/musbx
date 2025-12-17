# Musician's Toolbox (musbx) - AI Coding Instructions

## Project Overview
Flutter app combining metronome, tuner, drone, and music player features with AI-powered chord detection, audio demixing (separating vocals/instruments), and audio manipulation (pitch/speed changes).

## Git Conventions (Required)
Follow [Conventional Commits](https://www.conventionalcommits.org/) since Sep 25 2023:
- Format: `<type>[(scope)]: <description>` (types: feat, fix, chore, etc.)
- Breaking changes: `BREAKING CHANGE:` footer or `!` after type/scope
- Branches: `feat/[area]/[issue-ref]/<kebab-case-description>` (areas: demixer, tuner, songs, metronome)
- Example: `feat/songs/issue72/configure-audio-session`

## Architecture

### Core Structure
- **Feature-based modules**: `lib/{songs,metronome,tuner,drone}/` - each self-contained
- **Shared utilities**: `lib/utils/` - persistent storage, notifications, processes
- **Navigation**: Shell routing with go_router, 4 main branches (metronome/songs/tuner/drone)
- **Theme**: Material 3 with dynamic colors, tone-based from forked `dynamic_color` package

### Key Components

**Songs Module** (`lib/songs/`)
- `player/` - Audio playback using flutter_soloud (SoLoud engine)
  - `Song` class: immutable representation with `AudioProvider` for source resolution
  - `SongPlayer` component pattern for features (demixer, slowdowner, equalizer, loop, analyzer)
  - `SongsAudioHandler` extends AudioHandler for background playback/media notifications
- `demixer/` - ML-based stem separation (vocals, piano, guitar, bass, drums, other)
  - Jobs sent to backend API, stems cached locally as separate audio files
  - `DemixingProcess` extends `Process<T>` pattern for cancellable async work
- `musbx_api/` - Backend API client for demixing and chord analysis jobs
  - Jobs use polling pattern with progress tracking
  - Results cached in `song.cacheDirectory` under app documents

**State Management Patterns**
1. `PersistentValue<T>` - ValueNotifier that auto-saves to SharedPreferences
2. `TransformedPersistentValue<T, S>` - Type conversion layer over PersistentValue
3. Component pattern: `SongPlayerComponent<P extends SongPlayer>` for modular features
4. `Process<T>` abstract class - standard pattern for cancellable long-running tasks with progress tracking

**Singleton Services**
- `Songs.handler` - AudioHandler (initialize with `Songs.initialize()`)
- `Metronome.instance` - Global metronome with notification support
- `SoLoud.instance` - Audio engine (init in `Songs.initialize()`)
- `Analytics.initialize()` - Firebase analytics
- `Notifications.initialize()` - awesome_notifications setup

### Critical Patterns

**Late Final Initialization**
```dart
// Common pattern throughout codebase
late final ValueNotifier<bool> enabledNotifier = ValueNotifier(true)
  ..addListener(_updateEnabled);
```

**Audio Source Resolution**
`AudioProvider` subclasses (YtdlpAudio, FileAudio, DemixedAudio) resolve to `AudioSource` for playback. Always call `resolve(song: song)` before playing.

**Error Handling**
- Use `Process<T>` for async operations - automatic error tracking via `errorNotifier`
- Throw `Cancelled()` exception when user cancels operations
- Check `breakIfCancelled()` periodically in long operations

**Type Aliases**
```dart
typedef Json = Map<String, dynamic>;  // Used everywhere for JSON
```

## Development Workflow

### Building & Running
```bash
flutter pub get                    # Install dependencies
dart run flutter_launcher_icons    # Update app icons
dart run flutter_native_splash:create  # Update splash screens
flutter run                        # Run app
flutter build apk --release        # Android release build
```

### Dependencies
- Audio: `flutter_soloud` (dev branch from GitHub), `audio_service`, `audio_session`
- UI: `dynamic_color` (forked for tone-based colors), `google_fonts`, `material_symbols_icons`
- State: `shared_preferences` (via PersistentValue), `go_router`
- Backend: `dio` for API calls, Firebase for analytics

### Linting & Formatting
- Strict analysis enabled (strict-casts, strict-inference, strict-raw-types)
- Formatter: `trailing_commas: preserve`, `page_width: 79`
- Run `flutter analyze` before commits

## UI Conventions

**Custom Widgets** (`lib/widgets/widgets.dart`)
- `ContinuousButton` - Hold for repeated actions (metronome BPM adjustment)
- `Shimmer` - Loading effect, gradient configured per theme
- `Directories` class - Static helpers for app/temp directories

**Navigation**
- Use `Navigation.router` (GoRouter) for all routing
- Branch switching: `Navigation.navigationShell.goBranch(index)`
- Dialog context: Use `Navigation.navigatorKey.currentContext!` when no local context available

**Theming**
- Theme mode persisted via `AppTheme.themeModeNotifier`
- Custom theme extensions: `PositionSliderStyle` for song position slider
- Always use `Theme.of(context).colorScheme` for colors

## Common Gotchas

1. **Audio initialization**: Always call `Songs.initialize()` before using any Songs features
2. **Persistent values**: Must call `PersistentValue.initialize()` in main() before creating any instances
3. **Demixing cache**: Songs store stems in `song.audioDirectory`, check `song.isDemixed` before assuming stems exist
4. **Firebase**: `firebase_options.dart` auto-generated, don't edit manually
5. **Platform specifics**: Ads only on Android/iOS, some features desktop-only
6. **Component lifecycle**: SongPlayerComponents are tied to player instance, dispose with player

## Testing

Single test file: `test/widget_test.dart` (basic smoke test). No extensive test coverage yet.

## Key Files Reference

- [lib/main.dart](lib/main.dart) - App entry, initialization order critical
- [lib/navigation.dart](lib/navigation.dart) - Router config, branch structure
- [lib/songs/player/songs.dart](lib/songs/player/songs.dart) - Songs service, history handling
- [lib/songs/player/song.dart](lib/songs/player/song.dart) - Song model, cache management
- [lib/utils/persistent_value.dart](lib/utils/persistent_value.dart) - Persistent state pattern
- [lib/utils/process.dart](lib/utils/process.dart) - Async task pattern with cancellation
- [pubspec.yaml](pubspec.yaml) - Dependencies, note forked packages
