# Sonara: Critical Bugs & Deficiencies Implementation Checklist

**Task Objective:** Fix all 14 critical bugs and architectural deficiencies identified in Section 1 of the codebase audit.  
**Platform Invariants:** Flutter/Dart, minSdk 26, targetSdk 34+, 0 network, Drift SQLite, strict typing, 100% passing tests with 0 `flutter analyze` warnings.

---

## Batch 1: Database Integrity & Query Robustness

- [x] **Bug 1: SQLite Variable Limit Crash on Large Queues & Playlists (`getTracksByKeys`)**
  - **Files:**
    - [`lib/data/db/app_database.dart`](file:///e:/Android%20Music%20Player/lib/data/db/app_database.dart#L138-L150)
    - [`lib/audio/playback_controller.dart`](file:///e:/Android%20Music%20Player/lib/audio/playback_controller.dart#L395)
  - **Root Cause:**
    `t.trackKey.isIn(keys)` generates a raw SQL statement `WHERE track_key IN (?, ?, ...)`. When `keys.length > 999` (e.g., "Shuffle All" with 5,000 songs or large playlists), SQLite throws `SqliteException: too many SQL variables` (code 20).
  - **Step-by-Step Implementation:**
    1. In `app_database.dart:getTracksByKeys(List<String> keys)`:
       - Chunk `keys` into sublists of size 250 (well below 999 limit).
       - Query each batch using `(select(tracks)..where((t) => t.trackKey.isIn(chunk))).get()`.
       - Aggregate all fetched `Track` entities into a map `Map<String, Track>`.
       - Reconstruct the output `List<Track>` in the exact order of the original `keys` argument.
  - **Regression Test:**
    - `test/unit/database_test.dart`: Call `db.getTracksByKeys(...)` with 1,500 distinct synthetic keys and assert that all 1,500 are returned in preserved order without `SqliteException`.

---

- [x] **Bug 6: Soundtrack & Compilation Albums Splitting into Separate 1-Track Albums**
  - **Files:**
    - [`lib/data/db/app_database.dart`](file:///e:/Android%20Music%20Player/lib/data/db/app_database.dart#L813-L844)
    - [`lib/domain/services/library_scanner.dart`](file:///e:/Android%20Music%20Player/lib/domain/services/library_scanner.dart#L358-L367)
  - **Root Cause:**
    In `library_scanner.dart`, the scanner passed `artistId` (the track's specific artist) to `getOrCreateAlbum(title: albumTitle, artistId: artistId)` instead of `albumArtistId`. Furthermore, `getOrCreateAlbum` enforces `a.title.equals(title) & a.albumArtistId.equals(artistId)`. For compilations (e.g. "Guardians of the Galaxy", "Pulp Fiction"), every track has a different artist, splitting the album into 20 separate 1-track albums.
  - **Step-by-Step Implementation:**
    1. In `library_scanner.dart`:
       - Resolve album artist name: Check `metadata.albumArtist`. If non-empty, use it. If empty and track is marked compilation or chunk/folder tracks share album title with multiple artists, resolve to `"Various Artists"`. If single artist album, use `artistName`.
       - Call `getOrCreateArtist(albumArtistName)` to obtain `albumArtistId`.
       - Pass `albumArtistId` to `getOrCreateAlbum(title: albumTitle, artistId: albumArtistId)`.
    2. In `app_database.dart`:
       - In `getOrCreateAlbum`, if an existing album matches `title` and its artist is `"Various Artists"`, reuse it. If a track belongs to an existing album but has a different artist, update or link under compilation album artist.
  - **Regression Test:**
    - `test/unit/library_scanner_test.dart`: Scan 5 tracks having the same album title "Awesome Mix Vol. 1" but 5 distinct track artists ("Blue Swede", "David Bowie", etc.). Assert that exactly 1 `Album` row is created in the database and all 5 tracks reference its `albumId`.

---

- [x] **Bug 8: FTS5 Search Query Crash on Special Characters (`-`, `(`, `)`, `:`, `*`)**
  - **Files:**
    - [`lib/data/db/app_database.dart`](file:///e:/Android%20Music%20Player/lib/data/db/app_database.dart#L97-L105)
  - **Root Cause:**
    `searchTrackKeysFts` builds the query `variables: [Variable.withString('$cleanTerm*')]`. In SQLite FTS5, `-` is a negation/column operator, `(` and `)` are grouping operators, and `:` is column matching. Unescaped inputs like `queen (live)`, `ac/dc`, or `love - hate` produce `SqliteException: fts5: syntax error`.
  - **Step-by-Step Implementation:**
    1. In `app_database.dart:searchTrackKeysFts`:
       - Tokenize input string by whitespace `RegExp(r'\s+')`.
       - Strip quotes and FTS reserved operator characters from each token.
       - If tokens are empty, return `[]`.
       - Enclose each sanitized token in double quotes with prefix wildcards: `'"$token"*'`.
       - Join tokens with space for AND matching: `tokens.map((t) => '"$t"*').join(' ')`.
       - Wrap execution in a `try/catch` fallback returning `[]` on query syntax anomalies.
  - **Regression Test:**
    - `test/unit/database_test.dart`: Query FTS with search terms: `queen (live)`, `ac/dc`, `foo - bar`, `***`, `"unclosed quote`, `artist:name`. Assert 0 exceptions and successful retrieval.

---

- [x] **Bug 9: `PlaylistTracks` Composite Primary Key Blocks Duplicate Songs in Playlists**
  - **Files:**
    - [`lib/data/db/tables.dart`](file:///e:/Android%20Music%20Player/lib/data/db/tables.dart#L90-L98)
    - [`lib/data/db/app_database.dart`](file:///e:/Android%20Music%20Player/lib/data/db/app_database.dart#L390-L470)
    - [`lib/domain/services/playlist_service.dart`](file:///e:/Android%20Music%20Player/lib/domain/services/playlist_service.dart#L285-L298)
  - **Root Cause:**
    `PlaylistTracks.primaryKey` is currently `{playlistId, trackKey}`. If a user adds the same track twice to a playlist (e.g. at position 1 and position 8), SQLite throws a PRIMARY KEY constraint violation (`UNIQUE constraint failed`), crashing or discarding the duplicate.
  - **Step-by-Step Implementation:**
    1. In `lib/data/db/tables.dart`:
       - Add auto-incrementing integer `id`: `IntColumn get id => integer().autoIncrement()();`.
       - Remove `{playlistId, trackKey}` primary key override (the auto-increment `id` becomes primary key).
       - Keep `playlistId`, `trackKey`, `position`, `addedAt` columns.
    2. Run Drift code generator:
       `dart run build_runner build --delete-conflicting-outputs`.
    3. In `app_database.dart`:
       - In `addTracksToPlaylist`: Insert each item as a distinct row with its unique `position`.
       - In `reorderPlaylistTracks`: Update positions safely using row `id` or sequential rewrite.
       - In `removeTrackFromPlaylist`: Support removing by `id` or first occurrence of `trackKey` and compact positions.
  - **Regression Test:**
    - `test/unit/playlist_service_test.dart`: Add track A, track B, and track A again to a playlist. Assert playlist length is 3, with track A at index 0 and index 2. Reorder them and verify persistence.

---

## Batch 2: Audio Engine & Native Android Sync

- [x] **Bug 2: Gapless Playback Stutter & Reset in Sliding Window Progression**
  - **Files:**
    - [`lib/audio/sonara_audio_handler.dart`](file:///e:/Android%20Music%20Player/lib/audio/sonara_audio_handler.dart#L182-L189, #L362-L367)
  - **Root Cause:**
    When `_player.currentIndexStream` emits index 1 (meaning the player smoothly transitioned to the second track in the sliding window), the handler calls `queueManager.advanceToNext()` and then calls `_reloadSlidingWindow(resumePlaying: _player.playing)`. `_reloadSlidingWindow` instantiates a brand new `ConcatenatingAudioSource` and invokes `_player.setAudioSource(..., initialIndex: 0)`, which interrupts ExoPlayer, clears the buffer, re-loads from 0ms, and causes an audible glitch/stutter.
  - **Step-by-Step Implementation:**
    1. In `sonara_audio_handler.dart`:
       - Introduce in-place sliding window maintenance method: `Future<void> _advanceSlidingWindowInPlace()`.
       - Check if `_audioSource` is active and has elements:
         - Call `await _audioSource.removeAt(0)` without stopping playback. This shifts the current track from index 1 to index 0 smoothly inside ExoPlayer without re-buffering.
         - Inspect `queueManager.getSlidingWindow()`. If the sliding window contains new upcoming tracks beyond the current `_audioSource.length`, build the `AudioSource` for the new upcoming track and call `await _audioSource.add(newChild)`.
       - In `currentIndexStream.listen((index))`:
         - When `index > 0`:
           - Advance queue: `queueManager.advanceToNext()`.
           - Call `await _advanceSlidingWindowInPlace()`.
           - Do NOT invoke `setAudioSource()`.
  - **Regression Test:**
    - `test/unit/real_playback_controller_test.dart` / audio handler test: Simulate track completion transition to index 1 and verify `_audioSource` length is maintained, `removeAt(0)` is executed, and player state does not reset to stopped or initial source.

---

- [x] **Bug 3: RemoteViews IPC Thrashing (Battery Drain) from Snapshot Position Ticks**
  - **Files:**
    - [`lib/core/services/widget_service.dart`](file:///e:/Android%20Music%20Player/lib/core/services/widget_service.dart#L18-L25)
    - [`android/app/src/main/kotlin/com/example/sonara/sonara/SonaraWidgetProvider.kt`](file:///e:/Android%20Music%20Player/android/app/src/main/kotlin/com/example/sonara/sonara/SonaraWidgetProvider.kt)
  - **Root Cause:**
    `playbackController.snapshotStream` emits position updates every 200ms. In `widget_service.dart`, every single snapshot triggers `_channel.invokeMethod('updateWidget', ...)`. This sends 5 IPC transactions per second to the Android System Server `AppWidgetManager`, causing high CPU wakeups and rapid battery depletion.
  - **Step-by-Step Implementation:**
    1. In `widget_service.dart`:
       - Add state tracking fields: `String? _lastTitle`, `String? _lastArtist`, `bool? _lastIsPlaying`.
       - In `startListening()`:
         - Check if `snapshot.title == _lastTitle && snapshot.artist == _lastArtist && snapshot.isPlaying == _lastIsPlaying`.
         - If identical, ignore the tick (skip IPC).
         - If any value changed, cache the new values and invoke `updateWidget(...)`.
  - **Regression Test:**
    - `test/unit/cold_start_and_lifecycle_test.dart` or widget service unit test: Emit 20 snapshots with changing position but identical title, artist, and isPlaying. Verify `updateWidget` is called exactly once.

---

- [x] **Bug 4: Accelerometer Hardware Sensor Leak in Background**
  - **Files:**
    - [`android/app/src/main/kotlin/com/example/sonara/sonara/MainActivity.kt`](file:///e:/Android%20Music%20Player/android/app/src/main/kotlin/com/example/sonara/sonara/MainActivity.kt#L160-L216, #L365-L368)
  - **Root Cause:**
    `sensorManager.registerListener` registers hardware accelerometer polling at 50 Hz. When the user exits the app or locks the screen, `onPause()` / `onStop()` does not unregister the sensor. Furthermore, `onDestroy()` only cleans up `unregisterMediaStoreObserver()` and forgets `stopSensorListening()`, leaking the sensor listener and draining battery continuously.
  - **Step-by-Step Implementation:**
    1. In `MainActivity.kt`:
       - Add lifecycle overrides:
         - `override fun onPause()`: If sensor listening is active, unregister `sensorListener` with `sensorManager?.unregisterListener(it)` to eliminate background battery drain.
         - `override fun onResume()`: If `sensorSink != null`, re-register `sensorListener`.
         - `override fun onDestroy()`: Ensure `stopSensorListening()` and `unregisterMediaStoreObserver()` are both called.
  - **Regression Test:**
    - Kotlin code inspection & Android lifecycle verification: Validate that backgrounding pauses the accelerometer and `onDestroy` frees all references.

---

## Batch 3: Scoped Storage, Permissions & Metadata Parsing

- [x] **Bug 5: Scoped Storage File Deletion & Tag Writing Failures (Android 11-15)**
  - **Files:**
    - [`lib/domain/services/duplicate_finder_service.dart`](file:///e:/Android%20Music%20Player/lib/domain/services/duplicate_finder_service.dart#L101-L113)
    - [`lib/data/sources/tag_writer.dart`](file:///e:/Android%20Music%20Player/lib/data/sources/tag_writer.dart#L54-L115)
    - [`lib/core/services/scoped_storage_service.dart`](file:///e:/Android%20Music%20Player/lib/core/services/scoped_storage_service.dart)
    - [`android/app/src/main/kotlin/com/example/sonara/sonara/MainActivity.kt`](file:///e:/Android%20Music%20Player/android/app/src/main/kotlin/com/example/sonara/sonara/MainActivity.kt#L103-L126)
  - **Root Cause:**
    On Android 11+ (API 30+), direct POSIX file operations like `File(path).delete()` or creating `${file.path}.tmp` in shared music directories fail with `OS Error: Permission denied, errno = 13`. Shared storage requires `MediaStore.createDeleteRequest()` and writing tags via content resolver or temporary app-private directory.
  - **Step-by-Step Implementation:**
    1. In `MainActivity.kt`:
       - Implement `requestDeletePermission` method channel handling using `MediaStore.createDeleteRequest(contentResolver, listOf(uri))` on API 30+, and fallback to `contentResolver.delete(uri, null, null)` on API < 30.
    2. In `scoped_storage_service.dart`:
       - Add `Future<bool> requestDeletePermission(String contentUri)`.
    3. In `duplicate_finder_service.dart`:
       - When deleting a track file, check `track.uri`. If present, request deletion via `scopedStorageService.requestDeletePermission(track.uri)`. If that succeeds or is not on Android, proceed to remove from DB.
    4. In `tag_writer.dart`:
       - Write the temporary file into `Directory.systemTemp` (app-private storage, always writable) rather than alongside the target file on shared storage.
       - Stream rewritten bytes back into the target file or open write stream.
  - **Regression Test:**
    - `test/unit/domain/duplicate_finder_service_test.dart`: Verify `deleteTrack` invokes `requestDeletePermission` when URI is present.
    - `test/unit/tag_writer_test.dart`: Verify tag writer successfully writes using temp directory without leaving orphan `.tmp` files.

---

- [x] **Bug 10: ID3v2.3 Non-Standard Text Encoding (UTF-8 Illegal in v2.3)**
  - **Files:**
    - [`lib/data/sources/tag_writer.dart`](file:///e:/Android%20Music%20Player/lib/data/sources/tag_writer.dart#L125-L146, #L192)
  - **Root Cause:**
    `_buildId3v2Tag` declares ID3v2.3 in the header (`0x03` at byte 3), but writes text frames with encoding flag `0x03` (UTF-8). In the ID3v2.3 standard, `0x03` does not exist (valid values are only `0x00` Latin-1 and `0x01` UTF-16 with BOM). UTF-8 was introduced in ID3v2.4. External media players either drop these tags or show corrupted text.
  - **Step-by-Step Implementation:**
    1. In `tag_writer.dart`:
       - For text strings containing only ASCII/ISO-8859-1 characters: Use encoding byte `0x00` (ISO-8859-1) and `latin1.encode(text)`.
       - For text strings containing Unicode/multilingual characters: Use encoding byte `0x01` (UTF-16 with BOM `[0xFF, 0xFE]`) and encode characters as little-endian 16-bit code units.
       - Alternatively, update ID3 header to ID3v2.4 (`0x04`) with synchsafe integer sizing. UTF-16 BOM with ID3v2.3 provides universal compatibility with car stereos and desktop players.
  - **Regression Test:**
    - `test/unit/tag_writer_test.dart`: Write metadata with unicode characters (e.g., "日本語", "Beyoncé", "Café"). Read it back with `TagReader` and verify zero corruption or mojibake.

---

- [x] **Bug 11: APIC / USLT Descriptor Truncation on UTF-16 in TagReader**
  - **Files:**
    - [`lib/data/sources/tag_reader.dart`](file:///e:/Android%20Music%20Player/lib/data/sources/tag_reader.dart#L567, #L597)
  - **Root Cause:**
    In `_decodeUslt` and `_decodeApic`, the code searches for the end of the descriptor using `while (offset < bytes.length && bytes[offset] != 0) { offset++; }`. When the encoding is UTF-16 (`encoding == 1` or `2`), null terminators are 2 bytes (`0x00, 0x00`), and every ASCII character contains a zero byte (`0x00`). Checking a single zero byte immediately truncates the descriptor on the first ASCII character, corrupting artwork offsets and lyrics extraction.
  - **Step-by-Step Implementation:**
    1. In `tag_reader.dart:_decodeUslt`:
       - If `encoding == 1 || encoding == 2`: Scan for two consecutive zero bytes on 2-byte alignment (`bytes[offset] == 0 && bytes[offset + 1] == 0`), then advance `offset += 2`.
       - Decode lyrics according to the `encoding` flag (Latin-1, UTF-16LE, UTF-16BE, UTF-8).
    2. In `tag_reader.dart:_decodeApic`:
       - For the description field: If `encoding == 1 || encoding == 2`, search for 2-byte aligned `0x00, 0x00` null terminator before extracting image payload bytes.
  - **Regression Test:**
    - `test/unit/tag_reader_test.dart`: Synthesize an APIC frame and USLT frame encoded in UTF-16 with descriptor "Cover Art (Front)". Assert that the description terminates cleanly and full image/lyrics payload is extracted intact.

---

- [x] **Bug 14: Missing `POST_NOTIFICATIONS` Permission Handling on Android 13+**
  - **Files:**
    - [`lib/core/services/permission_service.dart`](file:///e:/Android%20Music%20Player/lib/core/services/permission_service.dart#L21-L32)
  - **Root Cause:**
    `SystemPermissionService` only requests `Permission.audio` on SDK >= 33, omitting `Permission.notification`. On Android 13+, if notification permission is not granted, foreground playback controls in the notification tray and lock screen MediaSession controls are blocked by Android.
  - **Step-by-Step Implementation:**
    1. In `permission_service.dart`:
       - Add `Future<bool> checkNotificationPermission()` and `Future<bool> requestNotificationPermission()`.
       - In `requestAudioPermission()`: When on Android and SDK >= 33, also prompt for `Permission.notification.request()`.
  - **Regression Test:**
    - `test/unit/cold_start_and_lifecycle_test.dart`: Verify notification permission check/request logic on simulated SDK 33.

---

## Batch 4: UI Resilience & Smart Playlist Logic

- [x] **Bug 7: Duplicate Key Assertion Crashes in Queue & Playlists**
  - **Files:**
    - [`lib/features/queue/queue_sheet.dart`](file:///e:/Android%20Music%20Player/lib/features/queue/queue_sheet.dart#L247)
    - [`lib/features/playlist/playlist_detail_screen.dart`](file:///e:/Android%20Music%20Player/lib/features/playlist/playlist_detail_screen.dart#L535)
  - **Root Cause:**
    In `queue_sheet.dart`, `Dismissible` uses `key: ValueKey(track.trackKey)`. In `playlist_detail_screen.dart`, `SliverReorderableList` uses `key: ValueKey('playlist_${playlist!.id}_${track.trackKey}')`. If a song exists more than once in the queue or playlist, Flutter crashes with `A Key was used multiple times in a widget tree`.
  - **Step-by-Step Implementation:**
    1. In `queue_sheet.dart`:
       - Update key to compound key: `key: ValueKey('${track.trackKey}_$index')`.
    2. In `playlist_detail_screen.dart`:
       - Update key to compound key: `key: ValueKey('playlist_${playlist.id}_${track.trackKey}_$index')`.
  - **Regression Test:**
    - `test/widget/queue_sheet_test.dart`: Render a queue containing two instances of the exact same track. Verify the sheet renders without assertion errors.
    - `test/widget/playlist_flow_test.dart`: Render playlist detail with duplicate songs and reorder items without crash.

---

- [x] **Bug 12: Smart Playlist Genre Filter Hardcoded `return true` No-Op**
  - **Files:**
    - [`lib/domain/services/smart_playlist_engine.dart`](file:///e:/Android%20Music%20Player/lib/domain/services/smart_playlist_engine.dart#L63-L64, #L165-L200)
  - **Root Cause:**
    In `SmartRule.evaluate`, `case SmartField.genre: return true;` was hardcoded as a no-op placeholder. Consequently, any smart playlist filtering by Genre (e.g. "Genre is Rock") matches every single song in the user's library.
  - **Step-by-Step Implementation:**
    1. In `smart_playlist_engine.dart`:
       - Update `evaluate(Track track, {String? artistName, String? albumTitle, List<String> genres = const []})`.
       - For `SmartField.genre`:
         - Test `genres`: If `operator == SmartOperator.equals` or `contains`, return `genres.any((g) => _evaluateString(g, operator, value.toString()))`.
         - If `operator == SmartOperator.notEquals` or `notContains`, return `!genres.any((g) => ...)`.
       - In `SmartPlaylistEngine.evaluate(SmartRuleGroup group)`:
         - Fetch `final allGenresMap = await _db.getAllTrackGenresMap();` once before the loop.
         - Pass `genres: allGenresMap[track.id] ?? []` to `rule.evaluate`.
  - **Regression Test:**
    - `test/unit/smart_playlist_engine_test.dart`: Create smart rule `SmartRule(field: SmartField.genre, operator: SmartOperator.contains, value: 'Jazz')`. Evaluate against tracks with Rock, Jazz, and Classical genres. Verify only Jazz tracks match.

---

- [x] **Bug 13: RenderFlex Overflow in NowPlayingSheet on Constrained Heights**
  - **Files:**
    - [`lib/features/now_playing/now_playing_sheet.dart`](file:///e:/Android%20Music%20Player/lib/features/now_playing/now_playing_sheet.dart#L223-L760)
  - **Root Cause:**
    `NowPlayingSheet` stacks artwork (Expanded flex: 5), Title/Artist row, Waveform scrubber, Seek bar, Time row, Transport controls, and Secondary controls inside a single rigid `Column`. In landscape orientation or on screens with high system accessibility text scale (> 1.3x), content overflows by 60-120 pixels.
  - **Step-by-Step Implementation:**
    1. In `now_playing_sheet.dart`:
       - Wrap sheet body in `LayoutBuilder`.
       - When available height is constrained (`constraints.maxHeight < 560`), provide responsive proportions:
         - Allow artwork to shrink gracefully or wrap content inside a `SingleChildScrollView` with fixed controls.
         - Ensure transport buttons and slider retain touch target minimums (48x48 dp) without overflow.
  - **Regression Test:**
    - `test/widget/now_playing_sheet_test.dart`: Render `NowPlayingSheet` inside a constrained test window of `Size(400, 500)` and assert 0 overflow exceptions.

---

## Quality Gate Checklist

- [x] `dart run build_runner build --delete-conflicting-outputs` completes with zero errors.
- [x] `dart format .` passes cleanly with no diffs.
- [x] `flutter analyze` reports 0 issues.
- [x] `flutter test` passes all unit and widget tests (baseline: 266 passed).
- [x] New regression tests pass for all 14 bug fixes.
