# ROADMAP: Sonara Development Plan

Status legend:
- [ ] Not started
- [x] Completed
- [-] Deferred / Paused

---

## Phases

### [x] Phase 0: Foundation
- [x] Environment verification (Flutter doctor, Android SDK, ADB, FFmpeg, Emulator/Device)
- [x] Project scaffolding & Git configuration
- [x] AGENTS.md, docs/PRD.md, docs/ROADMAP.md, docs/DECISIONS.md
- [x] Dependency verification & pinning (DECISIONS.md table)
- [x] Architecture skeleton (`lib/app`, `core`, `data`, `domain`, `audio`, `features`, `shared`)
- [x] Design tokens and theme system (Light, Dark, AMOLED + dynamic color foundation)
- [x] App shell (3-tab navigation shell, mini-player slot, Now Playing sheet stub)
- [x] Drift database schema v1 with bundled SQLite, WAL, FTS5 table, and migration tests
- [x] Riverpod state management wiring
- [x] Localization (l10n) scaffolding (ARB files, RTL-ready)
- [x] Strict analysis options (`analysis_options.yaml`) and test harness
- [x] `tool/seed_music` FFmpeg sine-wave track generator and ADB push utility
- [x] Debug-only 20,000 synthetic DB rows stress seeder
- [x] Quality gates: `dart format`, `flutter analyze`, test suite green, debug APK boots

### [x] Phase 1: Library Engine and Browse UI
- [x] Permission flow & onboarding rationale (READ_EXTERNAL_STORAGE for <=32, READ_MEDIA_AUDIO for 33+)
- [x] MediaStore background isolate scanner with batched transactional upserts & streaming progress
- [x] Pure-Dart / robust tag reader & metadata fallbacks (filename, folder, "Unknown Artist")
- [x] Artwork extraction pipeline (embedded, folder.jpg/cover.jpg/front.png, gradient fallback)
- [x] Disk LRU thumbnail cache & off-UI palette extraction via `material_color_utilities`
- [x] Incremental rescan (generation/modified timestamp diffs) & ContentObserver auto-refresh
- [x] Folder include/exclude configuration and minimum duration filter (default 30s)
- [x] Core browse screens: Songs, Albums, Artists, Genres, Folders
- [x] Browse controls: Sort options, filter chips, list/grid toggle, sticky A-Z scrubber
- [x] Album and Artist detail pages
- [x] Skeletons, empty states, and error handling states

### [x] Phase 2: Playback Core
- [x] Audio handler background service (`mediaPlayback` foreground service on Android 14+)
- [x] MediaSession, rich lock-screen & notification controls with artwork
- [x] Headset gestures (single, double, triple clicks) & Bluetooth AVRCP metadata
- [x] Audio focus management (pause on calls, transient ducking, unplug pause, auto-resume)
- [x] Logical queue manager (Play now, next, last, reorder, remove, clear, undo)
- [x] Shuffle (Fisher-Yates with saved seed, exhaust before repeat) & repeat modes (off/all/one)
- [x] Gapless playback support & accurate decoder duration reconciliation
- [x] Process death state persistence (logical queue, active index, position, shuffle/repeat)
- [x] Corrupt / missing file skip resilience
- [x] Persistent Mini-Player and base Now Playing expansion
- [x] Tap-to-play from all browse lists & Android `ACTION_VIEW audio/*` intent handling

### [x] Phase 3: Now Playing and Motion
- [x] Expandable full Now Playing screen with shared-element transition & dynamic gradient
- [x] Artwork scale animations on play/pause, swipe-to-skip, and swipe-down to dismiss
- [x] Queue sheet ("Now Playing", "Next in Queue", reordering handles, swipe-to-remove, clear)
- [x] Synced lyrics viewer (sidecar .lrc discovery, embedded tag fallback, tap-to-seek, font resize)
- [x] Sleep timer with gentle fade-out & tap-to-extend (+15m), end-of-track support
- [x] Playback speed control (0.5x to 2.0x with pitch preservation)
- [x] Track info sheet with detailed audio specs and quality badge (FLAC, MP3, bit depth, sample rate, copy path)
- [x] Context menus and swipe actions across all track rows (Play Next, Add to Queue, Undo snackbar)
- [x] Haptic feedback engine (play/pause, scrub snap, long-press, undo) with Settings toggle
- [x] Predictive back & gesture navigation support

