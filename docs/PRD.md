# PROJECT BRIEF: Sonara, a premium offline music player (Flutter, Android-first)

You are a senior mobile engineer, product designer and QA lead working as one autonomous agent. Build a production-grade **offline music player** that plays audio files already stored on the phone, with the polish and feature depth of Spotify and Apple Music, minus streaming, accounts, ads and tracking. Everything must work in airplane mode, forever.

## 1. Configuration (edit before sending)

- **APP_NAME:** Sonara
- **APP_ID:** com.example.sonara (placeholder; set the real ID before release)
- **Framework:** Flutter + Dart, latest stable
- **Platforms:** Android. ignore the part for ios, for now we only build this for android.
- **Android:** minSdk 26 unless a verified plugin forces higher; targetSdk = latest stable API
- **Design:** dark-first, artwork-driven color, Material 3 base with our own design tokens
- **Languages:** English default; i18n-ready (ARB) and RTL-safe; track tags must render correctly in any script (Bengali, Hindi, Arabic, CJK, Cyrillic and so on)

## 2. How you must work

1. **Persist the brief first.** Save this message verbatim as `docs/PRD.md` (skip if it already exists). Create `docs/ROADMAP.md` (phases with checkboxes), `docs/DECISIONS.md` (log of non-obvious choices) and `AGENTS.md` (max 8,000 characters: stack, architecture rules, commands, coding standards, Definition of Done, this protocol, top pitfalls). If code and PRD disagree, the PRD wins unless DECISIONS.md says otherwise. At the start of each phase read `AGENTS.md` and only the PRD sections that phase needs. Never rely on chat memory alone.
2. **Phase-gated delivery.** Do only the phase I name. Open with a plan of one page or less (do not restate the PRD). Finish by running the quality gates (section 10), posting a short walkthrough (built, evidence, known gaps, how to run), ticking `docs/ROADMAP.md`, committing to git (`phase N: ...`), then **stop and wait**. Never start the next phase on your own. If a phase is too big for one run, split it yourself into N-a / N-b, finish N-a completely and tell me; do not cut corners.
3. **My commands.** `GO <n>` run phase n. `FIX: <issue>` minimal-diff fix plus a regression test. `STATUS` roadmap progress and open gaps. `AUDIT` compare the code against the PRD and list deviations. `SCOPE: <change>` update PRD and roadmap, then continue.
4. **Be autonomous.** On ambiguity choose the most conventional option, log it in `DECISIONS.md` and keep going. Stop and ask only if (a) a required SDK, tool or device is missing, (b) an action is destructive or irreversible, or (c) a choice materially changes scope or platform support.
5. **Verify, don't assume.** Before adding any dependency, check its current docs and pub.dev page: latest stable, actively maintained, compatible with current Flutter/Dart and the Android target SDK, no blocking open issues. Pin versions and record the choice. Never claim something works unless you ran it. If you cannot run it (no device or emulator), say exactly what is unverified and give me a 3-step manual check.
6. **Spend tokens wisely** (I run you at High thinking). Reason deeply only about architecture, concurrency, the audio engine, the data model and migrations; write boilerplate directly. Use targeted edits instead of whole-file rewrites. Do not re-read unchanged files or paste large files or logs into chat. Use the fast loop (format, analyze, unit tests) constantly and the emulator loop only at the end of a phase. Keep commentary terse.
7. **No half-work.** No TODO stubs, mock data in production paths, dead code or unused dependencies in finished work. Anything deferred goes in `ROADMAP.md` with a reason.
8. **Stay safe.** Never modify files outside the project, never touch real music libraries in tests, never commit copyrighted audio. Use generated sample audio only.

## 3. Product principles

- **Offline and private.** No network use at all. The release manifest must not declare INTERNET. No analytics, crash-reporting SDKs, ads or accounts. Bundle every font and asset (no runtime font downloading).
- **Fast.** Usable library in under 1.5 s on a cached launch, 60 fps lists at 20,000+ tracks, scanning never blocks the UI.
- **Delightful.** Fluid motion, haptics, artwork-driven color, and no dead ends: every screen has loading, empty and error states.
- **Trustworthy.** Never lose the queue, playlists, favorites or stats. Destructive actions are confirmable or undoable. DB migrations are tested and preceded by an automatic snapshot.
- **Original.** Borrow interaction patterns, not identity: no Spotify or Apple names, logos, icons, copy or assets.

## 4. Stack and architecture

Defaults below; deviate only with a `DECISIONS.md` entry.

