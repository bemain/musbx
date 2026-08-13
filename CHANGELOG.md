## [1.14.6] - 2026-08-13

### 🐛 Bug Fixes

- *(macos)* Remove incomplete NSAppTransportSecurity entry from Info.plist
- *(macos)* Grant microphone and file access, skip unsupported permission check

### 📚 Documentation

- Redesign the website
- Instruct GitHub pages that this is not a Jekyll site
- Improve layout on mobile
- Add AI usage policy

### ⚙️ Miscellaneous Tasks

- Automate release builds for macos
## [1.14.5] - 2026-08-05

### ⚙️ Miscellaneous Tasks

- Automate release builds for windows and linux
- Fix desktop build errors
- Fix windows build error
- Avoid pushing to main when dispatched from a feature branch
- Verify appimagetool checksum
- *(release)* V1.14.5+65 [skip ci]
## [1.14.4] - 2026-08-05

### 🐛 Bug Fixes

- Replace deprecated member

### 💼 Other

- Upgrade packages and build for iOS

### ⚙️ Miscellaneous Tasks

- Use git-cliff action to generate changelog
- *(release)* V1.14.4+64 [skip ci]
## [1.14.3] - 2026-08-04

### 🚀 Features

- Create script for generating custom icons
- *(songs)* Move hosted album art to `/assets/album_art`

### 🐛 Bug Fixes

- *(songs)* Switch package used to get content URIs
- Fix inconsistent icon sizes
- *(songs)* Enable demixing bytes audio
- Replace supabase anon key with publishable key

### 💼 Other

- Upgrade flutter
- Fix firebase build error
- Upgrade dependencies

### 🚜 Refactor

- Format files

### 📚 Documentation

- Add `/get` permalink that redirects to app store
- Host store badges on GitHub
- Fix invalid assets links
- Add `/get` to navigation bar
- Use snake case for all hosted assets

### ⚙️ Miscellaneous Tasks

- Sort dependencies
- *(release)* V1.14.3+63 [skip ci]
## [1.14.2] - 2026-04-09

### 🚀 Features

- *(songs)* Upgrade to `flutter_soloud` v4

### 💼 Other

- Upgrade `flutter_soloud`

### ⚙️ Miscellaneous Tasks

- *(release)* V1.14.2+62 [skip ci]
## [1.14.1] - 2026-03-16

### 🐛 Bug Fixes

- *(songs)* Update host address

### ⚙️ Miscellaneous Tasks

- *(release)* V1.14.1+61 [skip ci]
## [1.14.0] - 2026-03-13

### 🚀 Features

- *(songs)* Wrap demixing progress bar in a 9-sided cookie
- *(songs)* Wrap large search icon in four-sided cookie
- *(songs)* Use a uniform style for song tiles
- *(songs)* Replace rrect in `SongTile`s with 4-sided cookie
- *(songs)* Remove trailing icon in search list
- *(songs)* Use a six-sided cookie for the play button
- *(database)* Setup supabase
- *(database)* Create the `announcements` table
- *(announcements)* Create the `Announcements` class
- *(announcements)* Create the announcements page and app bar icon
- *(announcements)* Render `content` as markdown
- *(announcements)* Show latest announcement title as tooltip on startup

### 🐛 Bug Fixes

- *(songs)* Dispose `SearchController`
- *(songs)* Use a different color for the play button while loading
- *(database)* Reduce modularization of database tables
- *(announcements)* Minor fixes

### 💼 Other

- *(announcements)* Cleanup error message

### ⚙️ Miscellaneous Tasks

- *(release)* V1.13.13+59 [skip ci]
- Remove redundant clean step
- Fix changelog output variable name
- Push to current branch, not necessarily `main`
- Push to main
- *(release)* V1.14.0+60 [skip ci]
## [1.13.13] - 2026-03-10

### 🐛 Bug Fixes

- *(songs)* Specify that opening documents in place is supported

### 💼 Other

- Revert to older version of flutter_soloud
- Upgrade flutter_soloud

### ⚙️ Miscellaneous Tasks

- Specify xcode version directly
- *(release)* V1.13.12+57 [skip ci]
- Remove xcode-version file
- Run flutter clean
- Use a different action to generate changelog
- Install CMake
- Run flutter build directly on iOS
- Remove redundant cmake install
- Clean before build
- Cleanup workflow files
- *(release)* V1.13.13+58 [skip ci]
## [1.13.12] - 2026-03-08

### 🚀 Features

- *(songs)* Include error message in error dialog
- *(songs)* Indicate when a stem may not be accessed
- *(songs)* Replace `SegmentedButton` with `TabBar`

