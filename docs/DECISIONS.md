# Architecture and Design Decisions (DECISIONS.md)

This log records non-obvious technical choices, architecture invariants, and dependency evaluations for Sonara.

---

## 1. Core Architectural Decisions

### ADR-001: Strict Offline Privacy Invariant
- **Decision:** The application operates strictly offline with zero network connectivity. The production Android manifest excludes the `android.permission.INTERNET` permission.
- **Rationale:** Absolute privacy, battery efficiency, and compliance with the PRD core principle. All assets (fonts, icons, themes) must be bundled locally. No crash reporting or analytics SDKs will be integrated.

### ADR-002: Three-Tier Reactive Architecture
- **Decision:** Strict separation into `presentation/`, `domain/`, and `data/` layers using Riverpod.
- **Rules:**
  1. The UI layer never communicates with the audio playback engine or platform services directly; it calls the `PlaybackController` interface.
  2. The local database (Drift on SQLite) is the single source of truth; all UI collections observe reactive streams.
  3. All repositories are defined behind abstract domain interfaces.

### ADR-003: Database Engine and Migration Strategy
- **Decision:** Use Drift with `sqlite3_flutter_libs` compiled with WAL (Write-Ahead Logging) and FTS5 enabled.
- **Rationale:** Drift provides compile-time query safety, native streaming reactivity, and schema migration testing tools. FTS5 provides sub-100ms instant search across tens of thousands of tracks. WAL ensures heavy background scanning transactions do not lock UI read queries.

### ADR-004: Audio Engine and Foreground Service Lifecycle
- **Decision:** Utilize `audio_service` + `just_audio` + `audio_session`.
- **Rationale:** `audio_service` interfaces directly with Android MediaSession and supports the Android 14+ `FOREGROUND_SERVICE_MEDIA_PLAYBACK` requirements, lock screen, and system notification controls. `just_audio` provides gapless decoding, pitch-preserved speed adjustment, and fine-grained buffering.
- **Guardrail:** The logical queue lives in domain memory/DB; `just_audio` receives a sliding window of tracks to keep memory usage minimal on 20,000+ track queues.

### ADR-005: MediaStore Access & Tag Extraction
- **Decision:** Query Android MediaStore via ContentResolvers for base items and artwork content URIs. Deep tagging (ReplayGain, multi-artist tags, embedded lyrics) executes in a dedicated background worker isolate to prevent UI frame drops.

### ADR-006: Stable Track Identity (`trackKey`)
- **Decision:** Every track calculates a stable sha256 hash `trackKey` from normalized `(title + artist + album + durationMs + sizeBytes)`.
- **Rationale:** Guarantees playlists, favorites, play history, and user edits survive file renames, folder moves, and MediaStore re-indexing.

---

## 2. Dependency Evaluation and Pinning Matrix

*All dependencies are audited for: active maintenance, Flutter 3 compatibility, Android 14+ targetSdk support, offline operation, and clean license.*