- **Tooling:** Flutter + Dart latest stable. Strict analysis (strict-casts, strict-inference, strict-raw-types plus a recommended lint set).
- **Layers:** presentation, domain, data. Feature-first folders. Repositories behind interfaces. The DB is the single source of truth and the UI observes reactive queries. The UI never touches an audio plugin directly, only a `PlaybackController` interface.
- **State and navigation:** Riverpod; go_router with a stateful shell for the tabs.
- **Database:** Drift on bundled SQLite (sqlite3_flutter_libs), WAL mode, FTS5 for search, versioned migrations with tests.
- **Audio:** just_audio + audio_service + audio_session (verify current versions and Android 14+ foreground-service behavior).
- **Library access:** MediaStore through a maintained plugin. If none passes rule 2.5, write a thin Kotlin bridge (Pigeon or MethodChannel) for queries, ContentObserver, artwork and delete/write requests. Deep tag parsing runs in a background isolate with a verified pure-Dart or Rust-backed library.
- **Images and color:** own LRU disk cache for thumbnails; decode at display size; palette extraction off the UI thread using Flutter's `material_color_utilities`, cached in the DB.
- **Likely extras (verify each):** permission_handler, share_plus, home_widget, quick_actions, intl.

Folder layout:

```
lib/
  app/        bootstrap, router, theme + design tokens, l10n
  core/       errors, logging, utils, platform bridges
  data/       db/, sources/ (media_scanner, tag_reader, artwork_store, lyrics_reader), repositories/
  domain/     entities, services (queue_manager, shuffle, recommender, smart_playlists), usecases
  audio/      audio_handler, playback_controller, equalizer, sleep_timer, crossfade
  features/   home, search, library, album, artist, playlist, now_playing, queue, lyrics, equalizer, stats, settings, onboarding
  shared/     artwork, track_tile, shelves, skeletons, sheets, menus
test/  integration_test/  tool/  docs/
```

## 5. Features

**P0** = must ship. **P1** = should ship. **P2** = stretch, implemented only when I ask.

### Library and scanning
- **P0** Onboarding with permission rationale and live scan progress. Android 12 and below: READ_EXTERNAL_STORAGE; 13+: READ_MEDIA_AUDIO. Handle denied and permanently denied (deep link to system settings).
- **P0** MediaStore scan in a background isolate with batched transactional upserts; results stream into the UI while scanning.
- **P0** Incremental rescan (modified/generation diffs), ContentObserver refresh, pull-to-refresh, "Rescan" in settings. Deleted files are detected; removable volumes can appear and disappear safely.
- **P0** Filters: include/exclude folders, honor `.nomedia`, minimum duration (default 30 s) and minimum size, to skip ringtones and voice notes.
- **P0** Every format the platform decodes (MP3, AAC/M4A, FLAC, OGG, Opus, WAV and so on). Unsupported or corrupt files are flagged, never crash the app.
- **P0** Tags: title, artist, album, album artist, genre(s), year, track/disc number, duration, bitrate, sample rate, channels, codec, ReplayGain, embedded lyrics, artwork. Correct legacy-encoding handling and fallbacks (filename for title, folder for album, "Unknown Artist").
- **P0** Artist logic: configurable multi-artist delimiters (; / feat. &), album-artist grouping, compilations ("Various Artists"), sort names that ignore leading The/A/An, locale-aware collation.
- **P0** Artwork: embedded, then folder.jpg/cover.jpg/front.png, then a generated gradient placeholder. Multi-size disk-cached thumbnails; palettes cached.
- **P1** Track info sheet (codec, bitrate, sample rate, bit depth, channels, size, path, all tags) with a quality badge such as "FLAC · 24-bit/96 kHz".
- **P1** Duplicate finder (title + artist + duration within 2 s; audio hash on demand) with safe hide/merge. Delete from device through the system consent dialog. "Hide from library".
- **P2** Tag editor (single and batch, artwork replace; Android 11+ write-request flow), CUE sheets.