### 🐛 Bug Fixes

- *(songs)* Remove button used for debugging
- *(songs)* Make error message dialog scrollable
- *(songs)* Correct the padding around icon placeholder
- *(songs)* Clarify slider behaviour when access is restricted

### 💼 Other

- Upgrade dependencies
- Upgrade dependencies
- Upgrade pods

### ⚙️ Miscellaneous Tasks

- *(release)* V1.13.11+56 [skip ci]
- Fix incorrect java version
- Include commits in the changelog, not PRs
- Set xcode version
- *(release)* V1.13.12+57 [skip ci]
## [1.13.11] - 2026-03-03

### 🚀 Features

- *(songs)* Mark app as opening audio files

### 🐛 Bug Fixes

- *(songs)* Remove previous song history instance
- *(songs)* Remove debug logging
- *(songs)* Disable default deep linking
- *(songs)* Respect free limit on number of songs when opening files
- *(songs)* Avoid re-initialization

### 💼 Other

- Perform pod repo update

### ⚙️ Miscellaneous Tasks

- *(release)* V1.13.11+56 [skip ci]

### ◀️ Revert

- Undo change to iOS build config
## [1.13.10] - 2026-02-27

### 🚀 Features

- *(ads)* Remove ads

### 🐛 Bug Fixes

- *(ads)* Don't mention ads in upgrade dialog
- Suppress experimental warnings

### ⚙️ Miscellaneous Tasks

- Fix uploaded filepaths
- Bump build number on release
- *(release)* V1.13.10+55 [skip ci]
## [1.13.9] - 2026-02-04

### 🚀 Features

