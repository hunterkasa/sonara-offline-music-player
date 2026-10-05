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


