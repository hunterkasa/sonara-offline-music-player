import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sonara/core/services/permission_service.dart';
import 'package:sonara/core/utils/cue_parser.dart';
import 'package:sonara/core/utils/metadata_utils.dart';
import 'package:sonara/core/utils/track_key.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/data/sources/artwork_service.dart';
import 'package:sonara/data/sources/mediastore_source.dart';
import 'package:sonara/data/sources/tag_reader.dart';

class ScanProgress {
  final int scannedCount;
  final int totalCount;
  final String? currentTrackTitle;
  final bool isScanning;
  final String? statusMessage;

  const ScanProgress({
    this.scannedCount = 0,
    this.totalCount = 0,
    this.currentTrackTitle,
    this.isScanning = false,
    this.statusMessage,
  });

  ScanProgress copyWith({
    int? scannedCount,
    int? totalCount,
    String? currentTrackTitle,
    bool? isScanning,
    String? statusMessage,
  }) {
    return ScanProgress(
      scannedCount: scannedCount ?? this.scannedCount,
      totalCount: totalCount ?? this.totalCount,
      currentTrackTitle: currentTrackTitle ?? this.currentTrackTitle,
      isScanning: isScanning ?? this.isScanning,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class LibraryScanner extends StateNotifier<ScanProgress> {
  final AppDatabase _db;
  final MediaStoreSource _mediaStore;
  final PermissionService _permissions;
  final ArtworkService _artworkService;
  StreamSubscription<void>? _observerSubscription;
  Timer? _debounceTimer;

  LibraryScanner({
    required this._db,
    required this._mediaStore,
    required this._permissions,
    required this._artworkService,
  }) : super(const ScanProgress()) {
    _initObserver();
  }

  void _initObserver() {
    _observerSubscription = _mediaStore.observeMediaStore().listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 3), () {
        scanLibrary(isFullScan: false);
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _observerSubscription?.cancel();
    super.dispose();
  }

  Future<void> scanLibrary({bool isFullScan = false}) async {
    if (state.isScanning) return;

    final permissionStatus = await _permissions.checkAudioPermission();
    if (permissionStatus != AudioPermissionStatus.granted) {
      final reqStatus = await _permissions.requestAudioPermission();
      if (reqStatus != AudioPermissionStatus.granted) {
        state = state.copyWith(
          isScanning: false,
          statusMessage: 'Storage permission not granted',
        );
        return;
      }
    }

    state = const ScanProgress(
      isScanning: true,
      statusMessage: 'Discovering audio files...',
    );

    _nomediaCache.clear();

    try {
      var modifiedSince = 0;
      if (!isFullScan) {
        final setting = await (_db.select(
          _db.appSettings,
        )..where((s) => s.key.equals('last_scan_timestamp'))).getSingleOrNull();
        if (setting != null) {
          modifiedSince = int.tryParse(setting.valueJson) ?? 0;
        }
      }

      var minDurationMs = 30000;
      final minDurSetting = await (_db.select(
        _db.appSettings,
      )..where((s) => s.key.equals('min_duration_sec'))).getSingleOrNull();
      if (minDurSetting != null) {
        minDurationMs = (int.tryParse(minDurSetting.valueJson) ?? 30) * 1000;
      }

      // Query media items
      final rawItems = await _mediaStore.queryAudioFiles(
        minDurationMs: minDurationMs,
        modifiedSinceSec: modifiedSince,
      );

      // Query folder exclude rules
      final folderRules = await (_db.select(
        _db.libraryFolders,
      )..where((f) => f.mode.equals('exclude'))).get();
      final excludedPaths = folderRules
          .map((r) => r.path.toLowerCase())
          .toList();

      // Filter out excluded folders and .nomedia folders
      final filteredItems = rawItems.where((item) {
        final lowerPath = item.path.toLowerCase();
        for (final excluded in excludedPaths) {
          if (lowerPath.startsWith(excluded)) return false;
        }
        return !_hasNomedia(item.path);
      }).toList();

      state = state.copyWith(
        totalCount: filteredItems.length,
        statusMessage: 'Reading tags and indexing library...',
      );

      // Process in batches
      const batchSize = 100;
      var processed = 0;

      for (var i = 0; i < filteredItems.length; i += batchSize) {
        final chunk = filteredItems.sublist(
          i,
          (i + batchSize < filteredItems.length)
              ? i + batchSize
              : filteredItems.length,
        );

        await _processChunk(chunk);
        processed += chunk.length;

        state = state.copyWith(
          scannedCount: processed,
          currentTrackTitle: chunk.last.title,
        );

        // Yield UI thread between chunks to maintain 60fps responsiveness and avoid thermal spiking
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }

      // Reconcile deletions
      if (isFullScan) {
        try {
          final knownIds = (await _mediaStore.getKnownMediaIds()).toSet();
          if (knownIds.isNotEmpty) {
            final trackPairs = await _db.getMediaStoreTrackIds();
            final missingTrackIds = trackPairs
                .where((pair) => !knownIds.contains(pair.$2))
                .map((pair) => pair.$1)
                .toList();
            const updateBatch = 200;
            for (var i = 0; i < missingTrackIds.length; i += updateBatch) {
              final end = (i + updateBatch < missingTrackIds.length)
                  ? i + updateBatch
                  : missingTrackIds.length;
              final chunk = missingTrackIds.sublist(i, end);
              await (_db.update(_db.tracks)..where((t) => t.id.isIn(chunk)))
                  .write(const TracksCompanion(isMissing: Value(true)));
            }
          }
        } catch (_) {}
      }

      // Update last scan timestamp
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion(
              key: const Value('last_scan_timestamp'),
              valueJson: Value(nowSec.toString()),
            ),
          );

      state = state.copyWith(
        isScanning: false,
        scannedCount: processed,
        statusMessage: 'Library scan complete ($processed tracks)',
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Scan encountered error: $e',
      );
    }
  }

  Future<void> _processChunk(List<MediaStoreItem> items) async {
    final preparedTracks = <_PreparedTrackData>[];

    // Phase 1: Heavy file I/O & deep tag parsing running in background isolate
    final isolateResults = await compute(_extractTagsChunkIsolated, items);
    final resultsMap = {for (final r in isolateResults) r.index: r.metadata};

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      try {
        final hasValidPath = item.path.isNotEmpty && p.isAbsolute(item.path);
        final metadata =
            resultsMap[i] ??
            ParsedMetadata(
              title: MetadataUtils.resolveTitle(item.title, item.path),
              artist: MetadataUtils.resolveArtist(item.artist),
              album: MetadataUtils.resolveAlbum(item.album, item.path),
              albumArtist: MetadataUtils.resolveArtist(item.artist),
              year: item.year > 0 ? item.year : null,
              trackNumber: item.trackNumber > 0 ? item.trackNumber : null,
            );

        final title = metadata.title.isNotEmpty ? metadata.title : item.title;
        final artistName = metadata.artist.isNotEmpty
            ? metadata.artist
            : item.artist;
        final albumTitle = metadata.album.isNotEmpty
            ? metadata.album
            : item.album;
        final duration = item.durationMs;
        final size = item.sizeBytes;

        final trackKey = TrackKeyUtil.generate(
          title: title,
          artist: artistName,
          album: albumTitle,
          durationMs: duration,
          sizeBytes: size,
        );

        // Artwork caching
        String? artworkKey;
        if (metadata.embeddedArtwork != null) {
          artworkKey = ArtworkService.generateArtworkKey(
            '$albumTitle-$artistName',
          );
          await _artworkService.cacheArtworkBytes(
            artworkKey,
            metadata.embeddedArtwork!,
          );
        } else if (hasValidPath) {
          final sidecar = await _artworkService.resolveArtworkFile(
            artworkKey: null,
            filePath: item.path,
          );
          if (sidecar != null) {
            artworkKey = ArtworkService.generateArtworkKey(sidecar.path);
          }
        }

        // Check for sidecar CUE sheet
        var isCueMonolith = false;
        if (hasValidPath) {
          final withoutExt = p.withoutExtension(item.path);
          File? cueFile = File('$withoutExt.cue');
          if (!await cueFile.exists()) {
            final upperCue = File('$withoutExt.CUE');
            if (await upperCue.exists()) {
              cueFile = upperCue;
            } else {
              cueFile = null;
            }
          }

          if (cueFile != null) {
            try {
              final cueContent = await cueFile.readAsString();
              final cueSheet = CueParser.parse(
                cueContent,
                parentDuration: Duration(milliseconds: duration),
              );
              if (cueSheet.tracks.isNotEmpty) {
                await _db.importCueTracks(
                  audioPath: item.path,
                  contentUri: item.contentUri,
                  cueTracks: cueSheet.tracks,
                  artworkKey: artworkKey,
                  parentMediaStoreId: item.id,
                  parentFileSize: size,
                );
                isCueMonolith = true;
              }
            } catch (_) {}
          }
        }

        if (isCueMonolith) continue;

        final genresList = <String>{};
        for (final g in metadata.genres) {
          final trimmed = g.trim();
          if (trimmed.isNotEmpty) genresList.add(trimmed);
        }
        if (genresList.isEmpty && item.genre.trim().isNotEmpty) {
          genresList.add(item.genre.trim());
        }

        preparedTracks.add(
          _PreparedTrackData(
            item: item,
            metadata: metadata,
            trackKey: trackKey,
            title: title,
            artistName: artistName,
            albumTitle: albumTitle,
            duration: duration,
            size: size,
            artworkKey: artworkKey,
            genresList: genresList.toList(),
            hasValidPath: hasValidPath,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    if (preparedTracks.isEmpty) return;

    final albumArtistsMap = <String, Set<String>>{};
    for (final p in preparedTracks) {
      albumArtistsMap
          .putIfAbsent(p.albumTitle, () => <String>{})
          .add(p.artistName);
    }

    // Phase 2: Atomic batched database insertion in a single transaction
    await _db.transaction(() async {
      for (final pData in preparedTracks) {
        try {
          final artistId = await _db.getOrCreateArtist(pData.artistName);

          final String albumArtistName;
          if (pData.metadata.albumArtist.isNotEmpty) {
            albumArtistName = pData.metadata.albumArtist;
          } else if ((albumArtistsMap[pData.albumTitle]?.length ?? 0) > 1) {
            albumArtistName = 'Various Artists';
          } else {
            albumArtistName = pData.artistName;
          }

          final albumArtistId = await _db.getOrCreateArtist(albumArtistName);
          final albumId = await _db.getOrCreateAlbum(
            title: pData.albumTitle,
            artistId: albumArtistId,
            year:
                pData.metadata.year ??
                (pData.item.year > 0 ? pData.item.year : null),
            artworkKey: pData.artworkKey,
          );

          await _db
              .into(_db.tracks)
              .insertOnConflictUpdate(
                TracksCompanion(
                  trackKey: Value(pData.trackKey),
                  mediaStoreId: Value(pData.item.id),
                  contentUri: Value(pData.item.contentUri),
                  path: Value(pData.item.path),
                  relativeDir: Value(
                    pData.hasValidPath ? p.dirname(pData.item.path) : '',
                  ),
                  title: Value(pData.title),
                  titleSort: Value(
                    MetadataUtils.normalizeSortName(pData.title),
                  ),
                  artistId: Value(artistId),
                  albumId: Value(albumId),
                  albumArtistId: Value(albumArtistId),
                  trackNo: Value(
                    pData.metadata.trackNumber ??
                        (pData.item.trackNumber > 0
                            ? pData.item.trackNumber
                            : null),
                  ),
                  discNo: Value(pData.metadata.discNumber),
                  year: Value(
                    pData.metadata.year ??
                        (pData.item.year > 0 ? pData.item.year : null),
                  ),
                  durationMs: Value(pData.duration),
                  mime: Value(
                    pData.item.mimeType.isNotEmpty
                        ? pData.item.mimeType
                        : pData.metadata.codec,
                  ),
                  sizeBytes: Value(pData.size),
                  dateAdded: Value(pData.item.dateAdded),
                  dateModified: Value(pData.item.dateModified),
                  artworkKey: Value(pData.artworkKey),
                  replayGainTrackDb: Value(pData.metadata.replayGainTrackDb),
                  replayGainAlbumDb: Value(pData.metadata.replayGainAlbumDb),
                  hasLyrics: Value(
                    pData.metadata.lyrics != null &&
                        pData.metadata.lyrics!.isNotEmpty,
                  ),
                ),
              );

          final insertedTrack = await (_db.select(
            _db.tracks,
          )..where((t) => t.trackKey.equals(pData.trackKey))).getSingleOrNull();

          if (insertedTrack != null) {
            for (final genreName in pData.genresList) {
              final genreId = await _db.getOrCreateGenre(genreName);
              await _db
                  .into(_db.trackGenres)
                  .insertOnConflictUpdate(
                    TrackGenresCompanion(
                      trackId: Value(insertedTrack.id),
                      genreId: Value(genreId),
                    ),
                  );
            }
          }

          await _db.customStatement(
            'INSERT OR REPLACE INTO tracks_fts(track_key, title, artist, album, genre) VALUES (?, ?, ?, ?, ?)',
            [
              pData.trackKey,
              pData.title,
              pData.artistName,
              pData.albumTitle,
              pData.genresList.join(' '),
            ],
          );
        } catch (_) {
          continue;
        }
      }
    });
  }

  final Map<String, bool> _nomediaCache = {};

  bool _hasNomedia(String filePath) {
    if (filePath.isEmpty || !p.isAbsolute(filePath)) {
      return false;
    }
    try {
      var dir = Directory(p.dirname(filePath));
      while (dir.path.length > 1 && dir.path != dir.parent.path) {
        if (_nomediaCache.containsKey(dir.path)) {
          if (_nomediaCache[dir.path]!) return true;
        } else {
          final nomedia = File(p.join(dir.path, '.nomedia'));
          final exists = nomedia.existsSync();
          _nomediaCache[dir.path] = exists;
          if (exists) return true;
        }
        dir = dir.parent;
      }
    } catch (_) {}
    return false;
  }
}

class _IsolateItemResult {
  final int index;
  final ParsedMetadata metadata;

  const _IsolateItemResult({required this.index, required this.metadata});
}

Future<List<_IsolateItemResult>> _extractTagsChunkIsolated(
  List<MediaStoreItem> items,
) async {
  final results = <_IsolateItemResult>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    try {
      final hasValidPath = item.path.isNotEmpty && p.isAbsolute(item.path);
      final file = hasValidPath ? File(item.path) : null;
      ParsedMetadata metadata;

      if (file != null && file.existsSync()) {
        metadata = await TagReader.readFromFile(file);
      } else {
        metadata = ParsedMetadata(
          title: MetadataUtils.resolveTitle(item.title, item.path),
          artist: MetadataUtils.resolveArtist(item.artist),
          album: MetadataUtils.resolveAlbum(item.album, item.path),
          albumArtist: MetadataUtils.resolveArtist(item.artist),
          year: item.year > 0 ? item.year : null,
          trackNumber: item.trackNumber > 0 ? item.trackNumber : null,
        );
      }
      results.add(_IsolateItemResult(index: i, metadata: metadata));
    } catch (_) {
      results.add(
        _IsolateItemResult(
          index: i,
          metadata: ParsedMetadata(
            title: MetadataUtils.resolveTitle(item.title, item.path),
            artist: MetadataUtils.resolveArtist(item.artist),
            album: MetadataUtils.resolveAlbum(item.album, item.path),
            albumArtist: MetadataUtils.resolveArtist(item.artist),
            year: item.year > 0 ? item.year : null,
            trackNumber: item.trackNumber > 0 ? item.trackNumber : null,
          ),
        ),
      );
    }
  }
  return results;
}

class _PreparedTrackData {
  final MediaStoreItem item;
  final ParsedMetadata metadata;
  final String trackKey;
  final String title;
  final String artistName;
  final String albumTitle;
  final int duration;
  final int size;
  final String? artworkKey;
  final List<String> genresList;
  final bool hasValidPath;

  const _PreparedTrackData({
    required this.item,
    required this.metadata,
    required this.trackKey,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.duration,
    required this.size,
    required this.artworkKey,
    required this.genresList,
    required this.hasValidPath,
  });
}

final libraryScannerProvider =
    StateNotifierProvider<LibraryScanner, ScanProgress>((ref) {
      final db = ref.watch(databaseProvider);
      final mediaStore = ref.watch(mediaStoreSourceProvider);
      final permissions = ref.watch(permissionServiceProvider);
      final artwork = ref.watch(artworkServiceProvider);

      return LibraryScanner(
        db: db,
        mediaStore: mediaStore,
        permissions: permissions,
        artworkService: artwork,
      );
    });