- *(demixer)* Download stem files as mp3 and convert them to wav using ffmpeg
- *(demixer)* Add progress to all applicable demixing steps
- *(music-player)* Implement `SpeedDial` for picking a song
- *(music-player)* Make SpeedDialChild more flexible
- *(music-player)* Implement children for SpeedDial
- *(music-player)* Move position card to the bottom of the screen
- *(music-player)* Use blur overlay instead of changing color
- *(music-player)* Match the style of Google Calendar's speed dial
- *(music-player)* Scroll app bar with content
- *(music-player)* Update help text
- Create new icons for Tuner and Metronome
- *(music-player)* Add shadow to the top of the position card
- *(theme)* Change default seed color
- *(logo)* Use new clef and wrench logo
- *(logo)* Customize the launch screen
- *(logo)* Add monochrome icon
- Use icon with notes in AboutDialog
- *(youtube)* Add icons to history items on search page
- *(youtube)* Persist search history to disk
- *(logo)* Specify splash screen background color for dark theme
- Create `HistoryHandler` class
- *(music-player)* Create welcome screen
- *(demixer)* Support new version of the API
- *(demixer)* Change API versioning system
- *(demixer)* Separate the YoutubeApi from the DemixerApi
- *(demixer)* Handle DemixerApi returning errors as JSON
- *(slowdowner)* Allow the user to enter values for speed and pitch using the keyboard
- *(youtube)* Increase the number of search queries saved to history
- *(metronome)* Rewrite to use `just_audio` for playback
- *(metronome)* Vibrate if the volume is muted
- *(metronome)* Setup notifications
- *(metronome)* Specify the time signature as a higher and a lower value
- *(metronome)* Implement subdivision
- *(metronome)* Remove `lower` value
- *(metronome)* Change the layout of the metronome to not use cards
- *(metronome)* Create `Notifications` class for handling notifications
- *(metronome)* Make the quick access notification not be a `MediaPlayer`
- *(metronome)* Move bpm buttons to the bottom of the screen
- Change the default text theme to Inter
- *(metronome)* Use cards to group similar widgets
- *(metronome)* Create volume indicator widget, showing if the volume is muted
- *(metronome)* Create notification indicator for showing if notifications are disabled
- *(metronome)* Remove the help text
- *(metronome)* Use add and remove icons for bpm buttons
- *(metronome)* Implement entering bpm using the keyboard
- Restore the previously open page when the app starts
- *(metronome)* Change only the metronome's audio when enabling vibration
- *(music-player)* Create host for the chords API
- Create Chord model for parsing chords
- *(music-player)* Display chords below the loop slider
- Create abstract `Process` class for length tasks
- Add `result` property to `Process` and make it listenable
- *(analyzer)* Perform waveform extraction
- *(music-player)* Restructure cached files per song instead of per component
- *(analyzer)* Cache identified chords
- Create enums for `PitchClass` and `ChordExtension`
- *(analyzer)* Create `ChordSymbol` widget
- Create widget for showing the waveform
- *(analyzer)* Implement seeking by dragging the waveform
- *(analyzer)* Implement zooming on the waveform widget
- *(analyzer)* Limit the `durationShown`
- *(analyzer)* Highlight the section of the waveform before the current `position`
- *(analyzer)* Implement loading and saving settings to json
- *(analyzer)* Highlight chords that have been played
- Create `PersistentValue` class for easily persisting values to disk
- Remove old cached files when upgrading to app version 26
- *(metronome)* Persist `bpm`, `higher` and `subdivisions` to disk
- *(flavors)* Restrict access to the music player on the 'free' flavor of the app
- *(ads)* Initialize `google_mobile_ads`
- *(ads)* Create bottom banner ad
- *(ads)* Show interstitial ad whenever a song is loaded
- *(flavor)* Increase the number of `freeSongsPerWeek`
- *(flavors)* Restrict access to the Demixer on the 'free' flavor
- *(purchases)* Set up in app purchases
- *(payments)* Implement purchasing the 'premium' product
- *(equalizer)* Decrease the padding around the sliders
- *(analyzer)* Increase the default `durationShown`
- *(music-player)* Make play button filled
- *(purchases)* Add `BILLING` permission
- *(youtube)* Round the corners of a video's thumbnail in the search results
- *(analyzer)* Use custom font for chord symbols
- *(purchases)* Add package 'in_app_purchase'
- *(payments)* Add a 'Get Premium' button to the app bar
- *(build)* Create VSCode launch configuration
- *(purchases)* Show migration dialog to users who have the paid version of the app
- *(puchases)* Show "Processing payment" dialog when payment is pending
- *(purchases)* Show dialog if buying premium fails
- Upgrade dependencies
- *(tuner)* Use `mic_stream` package to capture audio on iOS as well
- *(build)* Add 'release' launch configuration
- *(music-player)* Automatically load the previous song on launch
- *(music-player)* Increase number of song history entries saved
- Create `Key` model
- Create `KeySignature` model
- *(tuner)* Create new `Note` class
- *(tuner)* Implement changing the reference frequency of A4
- *(demixer)* Add stem `guitar`
- *(demixer)* Add stem `piano`
- *(demixer)* Replace text labels with icons for each stem
- *(music-player)* Remove all references to YouTube within the app
- *(demixer)* Long press the `Checkbox` to solo instrument
- *(demixer)* Show the current step index when loading
- *(music-player)* Load a demo song the first time the app launches
- *(drone)* Create `Drone` tool
- Make a clearer distinction between `Pitch` (former `Note`) and `PitchClass`
- *(drone)* Highlight pitches that are in the `root`'s key
- Implement equality operators for all model classes
- *(drone)* Make wheel rotatable
- *(drone)* Rename `DroneControls` to `DroneWheel`
- *(drone)* Display and add buttons for changing the root's octave
- *(drone)* Add help text
- *(drone)* Change navigation icon
- *(drone)* Change the default root
- *(drone)* Add rubber band effect when the wheel is at the min or max value
- *(drone)* Persist `root` and `intervals` to disk
- Merge the `Key` and `KeySignature` classes
- *(drone)* Increase the volume
- *(drone)* Align the wheel toward the bottom of the screen
- Remove freemium migration dialog
- Use the main version of package 'flutter_launcher_icons'
- *(tuner)* Prefer the most common accidental, not always sharp
- *(metronome)* Make metronome page card-less
- *(tuner)* Make tuner page card-less
- *(demixer)* Remove the checkbox
- *(music-player)* Change the order of cards
- *(metronome)* Use `Divider`s for extra separation between distinct parts of the UI
- Remove the title from most `AppBar`s
- *(metrome)* Use a `Card` around the play button, instead of `Divider`s
- *(music-player)* Completely redesign the ui
- *(music-player)* Add toolbar options to change the pitch and speed and modify the equalizer
- Don't automatically resize `NavigationPage` to avoid bottom insets
- *(metronome)* Make the entire card with the play button visually respond to taps
- Make sure the `Upgrade` button is removed from `MusicPlayer`'s `AppBar`
- *(music-player)* Redesign the layout of the library page
- *(music-player)* Add "Get premium"-button to the `LibraryPage`
- Use the new Material Symbols
- Copy `SegmentedTabControl` widget from package animated-segmented-tab-control
- *(music-player)* Create my own `SegmentedTabControl`
- *(music-player)* Seek to the new value when changing the looped section
- *(music-player)* Use the search query to filter search history suggestions
- *(analyzer)* Increase the resolution of the rendered waveform
- *(songs)* Implement removal of songs from the library
- *(songs)* Create a new `waveform` icon
- *(songs)* Clearly indicate which songs are available when access to the music player is restricted
- *(songs)* Replace the remove song button with a cascading menu
- *(songs)* Indicate when the pitch or speed has been changed
- *(navigation)* Use `go_router` package to handle navigation
- *(songs)* Open a separate search view when the `SearchBar` is tapped
- *(songs)* Enhance library search with 'search on Youtube' button
- *(songs)* Use outlined variant of forward/rewind buttons
- *(analyzer)* Show position marker over waveform widget
- *(analyzer)* Introduce `LoopStyle` theme extension
- *(theme)* Use `DynamicColorBuilder` to obtain dynamic color
- *(pages)* Create GitHub pages site
- *(pages)* Add config file
- *(songs)* Create my own stream to mix audio files
- *(songs)* Begin porting `MusicPlayer` to use the `flutter_soloud` package
- *(songs)* Rethink the `MusicPlayer` model
- *(songs)* Begin porting the `MusicPlayer` components
- *(songs)* Make the `SongPlayer` responsible for managing the `AudioSource`
- *(songs)* Rethink the purpose of `SongSource`
- *(songs)* Migrate the `SlowdownerSheet` to use the new `SongPlayer`
- *(songs)* Port the `Equalizer` component to the new `SongPlayer`
- *(songs)* Move the filter abstraction to the `Playable`
- *(songs)* Begin implementing loading demixed songs
- *(songs)* Begin porting the `DemixerCard` widget
- *(songs)* Remove some old `MusicPlayerComponent`s
- *(songs)* Create multiple implementations of the `SongPlayer` class
- *(songs)* Port the `Analyzer` component to the new `SongPlayer`
- *(songs)* Port the AudioHandler implementation to the new `SongPlayer`
- *(songs)* Use custom icons for the media notification
- *(songs)* Port the `Looping` component to the new `SongPlayer`
- *(songs)* Only add demixed variant of songs to library
- *(songs)* Show the demixing progress on songs that are not demixed
- *(songs)* Add icon to indicate that the demixing is complete
- *(songs)* Open options sheet on long press
- *(songs)* Indicate in the options menu when a song has not been demixed
- *(purchases)* Show 'restore purchase' button when buying premium
- *(songs)* Add option to clear a `song`'s cached files
- *(songs)* Add option to rename song
- *(songs)* Enable desktop support
- Create widgets for applying a shimmer effect
- *(songs)* Apply shimmer effect when loading a song
- *(songs)* Show dummy waveform while loading
- *(songs)* Apply shimmer effect to remaining widgets
- *(songs)* Show placeholders while searching for Youtube videos
- *(songs)* Search for songs on SoundCloud
- *(songs)* Show search results as suggestions when searching the library
- *(songs)* Use the new Musbx API
- *(songs)* Mark songs that only provide a preview
- *(metronome)* Use SoLoud for the Metronome playback
- *(drone)* Use `SoLoud` as the audio backend
- *(tuner)* Use `flutter_recorder` package to record audio
- *(tuner)* Show wave and FFT data
- *(tuner)* Combine data into one stream and buffer
- *(tuner)* Combine pitch and wave graphs
- *(analytics)* Install Firebase Analytics
- *(analytics)* Log when the current page changes
- *(settings)* Create settings page
- *(settings)* Use custom page transitions
- *(settings)* Add option to disable the Metronome notification
- *(settings)* Add settings from the drone
- *(settings)* Remove GitHub link and Tuner temperament setting
- *(settings)* Add settings for Songs
- *(settings)* Add theme setting
- *(settings)* Use a subpage for each tool
- *(settings)* Add waveform shape option
- *(settings)* Add option to not automatically demix songs
- *(demixer)* Show cancel button while demixing
- *(demixer)* Transition to a checkmark when loading complete
- *(songs)* Include preferences in the `Song` object
- *(demixer)* Implement demixing songs that are not loaded
- *(songs)* Remove the intermediate `Playable` class
- Move common widgets and utils to a separate package
- *(songs)* Cache audio files in temporary directory
- *(songs)* Change icons for forward and rewind buttons
- *(songs)* Move loop slider to above position slider
- *(songs)* Use new material `Slider`
- *(songs)* Make position slider reflect new material theme more
- *(songs)* Move loop slider close to position slider
- *(songs)* Move the pitch and speed sliders above the waveform
- *(songs)* Update style and behaviour of instrument sliders
- *(settings)* Group similar settings together
- *(settings)* Increase tile size
- *(tuner)* Don't display the fft graph

