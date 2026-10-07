# Phase 10 Plan: Smart Listening, Offline Wrapped & Ecosystem

## 1. Objectives & Scope
Phase 10 delivers smart listening algorithms, 100% offline listening insights, sensor-driven sleep timer gestures, diverse Now Playing skins, Android Auto media browser hierarchy, and an expanded Android home screen widget suite.

1. **100% Offline "Wrapped" Recap & Local Canvas Cards:**
   - Domain service (`WrappedService`) analyzing Drift SQLite play counts, skip stats, listening durations, genres, and timestamps.
   - Calculates Top Artists, Total Hours Listened, Top Genre Breakdown, Most Skipped Tracks, Peak Listening Hour, and Listening Streaks.
   - Story/carousel UI (`WrappedScreen`) with custom painter / `RepaintBoundary` rendering high-resolution exportable graphics cards.
   - 100% private, on-device only.

2. **Offline "Track Radio" (Metadata & Acoustic Similarity Engine):**
   - Domain service (`TrackRadioService`) building a recommendation queue from a seed track.
   - Multi-factor scoring: genre match (40%), era/year proximity (25%), artist collaborations (20%), track duration similarity (15%).
   - Integrated into track context sheets ("Start Radio") and Now Playing options.

3. **Smart Sleep Gestures (Shake-to-Extend & Flip-to-Pause):**
   - Native `SensorManager` bridge in `MainActivity.kt` and `GestureSensorService` listening to Accelerometer & Proximity sensors.
   - Shake detection during sleep timer / fade-out adds +15 minutes with haptic confirmation.
   - Flip face-down gesture immediately triggers pause.
   - Lifecycle-bound: only registers listeners when sleep timer or gesture toggle is active to ensure 0% battery drain when idle.

4. **Custom Now Playing Skins (Vinyl, Cassette, Minimalist OLED, Default):**
   - `NowPlayingSkin` enum: `defaultModern`, `spinningVinyl`, `retroCassette`, `minimalistOled`.
   - Spinning Vinyl: 33 RPM rotation, tonearm needle tracking play/pause, album art label.
   - Retro Cassette: Dual spinning tape spools, magnetic tape head, vintage cassette casing.
   - Minimalist OLED: Pure `#000000` dark theme, battery-saving typography, ultra-clean UI.
   - Integrated into `NowPlayingSheet` with instant skin switcher.

5. **Android Auto Dashboard Integration (`MediaBrowserServiceCompat`):**
   - Android automotive manifest declaration (`automotive_app_desc.xml`).
   - `SonaraAudioHandler` implementation of `getChildren`, `getItem`, `playFromMediaId`, and `search`.
   - Exposes browse hierarchy: Playlists, Artists, Albums, Liked Songs, Recently Played.

6. **Expanded Home Screen Widget Suite:**
   - 4x2 Large Artwork & Controls Widget.
   - 2x1 Minimalist Pill Widget.
   - 4x3 Scrollable Recents/Favorites Widget with collection remote views and direct deep-link playback.

## 2. Quality Gates & Verification
1. `flutter analyze` 0 issues; `dart format` clean.
2. Unit tests for `WrappedService`, `TrackRadioService`, `NowPlayingSkin`, and Android Auto media tree.
3. Widget tests for `WrappedScreen`, `NowPlayingSheet` skins, and gesture controllers.
4. All tests passing (target >= 220 tests).
5. Debug build verified on Android emulator with screenshots in `docs/screenshots/phase-10/`.
6. Docs updated (`ROADMAP.md`, `DECISIONS.md`, `QA_MATRIX.md`, `README.md`) + atomic commit `phase 10: ...`.