| Package | Version | Maintained? | Purpose / Rationale |
| :--- | :--- | :--- | :--- |
| `flutter_riverpod` | `^2.6.1` | Yes | Modern declarative state management, reactivity, and dependency injection. |
| `go_router` | `^14.8.1` | Yes | Official declarative routing supporting nested `StatefulShellRoute` for tab bars. |
| `drift` | `^2.25.0` | Yes | Type-safe reactive persistence on SQLite. |
| `sqlite3_flutter_libs`| `^0.5.28` | Yes | Bundles modern SQLite binaries supporting FTS5 and WAL across all Android ABIs. |
| `path_provider` | `^2.1.5` | Yes | Resolves application documents and cache directories. |
| `path` | `^1.9.1` | Yes | Robust file and directory path manipulations. |
| `audio_service` | `^0.18.18` | Yes | Android MediaSession, notification controls, and background playback service. |
| `just_audio` | `^0.9.46` | Yes | High-performance audio playback engine supporting gapless, buffering, speed. |
| `audio_session` | `^0.1.25` | Yes | Audio focus management, headphone unplug handling, interruption policies. |
| `material_color_utilities` | `^0.13.0` | Yes | Off-thread dynamic color extraction from artwork (Material You palette). Pinned to Flutter SDK requirement. |
| `permission_handler` | `^11.3.1` | Yes | Standard permission requests across Android 12- (`READ_EXTERNAL_STORAGE`) and 13+ (`READ_MEDIA_AUDIO`). |
| `intl` | `^0.20.2` | Yes | Internationalization, plural handling, and date/number formatting. |
| `crypto` | `^3.0.6` | Yes | SHA-256 calculation for stable `trackKey`. |
| `device_info_plus` | `^11.3.3` | Yes | Determines runtime Android SDK level for granular permission branching. |
| `flutter_lints` | `^5.0.0` | Yes | Baseline recommended lints, combined with custom strict analysis options. |
| `drift_dev` (dev) | `^2.25.0` | Yes | Code generator for Drift schema, queries, and type converters. |
| `build_runner` (dev) | `^2.4.15` | Yes | Dart build system runner. |

---

## 3. Platform & SDK Specifications

- **Target OS:** Android only (iOS deferred to Phase 8 / upon request)
- **Minimum Android SDK:** API 26 (Android 8.0 Oreo)
- **Compile & Target SDK:** API 34+
- **NDK / ABI Targets:** `arm64-v8a`, `armeabi-v7a`, `x86_64`

---

## 4. Phase 1 Architecture Decisions

### ADR 1.1: Native MediaStore & Pure-Dart TagReader Hybrid Pipeline
- **Decision:** MediaStore query is executed natively via lightweight MethodChannel (`com.example.sonara/mediastore`), extracting Content URIs, IDs, and coarse file metadata without heavy dependencies. Detailed tags (multi-artist, genres, release year, ReplayGain, embedded APIC artwork) are parsed via a robust, pure-Dart `TagReader` in background isolates.
- **Rationale:** Minimizes native third-party dependencies, keeps tag extraction reproducible and fast in pure Dart, avoids memory leaks on large media libraries, and allows graceful recovery from corrupt headers.