### Playback engine
- **P0** Background playback through a `mediaPlayback` foreground service; MediaSession; rich notification (artwork, prev/play/next, seek bar); lock-screen controls; Bluetooth/AVRCP metadata; headset button gestures (1, 2 and 3 presses).
- **P0** Audio focus: pause on calls, duck for navigation prompts (configurable), pause when headphones unplug, optional auto-resume after transient interruptions and on Bluetooth reconnect.
- **P0** Queue: play now / next / last. "Up Next" (user-added) is kept separate from the source context (Spotify model). Drag-reorder, swipe-remove, clear, undo. Scales to 20k+ items.
- **P0** Shuffle (no repeats until exhausted, current track first, seed stored so restore keeps the order, original order returns when switched off) and repeat off/all/one.
- **P0** Gapless playback, accurate seeking, durations reconciled with the decoder (VBR MP3).
- **P0** Full restore after app or process death (queue, index, position, shuffle/repeat). Never autoplay on cold start unless enabled.
- **P0** Resilience: corrupt or missing file gives a gentle message, skips and flags the track; never loops forever.
- **P1** Crossfade 0 to 12 s (configurable) with fades on skip and pause/resume; "stop after this track". If the plugin cannot deliver glitch-free crossfade, ship gapless + fades and record the limitation.
- **P1** Speed 0.5x to 2.0x with pitch preservation; remembered position and speed for long audio (20 min or more: podcasts, audiobooks, DJ mixes).
- **P1** Sleep timer: presets and custom, end of track, end of queue, gentle fade-out, extend with one tap.
- **P1** Normalization: ReplayGain track/album with pre-amp; fall back to platform loudness effects.
- **P1** Equalizer with presets driven by the device's actual bands, bass boost and loudness where the platform offers them; skip-silence (Android), mono, balance.
- **P2** Android Auto media browse tree; per-output-device EQ profiles; shake-to-extend sleep timer.

### Playlists and personalization
- **P0** Liked songs; playlist create/rename/delete/duplicate; add, remove, drag-reorder; multi-select add; cover mosaic or custom image; Recently played, Recently added, Most played.
- **P1** M3U/M3U8 import/export (resolve by path, then by tags). Smart playlists (rules on genre, artist, year, rating, play count, last played, date added, format, duration; match all/any; limit; sort). Play history and stats (plays, skips, listening time).
- **P1** Local "Made for you": Daily Mixes by genre/era/artist cluster, On Repeat, Rewind (not played in 90 days), New in your library, Discover (rarely played).
- **P2** Song/artist radio built from shared artist, genre, era, BPM tag and playlist co-occurrence; yearly "Wrapped"-style stats with a shareable image; ratings.

### Search
- **P0** Instant search across title, artist, album, genre, playlist and folder. Case- and diacritic-insensitive, multi-script. Grouped results (Top result, Songs, Albums, Artists, Playlists), recent searches, under 100 ms at 20k tracks.
- **P1** Typo tolerance, filter chips, Browse-all tiles (genres and decades), search within a playlist or the queue.

### Lyrics
- **P0** Embedded lyrics (USLT/SYLT/Vorbis) and sidecar `.lrc`. Line-synced highlight, auto-scroll, tap-to-seek, plain-text fallback, font-size control.
- **P1** Offset adjust, import/paste `.lrc`, edit lyrics, full-screen lyrics. No online fetching in v1 (keep INTERNET out).

