# Sonara (Android Music Player)

An offline-first, private, local-first Android music player crafted with Flutter & Dart.

---

## Architecture Overview

Sonara follows a feature-first, 3-tier reactive pattern:
```
lib/
  app/        # Bootstrap, router (go_router), theme tokens, l10n
  core/       # Errors, logging, utils, platform bridges
  data/       # db/ (Drift SQLite), sources/, repositories/
  domain/     # Entities, services, use cases
  audio/      # audio_handler, playback_controller abstraction
  features/   # home, search, library, settings, now_playing
  shared/     # mini_player, track_tile, skeletons, sheets
```

### Key Invariants:
1. **Single Source of Truth:** Drift SQLite database with bundled `sqlite3_flutter_libs`, WAL mode, and FTS5 search.
2. **Audio Isolation:** The UI never calls audio plugins directly; all actions flow through `PlaybackController`.
3. **100% Offline & Private:** Zero network permissions (`android.permission.INTERNET` is strictly omitted).

---

## How to Test & Run

### 1. Run Automated Tests
```powershell
flutter test
```
All unit, widget, and golden path tests execute in ~3 seconds.

### 2. Verify Code Quality & Static Analysis
```powershell
flutter analyze
dart format --output=none --set-exit-if-changed .
```

### 3. Launch the App on Emulator or Physical Device
Ensure your Android emulator (or USB-connected device) is active:
```powershell
# List connected devices
flutter devices

# Run the app in debug mode
flutter run -d emulator-5554
```

