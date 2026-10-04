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

### 4. Interactive In-App Testing (Phase 0 & Phase 1)
- **Permission Flow & Onboarding:** First launch presents the private & offline rationale screen. Dynamically requests `READ_MEDIA_AUDIO` on Android 13+ (API 33+) or `READ_EXTERNAL_STORAGE` on API <=32, with a settings deep-link fallback on permanent denial.
- **MediaStore Native Scanner:** Scans audio files via background platform channel with transactional batching into Drift SQLite, real-time progress indicators, and incremental `ContentObserver` updates.
- **Pure-Dart TagReader:** Reads ID3v1, ID3v2.2-2.4 (TIT2, TPE1, TALB, USLT, APIC, ReplayGain), FLAC Vorbis comments + picture blocks, MP4/M4A atoms, and OGG with automatic fallback heuristics.
- **Browse Tabs:** Switch between **Songs**, **Albums**, **Artists**, **Genres**, and **Folders** tabs in Library.
- **A-Z Sticky Scrubber:** Tap or slide the right-edge letter alphabet to instantaneously scroll large libraries.
- **Detail Screens:** Collapsing headers with dynamic Material 3 palettes for Albums and circular headers for Artists with albums shelves.
- **Mini-Player & Theme Modes:** Floating mini-player above navigation bar; Dark, Light, and pure black AMOLED themes.
- **Audio Synthesis Tool:** Run `dart tool/seed_music.dart` to synthesize real tagged test tracks (MP3, FLAC, M4A, OGG) with sidecar artwork and push them directly to Android devices via ADB.
