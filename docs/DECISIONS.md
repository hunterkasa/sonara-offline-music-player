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