### 4. Interactive In-App Testing
- **Permission Flow & Onboarding (Phase 1):** First launch presents the private & offline rationale screen. Dynamically requests `READ_MEDIA_AUDIO` on Android 13+ (API 33+) or `READ_EXTERNAL_STORAGE` on API <=32, with a settings deep-link fallback on permanent denial.
- **MediaStore Native Scanner (Phase 1):** Scans audio files via background platform channel with transactional batching into Drift SQLite, real-time progress indicators, and incremental `ContentObserver` updates.
- **Pure-Dart TagReader (Phase 1):** Reads ID3v1, ID3v2.2-2.4 (TIT2, TPE1, TALB, USLT, APIC, ReplayGain), FLAC Vorbis comments + picture blocks, MP4/M4A atoms, and OGG with automatic fallback heuristics.
- **Browse Tabs & Scrubbers (Phase 1):** Switch between **Songs**, **Albums**, **Artists**, **Genres**, and **Folders** tabs in Library; sticky A-Z scrubber.
- **Audio Service & MediaSession (Phase 2):** Full background playback with `FOREGROUND_SERVICE_MEDIA_PLAYBACK` on Android 14+. Lock screen and notification shade controls with artwork, scrub bar, and Bluetooth AVRCP support.
- **Audio Focus & Headset Gestures (Phase 2):** Transient ducking on notifications, auto-pause on headphone unplug (`becomingNoisy`), resume on focus return, single/double/triple headset click handling.
- **Scalable Queue & Sliding Window (Phase 2):** Logical queue supports 20,000+ tracks without memory leaks. Sliding window feed of 5 upcoming tracks into `just_audio`.
- **Shuffle & Repeat (Phase 2):** Seeded Fisher-Yates shuffle (pins current track, exhausts before repeat) and repeat modes (off, all, one).
- **Crash & Skip Resilience (Phase 2):** Missing/unplayable files skip smoothly with user snackbars without crash loops. Accurate decoder duration reconciliation in Drift DB.
- **Process Death Restoration (Phase 2):** Drift DB persistence of logical queue, seek position, active index, and repeat/shuffle states across process kills and cold restarts.
- **External Intent Handling (Phase 2):** Plays external audio files opened from file managers via Android `ACTION_VIEW audio/*` intent.
- **Now Playing Screen & Dynamic Motion (Phase 3):** Full expandable Now Playing sheet with adaptive artwork color gradient, animated artwork scale (1.0 playing, 0.88 paused), swipe-to-skip, swipe-down collapse, and predictive back support.
- **Reorderable Queue Sheet (Phase 3):** Modal queue with active track indicator, reorder drag handles (`onReorderItem`), swipe-to-remove dismissible tiles, and clear queue action.
- **Synchronized Lyrics (Phase 3):** High-precision LRC parser (`LrcParser`) supporting sidecar `.lrc` / `.LRC` files, embedded ID3 tags (`USLT`/`SYLT`), active line auto-scroll, tap-to-seek, and dynamic font resizing (`A-` / `A+`).
- **Sleep Timer (Phase 3):** Timer presets (15m, 30m, 45m, 60m), custom duration slider, "End of track" option, 20-second gentle linear volume ramp-down, and tap-to-extend (+15m).
- **Playback Speed Control (Phase 3):** Pitch-preserved speed selection from 0.5x to 2.0x.
- **Track Audio Specifications (Phase 3):** Technical inspection sheet displaying format, codec, bitrate, sample rate, bit depth, channels, file size, duration, storage path, and quality badges.
- **Track Context Menu & Row Gestures (Phase 3):** Long-press and 3-dot context sheets (Play Next, Add to Queue, Favorites, Details) and swipe-right "Play Next" row gesture with Undo snackbar.
- **Haptic Engine (Phase 3):** Tactile feedback on playback controls, scrubbing, long-press, and sheet actions with user toggle in Settings.
- **Playlists & Drag-and-Drop Reordering (Phase 4):** Create, rename, delete, duplicate playlists with custom track ordering (`ReorderableListView`). Quick-add from track context sheets and dedicated playlist detail view.
- **Liked Songs & Instant Favorites (Phase 4):** Reactive heart toggles across all screens with pinned Liked Songs card in Library and quick-action cards on Home.
- **M3U / M3U8 Import & Export (Phase 4):** `#EXTINF` parser with resilient 3-tier track matching (absolute path, filename/basename, title+artist) and UTF-8 export.
- **Smart Playlist Rule Engine (Phase 4):** Dynamic rule groups (AND/OR, text, numeric, date, boolean operators) with built-in presets (Recently Added, Most Played, Top Rated, Forgotten Favorites).
- **Listening Statistics & Skip Detection (Phase 4):** Standard 30s / 50% threshold play logging, skip counter, and play history in Drift SQLite.
- **Home Screen Dynamic Shelves (Phase 4):** "Good Morning/Afternoon/Evening" greeting, quick action cards, "Jump Back In", "On Repeat", and "Your Top Artists" horizontal shelves.
- **Instant FTS5 Search (Phase 4):** SQLite FTS5 prefix search (<50ms) across tracks, artists, albums, playlists with filter chips ("All", "Songs", "Albums", "Artists", "Playlists"), Top Result hero card, and recent searches history.
- **Hardware Equalizer & Presets (Phase 5):** 5-band hardware EQ (`AndroidEqualizer`), dynamic Catmull-Rom/cubic Bezier frequency curve, 9 presets (*Flat, Bass Boost, Treble Boost, Rock, Pop, Jazz, Electronic, Vocal/Acoustic, Classical*) plus Custom, bypass master switch.
- **Bass Boost & Loudness Enhancer (Phase 5):** Hardware-accelerated bass boosting (0-100%) and loudness enhancer (`AndroidLoudnessEnhancer`) with target gain up to +10 dB.
- **Crossfade & Smooth Volume Fades (Phase 5):** Configurable crossfade (0s to 12s, 0 = gapless) and 200ms volume ramp on pause/resume/skip eliminating DAC transient clicks.
- **ReplayGain & Volume Normalization (Phase 5):** Smart (shuffle vs sequential), Track, and Album normalization with -12 dB to +12 dB pre-amp and peak limiter anti-clipping clamp.
- **Platform Audio Engine Controls (Phase 5):** Hardware skip silence (`player.setSkipSilenceEnabled`), stereo channel balance slider (-1.0 Left to +1.0 Right), and mono downmix.
- **Long-Audio Position Memory (Phase 5):** Auto-saves and restores exact seek position and playback speed for tracks >= 20 minutes (podcasts, DJ sets, audiobooks).
- **Home Screen Widgets (Phase 6):** Native Android app widget (`SonaraWidgetProvider`) showing active track title, artist, play/pause status, and direct `MediaButtonReceiver` transport controls (Play/Pause, Next, Previous).
- **Dynamic App Shortcuts (Phase 6):** Launcher dynamic shortcuts for quick actions (*Shuffle all*, *Liked*, *Recently played*, and *Search*) routed via `sonara://` deep links.
- **Duplicate Audio Finder (Phase 6):** Detection engine grouping tracks by title, artist, and duration (±2s) with options to hide duplicates from library or delete with confirmation.
- **Library Backup & Restore (Phase 6):** Complete offline JSON backup and restore for playlists, favorites, listening stats, and user settings with 3-tier track relinking cascade (path, URI, metadata).
- **Storage Inspector & Cache Management (Phase 6):** Storage breakdown displaying database size, track counts, and artwork cache footprint, featuring one-tap thumbnail eviction and SQLite `VACUUM`.
- **Audio Synthesis Tool:** Run `dart tool/seed_music.dart` to synthesize real tagged test tracks (MP3, FLAC, M4A, OGG) with sidecar artwork and push them directly to Android devices via ADB.



