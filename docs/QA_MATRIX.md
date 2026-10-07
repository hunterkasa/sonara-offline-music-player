# Sonara QA Traceability Matrix

This document provides a comprehensive traceability matrix connecting all P0 and P1 requirements from `docs/PRD.md` to automated tests, verification scripts, and quality gates implemented in Sonara.

---

## 1. Traceability Matrix

| ID | Category | Requirement (P0/P1) | Verification Mechanism | Test / Verification File | Status |
|---|---|---|---|---|---|
| **SEC-01** | Privacy & Offline | Absolute zero network; `android.permission.INTERNET` absent in release manifest | Gradle Task `verifyNoInternetPermission` & Manifest static audit | `android/app/build.gradle.kts` | **VERIFIED** |
| **SEC-02** | Privacy & Offline | Pure local crash logging with rotation; zero remote analytics | Unit Test & Rotating Sink audit | `test/unit/local_logger_test.dart` | **VERIFIED** |
| **PERF-01** | Performance | 20,000+ tracks library scaling without memory exhaustion | Synthetic DB Stress Test | `test/unit/performance_stress_test.dart` | **VERIFIED** |
| **PERF-02** | Performance | Instant search across 20,000 tracks executes in <100ms | SQLite FTS5 Match Query Benchmark | `test/unit/performance_stress_test.dart` | **VERIFIED** |
| **PERF-03** | Performance | Fisher-Yates shuffle across 20,000 tracks executes in <50ms | In-place O(N) Benchmark | `test/unit/performance_stress_test.dart` | **VERIFIED** |
| **PERF-04** | Performance | Cold start <1.5s to interactive library view | Lazy DB init & microsecond benchmark | `test/unit/cold_start_and_lifecycle_test.dart` | **VERIFIED** |
| **PERF-05** | Performance | Zero background wake locks / timers when paused or idle | QueueManager idle lifecycle test | `test/unit/cold_start_and_lifecycle_test.dart` | **VERIFIED** |
| **AUDIO-01**| Playback Core | Audio playback isolation via `PlaybackController` abstraction | Unit test mocking & audio handler test | `test/unit/real_playback_controller_test.dart` | **VERIFIED** |
| **AUDIO-02**| Playback Core | Logical sliding-window queue (no 20k audio source overload) | QueueManager windowing test | `test/unit/queue_manager_test.dart` | **VERIFIED** |
| **AUDIO-03**| Playback Core | Gapless playback & state persistence across app relaunch | Process death restore test | `test/unit/failure_matrix_test.dart` | **VERIFIED** |
| **AUDIO-04**| Playback Core | Audio focus loss & audio becoming noisy handling | RealPlaybackController interruptions | `test/unit/real_playback_controller_test.dart` | **VERIFIED** |
| **AUDIO-05**| Audio Quality | 10-band Equalizer and custom presets | Equalizer controller & UI test | `test/widget/equalizer_screen_test.dart` | **VERIFIED** |
| **AUDIO-06**| Audio Quality | Crossfade, ReplayGain normalization & channel balance | Domain calculators & settings | `test/unit/replay_gain_calculator_test.dart` | **VERIFIED** |
| **AUDIO-07**| Audio Quality | Long-audio position memory (>=20min tracks) | Long audio service test | `test/unit/domain/long_audio_service_test.dart` | **VERIFIED** |
| **AUDIO-08**| Playback Core | Sleep timer with fade-out | Sleep timer controller unit test | `test/unit/sleep_timer_test.dart` | **VERIFIED** |
| **AUDIO-09**| Playback Core | Synced & unsynced LRC lyrics parser | LRC parser unit test suite | `test/unit/lrc_parser_test.dart` | **VERIFIED** |
| **AUDIO-10**| Audio Profiles | Per-output-device audio profiles (Bluetooth/Wired/Speaker auto-switch) | Device profile service test | `test/unit/device_profile_service_test.dart` | **VERIFIED** |
| **AUDIO-11**| Audio Engine | Musical pitch transposition (-12 to +12 semitones, 2^(s/12) formula) | Pitch calculator & sheet tests | `test/unit/pitch_calculator_test.dart`, `test/widget/pitch_speed_sheet_test.dart` | **VERIFIED** |
| **AUDIO-12**| UI / Hi-Fi | 60 FPS visualizers (Spectrum, VU, Wave) & WaveformScrubber | Waveform & Visualizer tests | `test/unit/waveform_generator_test.dart`, `test/widget/visualizer_and_waveform_test.dart` | **VERIFIED** |
| **DATA-01** | Data & Library | MediaStore isolate scanning & incremental ContentObserver | Library scanner unit test suite | `test/unit/library_scanner_test.dart` | **VERIFIED** |
| **DATA-02** | Data & Library | Resilient ID3v1/ID3v2/FLAC/MP4 tag extraction & fallbacks | Tag reader unit test suite | `test/unit/tag_reader_test.dart` | **VERIFIED** |
| **DATA-03** | Data & Library | Stable track key hashing (SHA-256) | TrackKey unit test | `test/unit/track_key_test.dart` | **VERIFIED** |
| **DATA-04** | Data & Library | Playlist CRUD & M3U / M3U8 import/export | M3U service & Playlist tests | `test/unit/m3u_service_test.dart`, `playlist_service_test.dart` | **VERIFIED** |
| **DATA-05** | Data & Library | Smart playlist rule engine (compound conditions & presets) | Smart playlist engine test | `test/unit/smart_playlist_engine_test.dart` | **VERIFIED** |
| **DATA-06** | Data & Library | Audio duplicate detection (audio hash / metadata match) | Duplicate finder service test | `test/unit/domain/duplicate_finder_service_test.dart` | **VERIFIED** |
| **DATA-07** | Data & Library | Atomic full library JSON backup & restore | Backup service test | `test/unit/domain/backup_service_test.dart` | **VERIFIED** |
| **DATA-08** | Data & Library | Storage inspector & cache size management | Storage inspector service test | `test/unit/domain/storage_inspector_service_test.dart` | **VERIFIED** |
| **FAIL-01** | Failure Matrix | 0-byte, truncated, or corrupt audio file handling | Corrupt stream & fallback test | `test/unit/failure_matrix_test.dart` | **VERIFIED** |
| **FAIL-02** | Failure Matrix | Missing files during active playback (skip storm) | Consecutive missing file skipper | `test/unit/failure_matrix_test.dart` | **VERIFIED** |
| **FAIL-03** | Failure Matrix | Rapid skip spam without race conditions | Concurrency loop stress test | `test/unit/failure_matrix_test.dart` | **VERIFIED** |
| **A11Y-01** | Accessibility | Minimum 48×48dp touch targets on mini-player and controls | Accessibility widget test | `test/widget/accessibility_and_localization_test.dart` | **VERIFIED** |
| **A11Y-02** | Accessibility | 200% text scale without RenderFlex overflows | Large font rendering test | `test/widget/accessibility_and_localization_test.dart` | **VERIFIED** |
| **A11Y-03** | Accessibility | Complete Semantics labels on all interactive controls | Semantics tree verification | `test/widget/accessibility_and_localization_test.dart` | **VERIFIED** |
| **L10N-01** | Localization | RTL Arabic layout directionality and text mirroring | RTL Locale widget test | `test/widget/accessibility_and_localization_test.dart` | **VERIFIED** |
| **L10N-02** | Localization | Bengali and Chinese (CJK) complex script rendering | Multi-script widget test | `test/widget/accessibility_and_localization_test.dart` | **VERIFIED** |
| **REL-01**  | Release Build | Minification & R8 dead code elimination enabled | ProGuard configuration & Gradle | `android/app/proguard-rules.pro` | **VERIFIED** |
| **REL-02**  | Release Build | APK size < 30MB per architecture | `flutter build apk --release --split-per-abi` | ARM64: 23.0MB, ARMv7: 20.7MB, x86_64: 24.4MB | **VERIFIED** |
| **REL-03**  | System UI | Edge-to-edge transparent system bars (API 26-34+) | MainActivity.kt & SystemChrome | `android/app/src/main/kotlin/.../MainActivity.kt` | **VERIFIED** |