### [x] Phase 4: Playlists, Favorites, and Personalization
- [x] Liked songs persistence & toggles
- [x] Playlist management: Create, rename, delete, duplicate, track reordering, mosaic artwork
- [x] M3U / M3U8 playlist import and export
- [x] Smart playlists (dynamic filter rule engine matching artist, genre, year, play count, etc.)
- [x] Local listening statistics and history (play counts, skip counts, listening duration)
- [x] Home shelves & local "Made for you" mixes (Daily Mixes, On Repeat, Rewind, Discover)
- [x] Instant FTS5 search (case/diacritic insensitive, multi-script, grouped results, <100ms)

### [x] Phase 5: Audio Quality Features
- [x] Crossfade engine (0 to 12s configurable) & skip/pause gentle fades (200ms volume ramp)
- [x] Device equalizer integration with hardware effects (`AndroidEqualizer`), 5 bands, 9 presets, bass boost, and loudness enhancer (`AndroidLoudnessEnhancer`)
- [x] ReplayGain track/album/smart normalization with configurable pre-amp (-12dB to +12dB) and clipping prevention clamp
- [x] Skip silence (`player.setSkipSilenceEnabled`)
- [x] Mono downmixing and stereo channel balance controls (-1.0 to +1.0)
- [x] Long-audio position memory for tracks >= 20 minutes (podcasts, DJ sets)
- [x] Dedicated Equalizer UI (`EqualizerScreen`) and Audio Settings UI (`AudioSettingsScreen`) linked from Settings and Now Playing

### [x] Phase 6: Integrations and Library Tools
- [x] Android Home Screen widgets (small, medium, large)
- [x] App launcher dynamic shortcuts (Shuffle all, Liked, Recently played, Search)
- [x] Audio duplicate finder (hash / metadata diffs) & safe hide/delete flow
- [x] Full library backup and restore (JSON bundle with path & tag relinking)
- [x] Cache management & storage inspector
- [x] Open-source licenses display & settings polish

### [x] Phase 7: Hardening and Release
- [x] 60 FPS performance verification on 20,000+ tracks
- [x] Cold start optimization (<1.5s to interactive library)
- [x] Memory and battery profile review (zero unneeded wake locks)
- [x] Failure matrix testing (SD card unmount, mid-track revocation, corrupt file storms)
- [x] Accessibility review (48dp targets, 200% text scaling, screen reader labels, AA contrast)
- [x] Localization verification (Arabic RTL, Bengali, CJK character rendering)
- [x] Manifest security audit (confirm INTERNET permission is strictly absent)
- [x] R8 optimization & release APK/AAB build (<30MB)
- [x] Traceability matrix in `docs/QA_MATRIX.md`

### [x] Phase 8: Audiophile & Sound Engine Standouts
- [x] Per-output-device audio profiles (auto-switch EQ, crossfade, and volume by Bluetooth/Wired/Speaker)
- [x] Real-time audio visualizer (60 FPS spectrum bars, analog VU meters, fluid wave) & waveform seekbar
- [x] Independent musical pitch transposition (-12 to +12 semitones) and tempo controls

### [x] Phase 9: Library Power-Tools, CUE & Lyrics Studio
- [x] In-app tag and artwork editor (ID3v2, Vorbis, MP4) with Android 11+ `MediaStore.createWriteRequest`
- [x] CUE sheet parser & virtual multi-track album rip splitting
- [x] Interactive synchronized LRC lyrics editor (tap-to-stamp timestamp recorder)

### [x] Phase 10: Smart Listening, Offline Wrapped & Ecosystem
- [x] 100% offline "Wrapped" recap with shareable local Canvas image cards
- [x] Offline "Track Radio" (metadata & acoustic clustering smart queue)
- [x] Offline "Today's Pick" daily spotlight & similarity radio queue
- [x] Spotify-style "Daily Mix" playlists (1–6 personalized mixes clustered by genre/artist with vibrant gradient covers & virtual playlist integration)
- [x] Smart sleep gestures (shake-to-extend, flip-to-pause)
- [x] Custom Now Playing skins (spinning vinyl, retro cassette, minimalist OLED)
- [x] Android Auto dashboard integration (`MediaBrowserServiceCompat`)
- [x] Expanded Home Screen widget suite (4×2 large artwork widget, 2×1 minimalist pill, scrollable favorites/recents widget)

### [ ] Phase 11: iOS Parity (On Request Only)
- [ ] Document picker import into sandbox
- [ ] AVAudioSession and background audio modes
- [ ] MPNowPlayingInfoCenter & MPRemoteCommandCenter
- [ ] iOS-specific equalizer and capability documentation

