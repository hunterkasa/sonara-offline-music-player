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

### [ ] Phase 1: Library Engine and Browse UI
- [ ] Permission flow & onboarding rationale (READ_EXTERNAL_STORAGE for <=32, READ_MEDIA_AUDIO for 33+)
- [ ] MediaStore background isolate scanner with batched transactional upserts & streaming progress
- [ ] Pure-Dart / robust tag reader & metadata fallbacks (filename, folder, "Unknown Artist")
- [ ] Artwork extraction pipeline (embedded, folder.jpg/cover.jpg/front.png, gradient fallback)
- [ ] Disk LRU thumbnail cache & off-UI palette extraction via `material_color_utilities`
- [ ] Incremental rescan (generation/modified timestamp diffs) & ContentObserver auto-refresh
- [ ] Folder include/exclude configuration and minimum duration filter (default 30s)
- [ ] Core browse screens: Songs, Albums, Artists, Genres, Folders
- [ ] Browse controls: Sort options, filter chips, list/grid toggle, sticky A-Z scrubber
- [ ] Album and Artist detail pages
- [ ] Skeletons, empty states, and error handling states

### [ ] Phase 2: Playback Core
- [ ] Audio handler background service (`mediaPlayback` foreground service on Android 14+)
- [ ] MediaSession, rich lock-screen & notification controls with artwork
- [ ] Headset gestures (single, double, triple clicks) & Bluetooth AVRCP metadata
- [ ] Audio focus management (pause on calls, transient ducking, unplug pause, auto-resume)
- [ ] Logical queue manager (Play now, next, last, reorder, remove, clear, undo)
- [ ] Shuffle (Fisher-Yates with saved seed, exhaust before repeat) & repeat modes (off/all/one)
- [ ] Gapless playback support & accurate decoder duration reconciliation
- [ ] Process death state persistence (logical queue, active index, position, shuffle/repeat)
- [ ] Corrupt / missing file skip resilience
- [ ] Persistent Mini-Player and base Now Playing expansion
- [ ] Tap-to-play from all browse lists & Android `ACTION_VIEW audio/*` intent handling

### [ ] Phase 3: Now Playing and Motion
- [ ] Expandable full Now Playing screen with shared-element transition & dynamic gradient
- [ ] Artwork scale animations on play/pause, swipe-to-skip, and swipe-down to dismiss
- [ ] Queue sheet ("Now Playing", "Next in Queue", "Next from Context", history tab)
- [ ] Synced lyrics viewer (USLT/SYLT embedded and `.lrc` sidecar, tap-to-seek, font resize)
- [ ] Sleep timer with gentle fade-out & tap-to-extend
- [ ] Playback speed control (0.5x to 2.0x with pitch preservation) & position memory for long tracks
- [ ] Track info sheet with detailed audio specs and quality badge (e.g. FLAC 24-bit/96kHz)
- [ ] Context menus and swipe actions across all track rows
- [ ] Haptic feedback engine (play/pause, scrub snap, long-press, undo)
- [ ] Android 15 predictive back & gesture navigation support

### [ ] Phase 4: Playlists, Favorites, and Personalization
- [ ] Liked songs persistence & toggles
- [ ] Playlist management: Create, rename, delete, duplicate, track reordering, mosaic artwork
- [ ] M3U / M3U8 playlist import and export
- [ ] Smart playlists (dynamic filter rule engine matching artist, genre, year, play count, etc.)
- [ ] Local listening statistics and history (play counts, skip counts, listening duration)
- [ ] Home shelves & local "Made for you" mixes (Daily Mixes, On Repeat, Rewind, Discover)
- [ ] Instant FTS5 search (case/diacritic insensitive, multi-script, grouped results, <100ms)

### [ ] Phase 5: Audio Quality Features
- [ ] Crossfade engine (0 to 12s configurable) & skip/pause gentle fades
- [ ] Device equalizer integration with actual hardware band discovery, bass boost, and loudness
- [ ] ReplayGain track/album normalization with configurable pre-amp
- [ ] Skip silence (Android platform capability)
- [ ] Mono downmixing and channel balance controls
- [ ] Audio settings UI

### [ ] Phase 6: Integrations and Library Tools
- [ ] Android Home Screen widgets (small, medium, large)
- [ ] App launcher dynamic shortcuts (Shuffle all, Liked, Recently played, Search)
- [ ] Audio duplicate finder (hash / metadata diffs) & safe hide/delete flow
- [ ] Full library backup and restore (JSON bundle with path & tag relinking)
- [ ] Cache management & storage inspector
- [ ] Open-source licenses display & settings polish

### [ ] Phase 7: Hardening and Release
- [ ] 60 FPS performance verification on 20,000+ tracks
- [ ] Cold start optimization (<1.5s to interactive library)
- [ ] Memory and battery profile review (zero unneeded wake locks)
- [ ] Failure matrix testing (SD card unmount, mid-track revocation, corrupt file storms)
- [ ] Accessibility review (48dp targets, 200% text scaling, screen reader labels, AA contrast)
- [ ] Localization verification (Arabic RTL, Bengali, CJK character rendering)
- [ ] Manifest security audit (confirm INTERNET permission is strictly absent)
- [ ] R8 optimization & release APK/AAB build (<30MB)
- [ ] Traceability matrix in `docs/QA_MATRIX.md`

### [ ] Phase 8: iOS Parity (On Request Only)
- [ ] Document picker import into sandbox
- [ ] AVAudioSession and background audio modes
- [ ] MPNowPlayingInfoCenter & MPRemoteCommandCenter
- [ ] iOS-specific equalizer and capability documentation

---

## Stretch Items (P2 - Built only when requested)
- [ ] Tag editor (single and batch, artwork replace; Android 11+ write-request flow)
- [ ] CUE sheet splitting & playback
- [ ] Android Auto media browse tree
- [ ] Per-output-device EQ profiles (Bluetooth vs wired vs speaker)
- [ ] Shake-to-extend sleep timer
- [ ] Song/artist radio based on metadata clusters
- [ ] Yearly "Wrapped"-style offline recap with shareable card generator
- [ ] User 5-star or custom ratings
