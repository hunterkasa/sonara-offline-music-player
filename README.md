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

### 4. Interactive In-App Testing
- **Permission Flow & Onboarding (Phase 1):** First launch presents the private & offline rationale screen. Dynamically requests `READ_MEDIA_AUDIO` on Android 13+ (API 33+) or `READ_EXTERNAL_STORAGE` on API <=32, with a settings deep-link fallback on permanent denial.
- **MediaStore Native Scanner (Phase 1):** Scans audio files via background platform channel with transactional batching into Drift SQLite, real-time progress indicators, and incremental `ContentObserver` updates.
- **Pure-Dart TagReader (Phase 1):** Reads ID3v1, ID3v2.2-2.4 (TIT2, TPE1, TALB, USLT, APIC, ReplayGain), FLAC Vorbis comments + picture blocks, MP4/M4A atoms, and OGG with automatic fallback heuristics.
- **Browse Tabs & Scrubbers (Phase 1):** Switch between **Songs**, **Albums**, **Artists**, **Genres**, and **Folders** tabs in Library; sticky A-Z scrubber.
- **Audio Service & MediaSession (Phase 2):** Full background playback with `FOREGROUND_SERVICE_MEDIA_PLAYBACK` on Android 14+. Lock screen and notification shade controls with artwork, scrub bar, and Bluetooth AVRCP support.
- **Audio Focus & Headset Gestures (Phase 2):** Transient ducking on notifications, auto-pause on headphone unplug (`becomingNoisy`), resume on focus return, single/double/triple headset click handling.
- **Scalable Queue & Sliding Window (Phase 2):** Logical queue supports 20,000+ tracks without memory leaks. Sliding window feed of 5 upcoming tracks into `just_audio`.
- **Shuffle & Repeat (Phase 2):** Seeded Fisher-Yates shuffle (pins current track, exhausts before repeat) and repeat modes (off, all, one).
- **Crash & Skip Resilience (Phase 2):** Missing/unplayable files skip smoothly with user snackbars without crash loops. Accurate decoder duration reconciliation in Drift DB.
- **Process Death Restoration (Phase 2):** Drift DB persistence of logical queue, seek position, active index, and repeat/shuffle states across process kills and cold restarts.
- **External Intent Handling (Phase 2):** Plays external audio files opened from file managers via Android `ACTION_VIEW audio/*` intent.
- **Audio Synthesis Tool:** Run `dart tool/seed_music.dart` to synthesize real tagged test tracks (MP3, FLAC, M4A, OGG) with sidecar artwork and push them directly to Android devices via ADB.