### 🐛 Bug Fixes

- Configure audio session to allow recording and playing simultaneously
- *(demixer)* Remove option to download wav files from server
- *(demixer)* Fix cached stems not being extracted
- *(demixer)* Don't cache extracted wav files
- *(music-player)* Let SpeedDialChild fill the width of the screen
- Minor adjustments to widgets
- *(music-player)* Remove old parameter from SpeedDial
- *(music-player)* Dybamically measure the height of position card
- *(demixer)* Change order of stems
- *(equalizer)* Decrease tap width of sliders
- *(equalizer)* Disable Equalizer on iOS
- *(logo)* Resize iOS logo
- *(youtube)* Fill search query when arrow button on history tile is pressed
- *(demixer)* Use the more correct variable name `songId` instead of `songName`
- *(music-player)* Increase empty space below position card
- *(music-player)* Add default album art
- *(music-player)* Use splash icon in notification
- *(music-player)* Strip unused icons from package `audio_service`
- *(music-player)* Fix inconsistent color of the position slider's thumb overlay
- *(api)* Remove debug host
- *(music-player)* Make bottom sheet an actual `bottomSheet`
- *(music-player)* Remove cached files when a song is removed from `songHistory`
- *(music-player)* Implement `operator==` for `Song`
- Check if build context is mounted before using it after async gaps
- *(demixer)* Make the `progress` a fraction between 0 and 1
- *(metronome)* Bpm tapper not updating playback
- *(metronome)* Make `count` non-nullable
- *(metronome)* Make `BpmTapper` only vibrate when the volume is muted
- *(metronome)* Implement removing beats
- *(metronome)* Use different vibrations for different `BeatSound´s
- *(metronome)* Update subdivision icons
- Use `AppLifecycleListener` to detect changes to the lifecycle
- *(music-player)* Replace the text on the welcome screen
- *(music-player)* Dynamically change the color of the arrow on the welcome screen
- *(metronome)* Let the Metronome handle how the notification should look
- *(metronome)* Use a weaker vibration for subdivisions
- *(metronome)* Update help text
- *(metronome)* Only request notification permission once
- *(metronome)* Make notification dismissable
- *(metronome)* Remove print statements
- *(metronome)* Create notification after permission has been granted using the `NotificationIndicator`
- *(demixer)* Remove host used during debugging
- Set `heroTag` on `SpeedDial`
- Await `loadSongLock` in a `try` statement.
- *(metronome)* Await `loadSongLock` in a `try` statement
- *(demixer)* Remove host used during debugging
- *(music-player)* Always download the audio to Youtube songs
- Throw instead of returning dummy data if a `Process` is cancelled early
- Start process even if the `future` is not awaited
- *(analyzer)* Transpose chords according the `Slowdowner`s pitch
- Override `toString()` methods for enums
- Set `heroTag` on `SpeedDial`
- Await `loadSongLock` in a `try` statement.
- *(analyzer)* Correct chord positioning
- *(analyzer)* Wrap `GestureDetector` around all Analyzer widgets
- *(music-player)* Update position immediately when seeking
- *(analyzer)* Allow scaling and seeking at the same time
- *(analyzer)* Remove position marker from `ChordsDisplay`
- *(analyzer)* Preserve the width of waveform steps
- *(youtube)* Allow setting `cacheFile` multiple times
- *(music-player)* Provide default preferences for components
- *(analyzer)* Make loading indicator circular
- *(analyzer)* Fix no-chords hiding all chords on the `ChordsDisplay`
- *(analyzer)* Always repaint waveform widget
- Fix typo
- *(music-player)* Clamp position also when no song is loaded
- *(analyzer)* Don't show loading indicator when no song is loaded
- Sort dependencies
- Fix typos
- Move history files to the app's temporary directory
- *(navigation)* Move initialization to main.dart
- *(metronome)* Fix inconsistent color of `VolumeIndicator`
- *(metronome)* Use singular form of "beats" in notification if `higher` equals 1
- *(metronome)* Use correct notification category
- *(ads)* Include AdMob App ID on the 'premium' flavor as well
- Restore the color of the logo in the about dialog
- *(ads)* Fail silently if an interstitial ad fails to load
- *(music-player)* Decrease the height of cards
- *(music-player)* Seek to the start when a new song is loaded
- Run on iOS
- *(ads)* Put bottom banner ad inside the `Scaffold`
- *(theme)* Add tonal colors missing from scheme generated by 'dynamic_color'
- Use material 3 defaults for custom sliders
- Catch errors during initialization
- *(demixer)* Properly detect if phone is on cellular
- *(music-player)* Catch errors when restoring the previous song
- *(tuner)* Use 'andika' text theme for showing note names
- *(tuner)* Handle 16 bit encoding from the mic stream
- *(tuner)* Stop listening to mic stream when `TunerPage` is disposed
- *(music-player)* Fix demixing files
- *(demixer)* Demixing progress overflowing 100%
- *(demixer)* Allow the loading text to be wider than previously
- *(music-player)* Correct the uri to the default album art
- *(demixer)* Make sure the audio is always updated when the demixer changes
- *(music-player)* Include how to solo instruments in the help text
- Return unmodifiable `List`s from getters
- *(drone)* Remove deprecated `frequencies` property
- *(drone)* Enable the play/pause button when the drone has been paused
- *(drone)* Transpose the root correctly when rotating the wheel
- *(drone)* Calculate the center of the wheel properly
- *(drone)* Implement locking
- *(drone)* Keep track of intervals instead of specific pitches
- *(drone)* Introduce a limit to the wheel
- *(drone)* Make sure the wheel is centered
- Prefer the term "pitch" over the more generic "note"
- *(drone)* Don't use temperament when changing the root
- *(tuner)* Display the name of pitches correctly
- *(tuner)* Pitch abbreviation not shown correctly
- *(music-player)* Adjust the order of tips in the help text to match the order of the cards
- *(analyzer)* Chord symbols using a grey color and disappearing
- Change the icon used for the "Upgrade" button
- *(music-player)* Increase text size on sheets
- *(music-player)* Remove unused widgets
- *(demixer)* Make `DemixerCard` scrollable
- Update the icons used in exception dialogs
- *(music-player)* Update the help text
- *(music-player)* Add `InfoButton` to the Library's app bar
- *(music-player)* Don't preload latest song
- *(music-player)* Stop audio playback when closing the `SongPage`
- *(music-player)* Use a different icon for the demo song
- *(music-player)* Allow unlimited history entries
- Use correct weight for symbols in an alert dialog
- Move all configuration regarding the theme to the `theme.dart` file
- *(songs)* Fix `songsPlayedThisWeek` not filtering out older songs correctly
- *(songs)* Make sure no song gets hidden behind the "Add to library" button
- *(songs)* Show access restricted dialog already when the "Add to library" button is pressed
- *(songs)* Change the title of the demixer card to be consistent with the segmented button
- *(songs)* Remove unused asset
- *(navigation)* Navigate to the correct route when tapping a notification
- *(navigation)* Persist the current route across app restarts
- *(songs)* Open the song page when a song is added to the library
- *(navigation)* Remove redundant error handling
- Remove use of deprecated `withOpacity()` method
- Build on iOS
- *(songs)* Use root navigator when opening the search view
- *(analyzer)* Use `LoopStyle` to theme the waveform
- *(metronome)* Use a darker color for the subdivisions button
- *(analyzer)* Adapt the marker color to the current Theme
- *(pages)* Move GitHub pages source to `/docs`
- *(pages)* Add missing includes
- *(pages)* Try removing overwritten includes
- *(pages)* Correct links
- *(songs)* Fix errors that have arisen during the porting
- *(songs)* Compensate for the fact that changing the speed alters the pitch
- *(songs)* Fix issues with types not being infered correctly
- *(songs)* Update stem volume immediately
- *(songs)* Check if filter is active before trying to activate it
- *(songs)* Use `SoLoud`'s global filters
- *(songs)* Indicate with the color of the button whether the equalizer is in use
- *(songs)* Prevent the app from freezing when seeking too frequently
- *(songs)* Dispose player when returning to the library page, and not when the next player is loaded
- *(songs)* Make sure cache file exists when loading a `FileSource`
- *(songs)* Give the demo song the correct type annotations
- *(songs)* Incorrect position values when playing at an altered speed
- *(songs)* Position overflowing the section being looped
- *(songs)* App freezing when seeking backwards
- *(songs)* Changing speed resets pitch
- *(songs)* Remove cache files when a song is removed from library
- *(payments)* Enable premium on platforms other than mobile
- *(songs)* Load preferences
- *(songs)* Include icon and artist in the options sheet
- *(songs)* Store song files as application documents
- *(songs)* Enable equalizer on all platforms
- *(songs)* Player being disposed when we switch tabs
- *(songs)* Use single filters instead of global
- *(navigation)* Only remember the top-level route on startup
- Apply lint recommendations
- *(purchases)* Restore purchases on startup
- *(purchases)* Reload the shell when premium is bought
- Apply Copilot's suggestions
- *(songs)* Prevent `SongPlayer` from being disposed twice simultaneously
- *(songs)* Don't show an ad when loading the demo song
- *(demixer)* Don't recreate the `DemixingProcess` whenever the Instruments tab is rebuilt
- *(songs)* Don't trigger a state change while building the songs route
- *(equalizer)* Disable reset button if all stems are in the default position
- *(songs)* Don't show Youtube search results as suggestions
- Remove padding between the `NavigationBar` and the banner ad
- Enable changing pitch on iOS
- *(songs)* Extract magic numbers as constants
- *(songs)* Show dialog if song could not be downloaded from SoundCloud
- *(songs)* Avoid reusing `FormData`
- *(songs)* Seeking `MultiPlayer` causes crash
- Replace deprecated members
- *(songs)* Fix typos
- *(songs)* Dispose sound handles correctly
- *(songs)* Search preview not updating rebuilding
- *(metronome)* Improve timing accuracy
- *(metronome)* Use flutter_soloud for the bpm tapper
- *(metronome)* Replace loading placeholder
- Always initialize `SoLoud` during startup
- *(metronome)* Mark `Notifications` class as `entry-point`
- Fix freeze caused by `LaunchHandler`
- Catch any errors encountered by `LaunchHandler`
- Remove just_audio dependencies
- *(tuner)* Only record while the tuner is open
- *(tuner)* Adjust graphs to the buffer size
- Reformat
- *(songs)* Generate SoundCloud `client_id` on launch
- *(songs)* Temporarily disable the equalizer
- *(analytics)* Format generated file
- *(settings)* Prefer sheets over dialogs
- *(settings)* Properly remove old settings
- Resolve TODOs
- *(demixer)* Improve progress tracking for upload
- *(demixer)* Adjust loading text and indicator
- *(songs)* Tidy up the new `AudioProvider` implementation
- *(songs)* Reenable the Equalizer
- *(songs)* Initialize `numBands`
- Prefer material `Symbols` over `Icons`
- *(songs)* Make sure history file exists
- *(songs)* Update 'client_id' extraction to reflect recent changes
- *(songs)* Update equalizer toolbar icon when gain changes
- *(songs)* Adjust loading app bar spacing
- *(songs)* Decrease padding between waveform and pitch/speed slider cards
- *(navigation)* Avoid error about `RestorableProperties` not being re-registered
- *(songs)* Fix typos in `PositionSliderStyle.copyWith()`
- Move material_plus dependency to gitlab
- *(settings)* Update accidental switcher text

### 💼 Other

- *(ios)* Build on iOS
- Version 1.4.3
- Upgrade flutter
- Version 1.4.4
- Run on iOS
- Version 1.4.5
- Upgrade flutter
- Remove deprecated imperative apply of Flutter's Gradle plugins
- Run on iOS
- Version 1.5.0
- Version 1.6.0
- Version 1.6.1
- Version 1.7.0
- Run on iOS
- Version 1.7.0 on iOS
- Upgrade flutter
- Remove deprecated MultiDex declaration
- Version 1.7.1
- Upgrade gradle and java
- Upgrade `awesome_notifications` package to avoid crash
- Version 1.8.0
- Version 1.9.0
- Cleanup build configuration
- Switch to flutter's beta channel
- Remove dead code
- Version 1.10.0
- Run on iOS
- Version 1.11.0
- Build on iOS
- Version 1.11.1
- Version 1.12.0
- Upgrade dependencies
- Use a more modern android file structure
- Version 1.12.1
- Update properties for windows builds
- Upgrade SoLoud

### 🚜 Refactor

- *(demixer)* Update description for extraction step
- *(music-player)* Create folder for components for `SpeedDial`
- *(music-player)* Remove old widgets
- *(music-player)* Remove redundant Row
- *(icon)* Remove old 'musbx' icon and organize new icon files
- Rename icon folder to logo
- *(logo)* Move splash images to separate folder
- Organize and remove unused assets
- *(youtube)* Rename `YoutubeApi` to `YoutubeDataApi`
- *(music-player)* Move MusbxApi to it's own folder
- *(metronome)* Extract `Subdivisions` widget
- *(metronome)* Extract `MetronomePermissionRationale` widget
- *(metronome)* Move the sounds we actually use to it's own folder
- Rename `Screen`s to `Page`s
- *(music-player)* Rename `position_card` folder to `bottom_bar`
- *(music-player)* Create `Analyzer` component
- Create `model` folder
- *(analyzer)* Extract `AnalyzerCard` widget
- *(youtube)* Remove redundant code
- Minor cleanup
- Minor cleanup
- *(music-player)* Extract widgets
- Restructure almost all files
- *(songs)* Rename `LoopStyle` to `PositionSliderStyle`
- *(songs)* Move new components to their own files
- *(songs)* Rename the new implementations of `SongPlayer` to `Single`- and `Multi`- as it is more general.
- *(songs)* Remove the old `MusicPlayer`
- *(songs)* Rename the loop component
- *(songs)* Remove old `Song` model
- Rename property to avoid ambiguous meaning
- Use flutter's default analysis options
- *(metronome)* Replace `flutter_volume_controller` package
- *(tuner)* Calculate pitch history from buffered data
- Add windows logo configuration
- Apply Copilot's suggestions
- *(settings)* Rename the file for subpages
- *(songs)* Rename `Source` to `AudioProvider`
- *(songs)* Rename `...Preferences` methods
- *(songs)* Remove old slowdowner sheet
- *(songs)* Remove unused `helpText` property
- Document parameter

### 📚 Documentation

- Introduce git naming conventions in README
- Add optional issue reference to branch naming convertion
- Add info about Commitizen tool to README
- *(README)* Specify that the 'Fixes ...' footer can be used
- *(demixer)* Update code documentation
- *(music-player)* Document SpeedDial
- *(music-player)* Improve logging when removing cached files
- Fix link to Google Play badge
- Update branch naming convention
- *(pages)* Move GitHub pages site to the 'BeMain.github.io' repo
- Clarify code documentation
- Update outdated info in README
- Update privacy policy
- Fix Google Play badge
- Add section about the search functionality
- Add more social links
- Update the theme
- Fix social icons
- Use default minima components
- Update features list in README

### 🎨 Styling

- Cleanup variable definitions
- Capitalize YouTube
- *(metronome)* Change the color of beat indicators
- Default to using the standard variant of icons
- *(analyzer)* Match the colors used by `Slider`
- *(metronome)* Change color of `Higher` buttons
- Enforce strict raw types

### ⚙️ Miscellaneous Tasks

- Generate icons on iOS
- *(songs)* Update SoLoud
- Add analyze workflow
- Load secrets in the workflow
- Make sure the action finds the `material_plus` dependency
- Add Copilot instructions
- Create release action
- Fix typo
- Use latest action versions
- Build version 1.13.0
- Fix incorrect signing certificate reference
- Build version 1.13.1
- Automatically update version number on release
- Upload generated binaries to release
- Fix commit step not pointing to a branch
- Build version 1.13.2
- Include version bump commit in the release
- Build version 1.13.2
- Remove duplicate commit call
- Cleanup release action
- *(release)* Bump version to v1.13.4 () [skip ci]
- Fetch dependencies correctly
- *(release)* V.13.5 [skip ci]
- Upgrade action versions
- *(release)* V1.13.6 [skip ci]
- Rename release file
- Verify signing certificate
- *(release)* V1.13.7 [skip ci]
- Use conventional changelog action to bump version
- Add fastlane iOS configuration
- Add fastlane android configuration
- Create beta lanes and deploy workflow
- Bump version to 1.13.7+1
- Fix some issues with beta lane
- Bump version to 1.13.7+2 [skip ci]
- Fix build number incrementation
- Fix invalid syntax
- Bump version to 1.13.7+46+47 [skip ci]
- Fix version parsing
- Bump version to 1.13.7+48 [skip ci]
- Inject service account json correctly
- Bump version to 1.13.7+49 [skip ci]
- Improve comments
- Fix upload keystore location
- Bump version to 1.13.7+50 [skip ci]
- Set match authorization
- Build version 1.13.7+51 [skip ci]
- Build version 1.13.7+52 [skip ci]
- Fix fastlane iOS building
- Build version 1.13.7+53 [skip ci]
- Allow selecting which platforms to build
- Make bumping build number optional
- Don't fail if nothing to commit
- Setup CocoaPods correcly
- Specify provisioning profile
- Change step names
- Fix provisioning profile reference
- Unlock iOS keychain
- Provide fastlane password
- Cleanup fastfile
- Fix AppStore 2FA
- Base64-encode AppStore API key
- Build version 1.13.7+54 [skip ci]
- Try removing Fastlane password
- Fix environment variable mapping
- Explicitly pass api_key
- Commit changelog
- Fix git push
- *(release)* V1.13.8+54 [skip ci]
- Include generated commit in release
- *(release)* V1.13.9+54 [skip ci]

### ◀️ Revert

- Switch to flutter's stable channel because of build errors
- Downgrade dependencies
