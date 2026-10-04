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

### 4. Interactive In-App Testing (Phase 0 Features)
- **Navigation Shell:** Switch between the 3 main tabs: **Home**, **Search**, and **Library**.
- **Mini-Player:** Located persistently at the bottom above the tab bar. Tap the play/pause button or the track title to open the **Now Playing** sheet.
- **Now Playing Sheet:** Supports drag handle swipe down, back gesture interception (`PopScope`), scrubber, and playback control toggles.
- **Theme Modes:** Navigate to **Settings** (top right on Home) and switch between **Dark**, **AMOLED** (pure black `#000000`), and **Light** themes.
- **20,000 Tracks Stress Test:** In **Settings**, tap **"Seed 20,000 Synthetic Tracks"**. Drift SQLite inserts 20,000 indexed records via transactional batching in ~2.5 seconds. Switch to the **Library** tab to inspect 60 FPS scrolling over 20,000 items with fixed extents.
- **Audio Synthesis Tool:** In `tool/seed_music.dart`, FFmpeg generates test sine-wave audio tracks (MP3, FLAC, M4A, OGG) and pushes them to `/storage/emulated/0/Music/SonaraTest/`.