### System integration
- **P0** "Open with" for audio files (ACTION_VIEW audio/*) plays without importing. Share audio files.
- **P1** Home-screen widgets (small, medium, large). Dynamic app shortcuts (Shuffle all, Liked, Recently played, Search).

### Settings, backup, accessibility
- **P0** Theme (System/Light/Dark/AMOLED), accent source (artwork / Material You / fixed); library, playback, audio, notification and language settings. Accessibility per section 8.
- **P1** Backup/restore in one versioned file (playlists, favorites, stats, settings; relink by path, then by tags). Storage usage and cache clearing. Open-source licenses.

**Out of scope for v1:** streaming, accounts, cloud sync, scrobbling, online metadata or lyrics lookup, podcast feeds, social features.

## 6. UX/UI spec

Target feel: Spotify's queue model and home shelves, Apple Music's lyrics and library index, Material You color.

- **Structure.** Bottom bar: Home, Search, Library. A persistent mini-player sits above it. A gear icon in the Home and Library headers opens Settings. The back gesture always collapses the player first.
- **Mini-player.** Artwork thumb, title/artist (marquee on overflow), play/pause, next, hairline progress, background tinted by artwork color. Swipe left/right = next/previous. Tap or swipe up = expand.
- **Now Playing.** Artwork-derived gradient background that cross-fades between tracks. Large rounded artwork that scales down when paused and up when playing. Title and artist (tap to open album/artist), heart. Seek bar with scrub preview, elapsed/remaining and quality badge. Transport row: shuffle, previous, play/pause, next, repeat. Secondary row: lyrics, queue, sleep timer, EQ, more. Swipe artwork left/right to skip, swipe down to collapse, swipe up (or button) for Lyrics and Queue panels. Lyrics use large type, an emphasized active line, dimmed inactive lines, auto-scroll, tap a line to seek, adjustable size, full-screen mode.
- **Home.** Time-of-day greeting; quick-access grid (Liked Songs, last played context, Shuffle All, Recently added). Horizontal shelves: Jump back in, Made for you, Recently added, On repeat, Your top artists (circular), Rewind, Discover from your library. All computed locally. Pull-to-refresh triggers a rescan.
- **Library.** Pinned filter chips (Playlists, Albums, Artists, Songs, Genres, Folders). Sort menu (recently added/played, A-Z, year, play count). List/grid toggle. A-Z scrubber with sticky headers. "Liked Songs" pinned. Multi-select with batch actions (play next, queue, add to playlist, share, hide, delete).
- **Track rows.** Swipe right = add to Up Next with an Undo snackbar. Long-press or the more button opens the context sheet: Play next, Add to queue, Add to playlist, Like, Go to album/artist, Share, Track info, Edit tags, Hide, Delete.
- **Detail pages (album, artist, playlist, genre, folder).** Collapsing header with artwork and tinted gradient; Play and Shuffle buttons; track list with track numbers, disc grouping and durations. Artist page: top tracks (by plays), albums, appears-on.
- **Search.** Sticky field. Before typing: recent searches and Browse-all tiles (genres, decades). While typing: instant grouped results with filter chips.
- **Queue sheet.** "Now playing", "Next in queue" (user-added), "Next from <source>", history tab. Drag handles, swipe to remove, multi-select, Clear, Save as playlist.
- **States.** First run: welcome, why audio access is needed, live scan progress ("Everything stays on your device"). Permission denied: explanation plus "Open settings". Plus empty library, scanning banner and error snackbars with actions.
- **Design tokens.** 4-pt spacing grid. Radii: artwork 12 to 16 dp, artist art circular, cards 12, sheets 24. One bundled variable typeface (weights 400 to 800, tabular numerals for time). Tonal surfaces and blur instead of heavy shadows. AA contrast guaranteed on dynamic backgrounds (auto-adjust with a scrim).
- **Motion and haptics.** 150/250/400 ms durations with emphasized easing; spring physics for sheets; honor reduce-motion. Haptics on play/pause, seek snaps, long-press and undo; user-toggle.

## 7. Data model (Drift; adapt as needed)

- `tracks`: id, trackKey, mediaStoreId, contentUri, path, relativeDir, title, titleSort, artistId, albumId, albumArtistId, trackNo, discNo, year, durationMs, bitrate, sampleRate, bitDepth, channels, mime, sizeBytes, dateAdded, dateModified, artworkKey, replayGainTrackDb, replayGainAlbumDb, hasLyrics, playCount, skipCount, lastPlayedAt, isFavorite, isHidden, isMissing, rating.
- `trackKey` is a stable identity (hash of normalized title + artist + album + duration + size) so favorites, playlists and stats survive moves, renames and rescans.
- `artists` (name, nameSort, artworkKey), `albums` (title, titleSort, albumArtistId, year, artworkKey, paletteJson), `genres` + `track_genres`.
- `playlists` (id, name, description, coverUri, isSmart, rulesJson, createdAt, updatedAt) + `playlist_tracks` (playlistId, trackKey, position, addedAt).
- `queue_state` (single row: ordered logical queue, index, positionMs, shuffle, repeat, seed), `play_history` (trackKey, startedAt, listenedMs, completed, source).
- `library_folders` (path, mode include/exclude), `settings` (key, JSON value).
- Indices on columns used for sorting and filtering (albumId, artistId, titleSort, dateAdded, lastPlayedAt, playCount, isFavorite). `tracks_fts` FTS5 table over title, artist, album, genre.

## 8. Non-functional requirements

- **Performance** (verify on a mid-range device when available, otherwise by profiling and static review): cold start to usable library under 1.5 s with a cached DB; 60 fps with 20k+ tracks; search under 100 ms; MediaStore pass for 10k tracks under 10 s with deep tags and artwork filled in lazily; image cache capped (about 100 MB); release APK at most 30 MB per ABI (report the actual size).
- **Reliability:** atomic persistence; survive process death; handle corrupt, zero-byte and unsupported files, SD-card removal, permission revoked mid-session, low storage, focus loss, Bluetooth disconnects, rapid skip spam, and extremely long or emoji/RTL/mixed-script tags. Global error handling logs locally (rotating file, user-exportable); no remote reporting.
- **Battery:** no wake locks beyond playback; no timers while paused; position stream throttled and active only while the UI is visible; notification state updated through MediaSession, not re-posted.
- **Privacy and security:** zero network; INTERNET absent from the merged release manifest (add a check that fails the build if it appears); no analytics, ads or accounts; minimal exported components; backups are user-initiated.
- **Accessibility:** semantic labels on every control, 48 dp minimum targets, text scaling to 200% without clipping, AA contrast (including on dynamic gradients), reduce-motion and haptics toggles, logical focus order, primary controls reachable one-handed.
- **Localization:** ARB with plurals, RTL mirroring, locale-aware sorting and number/date formats.

## 9. Known pitfalls (read before coding)

1. Permissions by API level: READ_EXTERNAL_STORAGE (32 and below), READ_MEDIA_AUDIO and POST_NOTIFICATIONS (33+), foreground service type `mediaPlayback` plus FOREGROUND_SERVICE_MEDIA_PLAYBACK (34+).
2. Scoped storage: play and load artwork through content URIs. Raw paths are only for display and folder filtering.
3. No heavy work on the UI isolate, no synchronous I/O in `build()`, batch DB writes in transactions (about 500 rows).
4. Large queues: keep the logical queue in the domain layer; the audio engine holds only a sliding window of upcoming items.
5. Persist queue and position on pause, about every 5 s while playing, and on lifecycle changes.
6. Tag durations can be wrong (VBR MP3): reconcile with the decoder and update the DB.
7. Crossfade and gapless share one transition mechanism; test both with a 30-track run.
8. MediaSession and notification: debounce metadata updates; expose artwork through URIs the system UI can read.
9. Android 15+ edge-to-edge and predictive back: the Now Playing sheet must collapse on the back gesture.
10. Lists: builder constructors, fixed extents where possible, const widgets, `RepaintBoundary` around artwork, `cacheWidth`/`cacheHeight` on images.
11. Release builds: verify shrinker (R8) rules for the audio stack and inspect the merged manifest for stray permissions.
12. Fonts and assets are bundled; never call a font-downloading API.

## 10. Quality gates (Definition of Done, every phase)

1. `dart format` clean and `flutter analyze` with zero issues.
2. Tests for all new logic. Unit: queue, shuffle, scanner diffing, tag fallbacks, LRC parser, M3U, smart-playlist rules, migrations. Widget: mini-player, Now Playing, track tile. At least one integration test for the phase's golden path. Pure logic at 90% coverage or more, overall 70% or more.
3. `flutter build apk --debug` succeeds. The app runs on an emulator or device (if available) and the golden path passes; screenshots saved to `docs/screenshots/phase-N/`.
4. README, ROADMAP and DECISIONS updated; git commit made; the main branch always builds.
5. Walkthrough posted: what was built, evidence (command output, screenshots), known gaps, biggest risk for the next phase.

## 11. Roadmap

**Phase 0: Foundation.** Check the environment (`flutter doctor -v`, Android SDK, emulator or device, adb, ffmpeg); if anything is missing, stop and give exact install steps. Create the project and init git. Write AGENTS.md and docs. Verify and pin dependencies, with a table in DECISIONS.md (package, version, last publish, maintained?, why). Build the architecture skeleton (section 4), design tokens and theme (Light/Dark/AMOLED), app shell (3 tabs, mini-player slot, Now Playing sheet stub), Drift schema v1 with a migration test, Riverpod wiring, l10n scaffolding, strict lints and test harness. Add `tool/seed_music`: generate tagged sine-wave tracks with ffmpeg, adb-push them to the device Music folder and trigger a media scan (fallback if ffmpeg is missing: tell me what to drop in manually). Add a debug-only seeder for 20,000 synthetic DB rows.
*Exit:* app boots into the shell on a device or emulator; format, analyze and tests are green.

**Phase 1: Library engine and browse UI.** Permission flow and onboarding; MediaStore scanner (isolate, batched upserts, streaming progress); tag reader and fallbacks; artwork pipeline and palettes; incremental rescan and ContentObserver; folder and min-duration filters; Songs, Albums, Artists, Genres and Folders screens with sort, filter chips, list/grid toggle and A-Z scrubber; basic album and artist pages; skeleton, empty and error states.
*Exit:* the seeded library appears within seconds; the 20k-row stress test scrolls without jank; rescan detects add, remove and rename.

**Phase 2: Playback core.** Audio handler and foreground service; MediaSession, notification and lock screen; headset and Bluetooth buttons; audio focus, noisy and interruptions; queue manager (play now/next/last, reorder, remove, clear, undo); shuffle and repeat; gapless; persistence and restore; error resilience; mini-player; basic Now Playing; tap-to-play from every list; "Open with" intents.
*Exit:* background playback with the screen off; notification controls work; killing the process and relaunching restores queue and position.

**Phase 3: Now Playing and motion.** Expandable full player (shared-element artwork, dynamic gradient, scale on pause, swipe gestures); queue sheet (Up Next vs. context, reorder, save as playlist, history); lyrics (embedded and .lrc, synced); sleep timer; speed; track info sheet with quality badge; context menus, swipe actions and share everywhere; haptics; predictive back.
*Exit:* all player interactions are smooth and accessible; the golden-path integration test passes.

**Phase 4: Playlists, favorites and personalization.** Liked songs; playlist CRUD, reorder and covers; M3U/M3U8 import/export; smart playlists; play history and stats; Home shelves and local "Made for you" mixes; FTS5 search with recents, filters and typo tolerance.
*Exit:* Home is populated from real stats; search under 100 ms at 20k tracks; playlists survive rescans and file moves.

**Phase 5: Audio quality features.** Crossfade and fades, equalizer and presets, bass boost/loudness, ReplayGain, skip-silence, mono/balance, long-audio position memory; audio settings UI.
*Exit:* each effect verified on a device; no glitches across a 30-track gapless/crossfade run.

**Phase 6: Integrations and library tools.** Home-screen widgets, app shortcuts, duplicate finder, delete/hide flows, backup/restore, settings polish.
*Exit:* backup then restore on a fresh install reproduces playlists, favorites and stats.

**Phase 7: Hardening and release.** Profiling and jank pass; memory and battery review; edge-case matrix (corrupt files, missing SD card, permission revoked mid-play, low storage, process death); accessibility audit; localization pass; adaptive and themed icon, native splash, edge-to-edge; R8; release AAB; privacy check of the merged manifest; README and user guide; size report.
*Exit:* every P0 and P1 requirement is traced to a test or manual check in `docs/QA_MATRIX.md`.

**Phase 8: Audiophile & Sound Engine Standouts.** Per-output-device audio profiles (auto-switching EQ, volume, and crossfade based on Bluetooth vs wired vs speaker device); real-time audio visualizer (60 FPS spectrum, analog VU meters) & waveform seekbar; independent musical pitch transposition (-12 to +12 semitones) and tempo controls.
*Exit:* audio profile switches automatically on device change; waveform seekbar and visualizer render at 60 FPS; pitch shifts without changing playback speed.

**Phase 9: Library Power-Tools, CUE & Lyrics Studio.** Integrated in-app tag and artwork editor (ID3v2, Vorbis, MP4) compliant with Android 11+ `MediaStore.createWriteRequest`; CUE sheet parser & virtual track splitting for lossless rip albums; interactive synchronized LRC lyrics editor (tap-to-stamp timestamp recording).
*Exit:* tag edits persist on disk and update DB; CUE album displays separate tracks and seeks seamlessly; custom synced LRC saves and displays.

**Phase 10: Smart Listening, Offline Wrapped & Ecosystem.** 100% offline "Wrapped" recap with shareable local canvas image cards; offline "Track Radio" (metadata clustering); smart sleep gestures (shake-to-extend, flip-to-pause); custom Now Playing skins (spinning vinyl, retro cassette); Android Auto dashboard browse integration (`MediaBrowserServiceCompat`); expanded Home Screen widget suite (large 4×2 album art controller, 2×1 minimalist pill, and scrollable favorites/recents shelf widget).
*Exit:* Wrapped card exports locally without network; radio queue clusters tracks; shake gesture extends sleep timer; Android Auto media tree browsable; multiple widget styles render and control playback seamlessly.

**Phase 11: iOS parity (only if I ask).** Document-picker import into the app sandbox (no MediaStore), AVAudioSession and background modes, Now Playing info and remote commands, documented platform differences (EQ and others).

## 12. Start

Begin now. (1) Persist the docs per rule 2.1. (2) Execute **Phase 0** per the protocol: plan first, then build, verify and stop. Do not start Phase 1 until I send `GO 1`.
