# AGENTS.md: Developer & Agent Protocol for Sonara

This document establishes the architecture rules, coding standards, commands, quality gates, and critical pitfalls for Sonara. Always consult this document before initiating any phase.

---

## 1. Stack & Tooling

- **Framework:** Flutter + Dart (latest stable).
- **Platform:** Android first (minSdk 26, targetSdk 34+). iOS deferred.
- **State Management:** Riverpod (`flutter_riverpod`).
- **Navigation:** `go_router` with `StatefulShellRoute` for tab bar persistence.
- **Database:** Drift with bundled SQLite (`sqlite3_flutter_libs`), WAL mode, and FTS5 search.
- **Audio Stack:** `audio_service` (MediaSession + foreground service) + `just_audio` (playback engine) + `audio_session` (audio focus).
- **Palettes & Art:** `material_color_utilities` off UI thread; disk-backed LRU thumbnail cache.
- **Analysis:** Strict Dart analysis (`strict-casts`, `strict-inference`, `strict-raw-types`).

---

## 2. Architecture Rules

Follow a feature-first, 3-tier reactive pattern:
```
lib/
  app/        # Bootstrap, router, theme tokens, l10n
  core/       # Errors, logging, utils, platform bridges
  data/       # db/ (Drift), sources/ (MediaStore, tags, art), repositories/
  domain/     # Entities, services (queue, shuffle, smart playlists), usecases
  audio/      # audio_handler, playback_controller, equalizer, sleep_timer
  features/   # home, search, library, album, artist, playlist, now_playing, queue, etc.
  shared/     # artwork, track_tile, shelves, skeletons, sheets, menus
```

### Invariants:
1. **Single Source of Truth:** Drift DB is the single source of truth. UI observes reactive query streams; it does not retain unpersisted duplicate state.
2. **Audio Isolation:** The UI NEVER calls audio plugins directly. All playback actions flow exclusively through the `PlaybackController` abstraction.
3. **Repository Pattern:** Data sources are accessed strictly via abstract domain repository interfaces.
4. **Isolate Boundary:** Heavy file scanning, deep tag extraction, and image downsampling MUST run in background isolates, never on the UI thread.
5. **Offline & Private:** Absolute zero network. No `android.permission.INTERNET` in release manifest. No remote analytics or external font downloads.

---

## 3. Working Protocol & Commands

Deliverables are strictly phase-gated. Proceed only when directed:

- **`GO <n>`**: Execute Phase n. Open with a plan (<= 1 page). Run quality gates, update `docs/ROADMAP.md`, commit (`phase N: ...`), post walkthrough, and STOP. Never auto-start Phase n+1.
- **`FIX: <issue>`**: Deliver a minimal-diff fix accompanied by a regression test.
- **`STATUS`**: Report roadmap progress, current test coverage, and open gaps.
- **`AUDIT`**: Diff code against `docs/PRD.md` and report any deviations.
- **`SCOPE: <change>`**: Update PRD and ROADMAP, then continue.

Rule on ambiguity: Choose the most conventional robust option, log it in `docs/DECISIONS.md`, and proceed autonomously. Stop and ask only if a tool/SDK is missing or an action is destructive.

---

## 4. Coding Standards

- **Formatting & Analysis:** Zero `flutter analyze` warnings. Zero `dart format` deviations.
- **Widgets:** Prefer `const` constructors. Use builder constructors (`ListView.builder`) with fixed extents when possible. Wrap heavy artwork in `RepaintBoundary`. Provide `cacheWidth` / `cacheHeight` on image decoders.
- **Build Methods:** Zero synchronous file I/O or database access inside `Widget.build()`.
- **Error Handling:** Graceful fallbacks for every screen: Loading, Empty, and Error states. Corrupt or unplayable files must display user snackbars and skip smoothly without crash loops.
- **Stable Identity:** Tracks are keyed by `trackKey` (SHA-256 of normalized title, artist, album, duration, size) to survive file renames and moves.

---

## 5. Quality Gates (Definition of Done for Every Phase)

1. **Static Health:** `dart format` passes cleanly; `flutter analyze` has 0 issues.
2. **Automated Tests:**
   - Unit tests for all business logic (queue, shuffle, tag fallbacks, LRC parser, smart rules, migrations).
   - Widget tests for primary UI components (mini-player, Now Playing, track tile).
   - Integration test for the phase golden path.
   - Pure logic test coverage >= 90%; overall coverage >= 70%.
3. **Build & Run:** `flutter build apk --debug` succeeds; app boots on emulator or device. Screenshots stored in `docs/screenshots/phase-N/`.
4. **Documentation & Git:** `ROADMAP.md`, `DECISIONS.md`, and `README.md` updated. Atomic commit formatted as `phase N: <description>`.
5. **Walkthrough:** Post concise report: what was built, verifiable evidence, known gaps, how to run, next phase risk.

---

## 6. Top Pitfalls

1. **Android Permissions:** API <=32 requires `READ_EXTERNAL_STORAGE`; API 33+ requires `READ_MEDIA_AUDIO` + `POST_NOTIFICATIONS`. Handle permanent denial with deep-link settings dialog.
2. **Foreground Service:** Android 14+ (API 34) requires `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permission and `mediaPlayback` service type.
3. **Scoped Storage:** Always play and load artwork through Content URIs (`content://...`). Raw file paths are solely for folder display and filtering.
4. **Queue Scalability:** Never load 20,000 tracks into `just_audio` ConcatenatingAudioSource. The domain `QueueManager` retains the logical list; the player loads only a sliding window of upcoming tracks.
5. **Persistence Triggers:** Save queue and playback position on pause, every 5s while playing, and on Android lifecycle pause/detach.
6. **Decoder Durations:** VBR MP3 header durations often mislead; reconcile with actual decoder duration upon playback and update Drift DB.
7. **Predictive Back:** Ensure Now Playing sheet and nested modals intercept back navigation before exiting root tabs.
8. **Pure Offline:** Merged release manifest must never contain `INTERNET`.