### ADR 1.2: Gradle Cross-Drive Kotlin Incremental Compilation
- **Decision:** Added `kotlin.incremental=false` to `android/gradle.properties`.
- **Rationale:** On Windows multi-drive setups (e.g. project on `E:\`, pub cache on `C:\`), the Kotlin incremental compilation lookup cache throws `IllegalArgumentException: this and base files have different roots` when computing relative paths. Disabling incremental compilation ensures consistent and reliable builds.

### ADR 1.3: ContentObserver & Incremental Rescan
- **Decision:** Native `ContentObserver` on `MediaStore.Audio.Media.EXTERNAL_CONTENT_URI` streams change notifications over EventChannel `com.example.sonara/mediastore_observer`. The `LibraryScanner` debounces notifications (3s) and queries MediaStore filtering by `DATE_MODIFIED > last_scan_timestamp`. Manual rescan actions execute a full scan (`isFullScan = true`) with deletion reconciliation.

### ADR 1.4: Deterministic Palette & Artwork Fallback
- **Decision:** Audio files without embedded or sidecar artwork display a deterministic Material 3 tonal gradient generated from SHA-256 hash seeds of title/artist metadata. Cached thumbnails are stored in app cache directory with fixed downscaled dimensions (256x256) to prevent OutOfMemory issues.

---

## 5. Phase 2 Architecture Decisions

### ADR 2.1: Logical Queue vs. Sliding-Window Player Engine
- **Decision:** The entire logical queue (supporting 20,000+ tracks) resides in memory within `QueueManager` and is backed by Drift SQLite. The underlying `just_audio` player engine only ever receives a bounded sliding window of upcoming tracks (window size 5).
- **Rationale:** Instantiating 20,000 `AudioSource` instances in `just_audio` causes excessive memory consumption, slow seek operations, and OutOfMemory crashes on Android. The sliding window buffers upcoming tracks for seamless transitions while keeping memory overhead negligible.

### ADR 2.2: QueueRepeatMode Naming Convention
- **Decision:** Named the domain repeat mode enum `QueueRepeatMode` (`off`, `all`, `one`) instead of `RepeatMode`.
- **Rationale:** Flutter 3.44+ introduced an internal `RepeatMode` enum in `package:flutter/widgets.dart`. Explicitly prefixing with `QueueRepeatMode` prevents naming collisions and ambiguous import errors across widgets and domain controllers.

### ADR 2.3: Seeded Fisher-Yates Shuffle with Current Track Pinning
- **Decision:** Shuffling generates a reproducible permutation using a 64-bit integer seed while pinning the currently active track to index 0. The shuffle sequence must be fully exhausted before repeating.
- **Rationale:** Prevents immediate re-playing of the current song upon activating shuffle, ensures all songs in the playlist are heard once without repeats, and allows persisting the exact shuffle state across app restarts via the seed and index pointer.

### ADR 2.4: Three-Trigger Process Death Persistence
- **Decision:** Playback state (queue track keys, active index, seek position, shuffle seed/state, repeat mode) is saved to the Drift `QueueStateTable` on: (1) pause, (2) periodically every 5 seconds during active playback, and (3) on Android lifecycle detach/pause.
- **Rationale:** Guarantees cold-start state recovery if the app is killed by Android low-memory killer (LMK) or user swipe-dismiss without causing excessive SQLite disk writes.

### ADR 2.5: Real Decoder Duration Reconciliation
- **Decision:** MediaStore or tag-extracted track durations are reconciled against the actual decoder duration reported by `just_audio` when playback starts, and asynchronously updated in Drift DB.
- **Rationale:** Variable Bitrate (VBR) MP3s and certain containers frequently report inaccurate durations in headers. Dynamic reconciliation ensures seekbars, scrubbers, and remaining-time timers are sample-accurate.

### ADR 3.1: Re-entrant Emission Protection in QueueManager
- **Decision:** State emissions in `QueueManager` are protected by an `_isEmitting` boolean flag and a `_pendingEmits` counter. If a listener triggers an action that requests another emission while a previous event is still broadcasting, the new emission is queued and processed iteratively.
- **Rationale:** Prevents `Bad state: Cannot fire new event. Controller is already firing an event` exceptions caused by synchronous event loops when UI sheets or error handlers respond immediately to queue mutations.

### ADR 3.2: Non-blocking Startup Playback Restoration
- **Decision:** `audioHandler.restoreSavedState()` is invoked with `unawaited(...)` during bootstrap rather than blocking `main()` before `runApp()`.
- **Rationale:** Guarantees that the Flutter UI mounts and renders the first frame immediately (<1s) even if persistent audio sources are inaccessible or slow to initialize.

### ADR 3.3: Synced Lyrics Discovery Precedence and Fallbacks
- **Decision:** Synced lyrics are queried in order: (1) memory cache, (2) sidecar `.lrc` and `.LRC` files matching track filename in the same directory, (3) embedded ID3 `USLT` / `SYLT` tags. Plain-text fallback displays lyrics when timestamps are absent.
- **Rationale:** Respects audiophile local library conventions where synchronized `.lrc` files often accompany lossless audio, while gracefully falling back to embedded metadata.

### ADR 3.4: Linear Volume Ramp-Down for Sleep Timer
- **Decision:** Sleep timer initiates a linear volume ramp-down from 1.0 to 0.0 over the final 20 seconds before pausing playback, with instant volume restoration if extended or cancelled.
- **Rationale:** Avoids abrupt audio cutoffs that wake listeners while falling asleep, providing a smooth transition.

---

## 7. Phase 4 Architecture Decisions

### ADR 4.1: Top-Level Riverpod Provider Families for Stream Queries
- **Decision:** All reactive database streams (e.g. `playlistStreamProvider(id)`, `playlistTracksStreamProvider(id)`) must be declared as top-level `StreamProvider.family` definitions rather than instantiated dynamically inside `Widget.build()`.
- **Rationale:** Creating providers inside `build()` instantiates new provider identities on every frame, resulting in subscriber churn, infinite rebuild loops, and test framework timeouts during `pumpAndSettle()`.

### ADR 4.2: Resilient M3U/M3U8 Parser with Multi-Tier Track Matching
- **Decision:** The `M3uService` supports `#EXTM3U`, `#EXTINF`, and raw URI playlist lines. Imported track entries are resolved against the local library using a 3-tier cascade: (1) exact path match, (2) filename / basename match, (3) normalized title and artist comparison.
- **Rationale:** M3U files exported from desktop players (e.g. Foobar2000, iTunes) or other devices contain relative or foreign absolute file paths. Multi-tier matching guarantees high track recovery without requiring manual path editing by the user.

### ADR 4.3: Local FTS5 Search with Result Categorization & Recent History
- **Decision:** Search queries utilize SQLite FTS5 prefix match (`term*`) over `tracks_fts` table, returning categorized results (Top Result hero card, Songs, Albums, Artists, Playlists). Recent search queries are persisted in `AppSettings` (up to 10 queries, FIFO).
- **Rationale:** Provides sub-50ms instant search across 20,000+ tracks completely offline with zero network lookups, while giving users intuitive search filtering and immediate recent query chips.

### ADR 4.4: Threshold-Based Listening Statistics & Skip Detection
- **Decision:** Play count is credited to a track only after either: (1) 30 seconds of playback, or (2) 50% of track duration (whichever is shorter). A skip is recorded if playback switches or finishes before this threshold is reached.
- **Rationale:** Follows standard audio telemetry conventions (e.g. Last.fm / Spotify), ensuring that brief accidental taps do not skew "On Repeat", "Your Top Artists", or smart playlist recommendations.

---

## 8. Phase 5 Architecture Decisions

### ADR 5.1: Hybrid AudioPipeline with Test Environment Fallback
- **Decision:** Built `AudioPipeline` with Android hardware effects (`AndroidEqualizer` and `AndroidLoudnessEnhancer`) guarded behind `!kIsWeb && Platform.isAndroid`. All hardware effect invocations are wrapped in defensive `try/catch` handlers that gracefully ignore platform exceptions in non-hardware environments (such as unit test fake audio platform drivers).
- **Rationale:** Allows full hardware audio effect features on physical devices and emulators without breaking headless test harnesses or throw UnimplementedError in mock environments.

### ADR 5.2: ReplayGain Volume Multiplier with Anti-Clipping Peak Limiter
- **Decision:** ReplayGain volume multiplier uses standard EBU R128 logarithmic formula: `multiplier = 10 ^ ((gainDb + preAmpDb) / 20)`. When `preventClipping` is enabled (default), `multiplier` is strictly clamped to `1.0` maximum; when disabled, headroom up to `2.0` (+6 dB) is permitted.
- **Rationale:** Prevents harsh digital clipping artifacts when applying positive pre-amp boosts or playing tracks with high mastering gains through 16/24-bit DACs.

### ADR 5.3: 200ms Step Volume Ramps on State Transitions
- **Decision:** Implemented `_fadeVolume` with 4 discrete interpolation steps over 200ms during manual `play()`, `pause()`, and track skipping.
- **Rationale:** Completely eliminates audible DC-offset "pops" and DAC transient clicks during playback transitions while keeping transport controls perceptually instantaneous.

### ADR 5.4: Long-Audio Position Memory Boundary (>= 20 Minutes)
- **Decision:** Position and speed memory (`LongAudioService`) triggers strictly for tracks with duration >= 20 minutes (1,200,000 ms), auto-saving when position exceeds 10s and restoring seamlessly on reload.
- **Rationale:** Distinguishes podcasts, DJ mixes, live sets, and audiobooks from standard songs (which should always start from 0:00). Prevents standard library tracks from perpetually opening at random mid-song timestamps.

---

## 9. Phase 6 Architecture Decisions

### ADR 6.1: Native Android AppWidget with Direct MediaButtonReceiver IPC
- **Decision:** The Home Screen widget (`SonaraWidgetProvider`) communicates transport actions (Play/Pause, Next, Previous) directly by dispatching key events to `com.ryanheise.audioservice.MediaButtonReceiver`. Widget metadata (track title, artist, playback state) is pushed from Flutter through a lightweight platform channel `com.example.sonara/mediastore` (`updateWidget`) and cached in `SharedPreferences`.
- **Rationale:** Eliminates redundant IPC relays and Flutter engine wakes for basic transport actions while ensuring immediate UI synchronization across process lifecycles.

### ADR 6.2: Static XML App Shortcuts with Deep Link Routing Scheme
- **Decision:** App launcher shortcuts (*Shuffle all*, *Liked*, *Recently played*, *Search*) are declared via Android standard `shortcuts.xml` with `sonara://` URI schemes handled by `AudioIntentService` and routed seamlessly through GoRouter.
- **Rationale:** Supported natively across all Android versions (API 25+) without requiring third-party plugins, operating completely offline with zero overhead.

### ADR 6.3: Two-Tier Duplicate Track Detection (Metadata Clusters & Hash / Size)
- **Decision:** `DuplicateFinderService` identifies duplicate audio tracks using a two-tier strategy: (1) metadata fuzzy matching on normalized title, artist, and duration within a ±2 second tolerance, and (2) secondary disambiguation via file size and path. Actions allow hiding tracks in Drift SQLite (`isHidden = true`) or permanent removal with confirmation dialogs.
- **Rationale:** Provides accurate duplicate grouping for varying file formats (e.g. FLAC vs MP3 version of the same song) while preserving user safety and avoiding accidental file loss.

### ADR 6.4: Standalone Self-Contained Backup & Restore Schema with Multi-Tier Relinking
- **Decision:** `BackupService` serializes all user-created data (playlists, track ordering, liked songs, play counts, skip stats, history, and app settings) into a single versioned JSON file (`v1`). Upon restore on a new install or altered filesystem, tracks are relinked using a fallback cascade: (1) exact file path, (2) content URI, and (3) normalized title + artist metadata matching.
- **Rationale:** Ensures complete user personalization survival even if SD card mount paths change, device models change, or library folders are relocated.

### ADR 6.5: Offline Cache Inspector with Granular Eviction & SQLite VACUUM
- **Decision:** `StorageInspectorService` calculates disk usage across the app database, artwork thumbnail cache, and temporary isolate workspaces. It provides user-triggered artwork cache eviction and SQLite database compaction via `VACUUM`.
- **Rationale:** Empowers users to inspect local storage footprints and reclaim space safely without compromising library metadata or playlist definitions.
---

## 10. Phase 7 Architecture Decisions

### ADR 7.1: Zero-Network Invariant Enforcement via Gradle Merged Manifest Verification
- **Decision:** Implemented a mandatory custom Gradle task `verifyNoInternetPermission` attached to `assembleRelease`. The task inspects the merged `AndroidManifest.xml` post-manifest-merging and aborts compilation with a fatal `GradleException` if `android.permission.INTERNET` is present.
- **Rationale:** Guarantees that neither Sonara code nor any third-party transitive dependency can sneak network permissions into the production release binary.

### ADR 7.2: Pure Offline Local Rotating Diagnostic Logger
- **Decision:** Created `LocalLogger` utilizing a single buffered `IOSink` with atomic message queuing, automatic size-based rotation (1MB max per log file, 2 file generations max), and a purge API. Hooked into `FlutterError.onError` and `PlatformDispatcher.instance.onError` in `main.dart`.
- **Rationale:** Diagnostic reports and crash traces remain 100% private and on-device without relying on Firebase Crashlytics or any network socket.

### ADR 7.3: R8 Full Optimization and ProGuard Retention Rules
- **Decision:** Enabled `isMinifyEnabled = true` and `isShrinkResources = true` in Android release build configuration. Added rules in `proguard-rules.pro` keeping `audio_service`, `just_audio`, SQLite C libraries, and Sonara app receivers while suppressing unused Play Core split-install warnings via `-dontwarn com.google.android.play.core.**`.
- **Rationale:** Eliminates dead code, optimizes bytecode, and keeps per-ABI APK sizes between 20MB and 24MB (<30MB PRD target).

### ADR 7.4: Edge-to-Edge System Navigation and Status Bar Configuration
- **Decision:** Enabled Android 10+ / 14+ edge-to-edge drawing via `window.setDecorFitsSystemWindows(false)` in `MainActivity.kt` and `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` with transparent status and navigation overlays.
- **Rationale:** Eliminates outdated solid black system letterboxing and ensures modern immersive playback surfaces.

### ADR 7.5: Minimum 48dp Touch Boundaries and 200% Text Scaling Resiliency
- **Decision:** Bound all interactive buttons across `MiniPlayer` and `TrackTile` to `BoxConstraints(minHeight: 64)` and guaranteed 48×48dp touch targets with semantic accessibility labels.
- **Rationale:** Ensures compliance with WCAG 2.1 AA standards and eliminates `RenderFlex` layout overflow when users activate Android high-contrast and 200% large font scaling.

---

## 11. Phase 8 Architecture Decisions

### ADR 8.1: Per-Output-Device Audio Profiles with Reactive Route Detection
- **Decision:** Implemented `DeviceProfileService` leveraging `audio_session.devicesChangedEventStream` to dynamically classify output routes (`speaker`, `bluetooth`, `wired`, `usb`) and automatically swap active EQ presets, crossfade duration, and loudness booster levels without requiring manual user intervention. Profiles are stored in the database's `appSettings` JSON kv-store.
- **Rationale:** Audiophiles and general users require different equalization and audio enhancements depending on listening hardware (e.g., Bass Boost for Bluetooth headphones, Flat EQ for wired studio IEMs, Loudness Enhancement for phone speakers or car Bluetooth).

### ADR 8.2: 60 FPS Audio Visualizer Engine with Zero-CPU Idle Decay & Waveform Scrubber
- **Decision:** Created `AudioVisualizer` with 3 rendering styles:
  1. `VisualizerStyle.spectrum`: 16 multi-band bars with responsive physics and floating peak-hold caps.
  2. `VisualizerStyle.vuMeter`: Dual-channel (L/R) analog needle meters with decibel markings (-20dB to +3dB).
  3. `VisualizerStyle.fluidWave`: Multi-harmonic bezier particle wave simulation.
  The visualizer monitors playback state and immediately halts the internal 60 FPS animation ticker when playback is paused or completed, decaying smoothly to zero and consuming 0% idle CPU and battery. In addition, `WaveformScrubber` replaces the traditional flat seek slider with an interactive amplitude-bar custom painter with smooth scrubbing and haptic feedback.
- **Rationale:** Delivers a tactile, high-end Hi-Fi aesthetic while strictly respecting battery life invariants and avoiding unnecessary draw cycles when idle.

### ADR 8.3: Independent Pitch Transposition via Semitone Multiplier ($2^{S/12}$)
- **Decision:** Built `PitchCalculator` and integrated independent pitch control into `PlaybackController` and `SonaraAudioHandler` using the mathematical frequency multiplier formula $\text{multiplier} = 2^{S/12}$, allowing users to shift key across $\pm 12$ semitones (full octave up/down) independently of playback tempo ($0.5\times$ to $2.0\times$).
- **Rationale:** Musician, vocal practice, and pitch training use cases require shifting the key of a song without altering the playback speed, and vice versa.

---

## 12. Phase 9 Architecture Decisions

### ADR 9.1: Scoped Storage In-Place Tag & Artwork Writing via `MediaStore.createWriteRequest`
- **Decision:** Built `TagWriter` supporting pure Dart in-place ID3v2.3 (MP3) and Vorbis Comment / FLAC PICTURE metadata writing with atomic file replacement. Paired with `ScopedStorageService` utilizing native Android 11+ `MediaStore.createWriteRequest` platform channel to present the official Android system permission dialog when modifying external files.
- **Rationale:** Modern Android Scoped Storage forbids direct arbitrary write access to user media files without OS approval. Utilizing `MediaStore.createWriteRequest` adheres cleanly to Android 11–15 security guidelines without requesting deprecated broad storage permissions or root access.

### ADR 9.2: Frame-Accurate CUE Sheet Virtual Splitting via `ClippingAudioSource`
- **Decision:** Created `CueParser` providing 75fps CD-DA frame-accurate parsing (`MM:SS:FF`) for `.cue` sidecar files. Virtual tracks are persisted into Drift SQLite with `cueStartMs` and `cueEndMs` columns and track key hashes. Playback is handled seamlessly through `just_audio`'s `ClippingAudioSource` without requiring destructive audio re-encoding or file splitting.
- **Rationale:** Audiophiles often maintain single-file monolithic album rips (`.flac` / `.ape` + `.cue`). Non-destructive virtual splitting preserves pristine lossless bitstreams while enabling full track-by-track indexing, shuffling, and searchability in Sonara.

### ADR 9.3: Real-Time Tap-to-Stamp Synchronized LRC Lyrics Studio
- **Decision:** Implemented `LyricsEditorSheet` and `LrcBuilder` enabling interactive lyrics synchronization. Users can play or pause audio at 0.75x slow-mo, navigate lines, and tap the tactile `STAMP` button to mark millisecond timestamps on the fly, with fine-grained $\pm 100\text{ms}$ adjustment buttons and sidecar `.lrc` file export.
- **Rationale:** Allows offline music listeners to produce and curate synchronized lyrics for songs lacking timestamped metadata directly on device without needing external desktop utilities or internet access.

---

## 13. Phase 10 Architecture Decisions

### ADR 10.1: 100% Offline "Wrapped" Recap with Local Canvas Card Export
- **Decision:** Built `WrappedService` and `WrappedScreen` to compute comprehensive listening recaps (Top Tracks, Top Artists, Genre Breakdown, Peak Listening Hour, Listener Persona, and Skip Rate) exclusively from local Drift SQLite playback statistics. Shareable graphic story cards are rendered natively using Flutter widgets and exported directly to PNG via `RenderRepaintBoundary.toImage()` and Android `ACTION_SEND` without sending telemetry or data packets over the network.
- **Rationale:** Brings the viral, engaging "Yearly / Monthly Wrapped" experience to offline, privacy-conscious local music collections with guaranteed zero external cloud dependencies.

### ADR 10.2: Multi-Factor Acoustic & Metadata Track Radio Clustering
- **Decision:** Built `TrackRadioService` which dynamically constructs a smart queue from a seed track using multi-factor scoring: Genre matching (40%), Era/Decade proximity (25%), Artist or Album affiliation (20%), and Duration similarity (15%). Selected candidates are sampled using a randomized temperature factor to ensure natural, cohesive playlists with high replay value.
- **Rationale:** Delivers instant streaming-style "Radio" autoplay queues purely from offline ID3 tag metadata and acoustic attributes without machine-learning model bloat.

### ADR 10.3: Zero-Battery-Overhead Smart Sleep Gestures (Shake & Flip)
- **Decision:** Created native Android accelerometer event streaming in `MainActivity.kt` mapped to `GestureSensorService`. To preserve battery life and prevent phantom wake locks, the native sensor listener is registered strictly during the active sleep timer fadeout window or when armed in `SleepTimerSheet`, and immediately unregistered upon timer expiration or cancellation. Shake gestures extend sleep time (+15m) and flip-to-pause stops audio when placed face-down.
- **Rationale:** Ensures effortless bedside interaction in the dark while eliminating idle sensor polling and background battery drain.

### ADR 10.4: Custom Tactile Now Playing Skins with Dynamic Theme Adaptation
- **Decision:** Implemented `NowPlayingSkin` supporting 4 distinct player interfaces: `defaultModern`, `spinningVinyl` (turntable with animated tone arm and grooved record), `retroCassette` (90s tape deck with spinning spools, tape counter, and vintage labeling), and `minimalistOled` (true `#000000` pitch black with high-contrast battery saving typography).
- **Rationale:** Elevates the Now Playing experience into a nostalgic, high-fidelity tactile music player with diverse aesthetic options.

### ADR 10.5: Native Android Auto Browsing via MediaBrowserServiceCompat Hierarchy
- **Decision:** Configured `SonaraAudioHandler` as an Android Auto compatible `MediaBrowserServiceCompat` with root categories (`playlists`, `artists`, `albums`, `liked`, `recent`) declared in `@xml/automotive_app_desc.xml`. Tracks and containers use deterministic URI-style Media IDs for fast, steering-wheel friendly car touchscreen navigation.
- **Rationale:** Enables drivers to safely access and play their offline music library on vehicle infotainment displays without touching their smartphone.

### ADR 10.6: Branded Visual Identity, PopScope Navigation Stack, Zero-Lag Resumes, and Dynamic Playlists
- **Decision:**
  1. *Brand Identity:* Added `SonaraBrandLogo` acoustic waveform squircle vector icon and updated all UI icons to Material 3 rounded variants (`Icons.*_rounded`).
  2. *Predictive Back Navigation:* Replaced naive system exits with predictive `PopScope` navigation: collapses expanded Now Playing sheets first, backtracks through user's bottom tab navigation history stack, and requires a double-tap within 2s to exit only when on the root Home tab.
  3. *Zero-Lag Resumes & DAC Pop Prevention:* Eliminated blocking volume fade loops in `play()` and unpausing in `SonaraAudioHandler`. Restored hardware volume synchronously to prevent 0-volume muted states. Added a 100ms hardware buffer on track skipping with `AnimatedSwitcher` slide+fade transitions for album art and track metadata.
  4. *Unified Virtual & Custom Playlists:* Unified virtual IDs (-1 Liked Songs, -2 Recently Added, -3 On Repeat) in `PlaylistService` and `PlaylistDetailScreen`, added a dedicated multi-select `PlaylistTrackPickerSheet` with search filtering, long-press playlist options (Play, Shuffle, Rename, Duplicate, Delete), direct track removals, drag reordering, and empty state resilience.
  5. *Audio Visualizers & Background Playback:* Overhauled `AudioVisualizer` with authentic backlit dual analog VU meters (scale arcs, dB markings, red overload LED), 24-band spectrum with gravity peak caps, and layered fluid harmonic waves. Added `backgroundPlayback` setting with Android lifecycle pause triggers.
- **Rationale:** Resolves user-reported audio delays, missing visual feedback, navigation inconsistencies, and playlist management limitations while maintaining strict offline invariants.

### ADR 10.7: Pristine High-Contrast White Mode and Dynamic Navigation Adaptation
- **Decision:**
  1. *White Mode Theme:* Added pure white `#FFFFFF` theme with neutral grey containers (`#F8F9FA`, `#F1F3F5`, `#E9ECEF`), high-contrast dark typography (`#191C1E`), zero muddy Material 3 surface tints (`surfaceTintColor: Colors.transparent`), and clean `#E8E8E8` dividers.
  2. *Quick Appearance Selector:* Added a 1-tap Theme selector button on the Home screen AppBar and expanded the Settings Theme dialog to directly switch between Light (White Mode), Dark (Default), AMOLED Dark (Pure Black), and System Default.
  3. *Navigation & MiniPlayer Dynamic Adaptation:* Configured `AppShell` bottom navigation bar and floating `MiniPlayer` card to dynamically render in pure white with subtle borders and shadows in White Mode, and pitch black with hairline borders in Minimalist OLED mode.
- **Rationale:** Delivers maximum daytime sunlight readability, high contrast, and clean modern aesthetics alongside the existing battery-saving pure black OLED and dark themes.