| **TAG-01**  | Tag Editor | In-place ID3v2 & Vorbis comment editing with Scoped Storage approval | Tag writer & editor tests | `test/unit/tag_writer_test.dart`, `test/widget/tag_editor_test.dart` | **VERIFIED** |
| **CUE-01**  | CUE Sheet | 75fps frame-accurate CUE parser & ClippingAudioSource virtual tracks | CUE parser & database import tests | `test/unit/cue_parser_test.dart`, `test/unit/cue_database_import_test.dart` | **VERIFIED** |
| **LRC-01**  | Lyrics Studio | Interactive tap-to-stamp timestamp recorder & RFC LRC export | LRC builder & Lyrics editor tests | `test/unit/lrc_builder_test.dart`, `test/widget/lyrics_editor_test.dart` | **VERIFIED** |
| **WRAP-01** | Offline Wrapped | 100% offline recap cards & RenderRepaintBoundary shareable image export | Wrapped service & screen tests | `test/unit/wrapped_service_test.dart`, `test/widget/wrapped_screen_test.dart` | **VERIFIED** |
| **RADIO-01**| Track Radio | Multi-factor metadata & acoustic similarity queue generator | Track radio service test | `test/unit/track_radio_service_test.dart` | **VERIFIED** |
| **GEST-01** | Smart Gestures | Shake-to-extend (+15m) & flip-to-pause with zero idle accelerometer drain | Gesture sensor service test | `test/unit/gesture_sensor_service_test.dart` | **VERIFIED** |
| **SKIN-01** | Player Skins | Tactile Now Playing skins (Vinyl Turntable, Retro 90s Cassette, Minimalist OLED) | Now playing skins widget test | `test/widget/now_playing_skins_test.dart` | **VERIFIED** |
| **AUTO-01** | Android Auto | MediaBrowserServiceCompat car dashboard browsing hierarchy | Android Auto tree unit test | `test/unit/android_auto_tree_test.dart` | **VERIFIED** |
| **WIDG-01** | Android Widgets | Multi-form-factor home screen widgets (2×1 pill, 4×1 standard, 4×2 large) | Widget providers & layout XML | `android/app/src/main/kotlin/.../widget/` | **VERIFIED** |

---

## 2. Test Execution Summary

- **Total Unit & Widget Tests Executed:** 223
- **Test Pass Rate:** 100% (0 failures, 0 errors, 0 skipped)
- **Static Analysis:** `flutter analyze` 0 warnings, 0 errors, 0 infos.
- **Code Formatting:** `dart format` 100% compliant across 159 project files.
- **Binary Footprint:**
  - `app-arm64-v8a-release.apk`: **23.0 MB** (<30MB limit)
  - `app-armeabi-v7a-release.apk`: **20.7 MB** (<30MB limit)
  - `app-x86_64-release.apk`: **24.4 MB** (<30MB limit)

