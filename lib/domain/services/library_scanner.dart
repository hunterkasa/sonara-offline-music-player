import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
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
            final dbTracks = await (_db.select(
              _db.tracks,
            )..where((t) => t.mediaStoreId.isNotNull())).get();
            final missingTrackIds = dbTracks
                .where((t) => !knownIds.contains(t.mediaStoreId))
                .map((t) => t.id)
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
    for (final item in items) {
      try {
        final file = File(item.path);
        ParsedMetadata metadata;

        if (await file.exists()) {
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
        } else {
          final sidecar = await _artworkService.resolveArtworkFile(
            artworkKey: null,
            filePath: item.path,
          );
          if (sidecar != null) {
            artworkKey = ArtworkService.generateArtworkKey(sidecar.path);
          }
        }

        // Check for sidecar CUE sheet
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
              continue; // Virtual sub-tracks imported, skip inserting monolith rip
            }
          } catch (_) {}
        }

        // Resolve or create Artist
        final artistId = await _getOrCreateArtist(artistName);

        // Resolve or create Album
        final albumId = await _getOrCreateAlbum(
          title: albumTitle,
          artistId: artistId,
          year: metadata.year ?? (item.year > 0 ? item.year : null),
          artworkKey: artworkKey,
        );

        // Upsert Track
        await _db
            .into(_db.tracks)
            .insertOnConflictUpdate(
              TracksCompanion(
                trackKey: Value(trackKey),
                mediaStoreId: Value(item.id),
                contentUri: Value(item.contentUri),
                path: Value(item.path),
                relativeDir: Value(p.dirname(item.path)),
                title: Value(title),
                titleSort: Value(MetadataUtils.normalizeSortName(title)),
                artistId: Value(artistId),
                albumId: Value(albumId),
                albumArtistId: Value(artistId),
                trackNo: Value(
                  metadata.trackNumber ??
                      (item.trackNumber > 0 ? item.trackNumber : null),
                ),
                discNo: Value(metadata.discNumber),
                year: Value(
                  metadata.year ?? (item.year > 0 ? item.year : null),
                ),
                durationMs: Value(duration),
                mime: Value(
                  item.mimeType.isNotEmpty ? item.mimeType : metadata.codec,
                ),
                sizeBytes: Value(size),
                dateAdded: Value(item.dateAdded),
                dateModified: Value(item.dateModified),
                artworkKey: Value(artworkKey),
                replayGainTrackDb: Value(metadata.replayGainTrackDb),
                replayGainAlbumDb: Value(metadata.replayGainAlbumDb),
                hasLyrics: Value(
                  metadata.lyrics != null && metadata.lyrics!.isNotEmpty,
                ),
              ),
            );

        // Fetch track for genre association
        final insertedTrack = await (_db.select(
          _db.tracks,
        )..where((t) => t.trackKey.equals(trackKey))).getSingleOrNull();

        // Collect genres from tags or MediaStore
        final genresList = <String>{};
        for (final g in metadata.genres) {
          final trimmed = g.trim();
          if (trimmed.isNotEmpty) genresList.add(trimmed);
        }
        if (genresList.isEmpty && item.genre.trim().isNotEmpty) {
          genresList.add(item.genre.trim());
        }

        if (insertedTrack != null) {
          for (final genreName in genresList) {
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

        // Sync FTS
        await _db.customStatement(
          'INSERT OR REPLACE INTO tracks_fts(track_key, title, artist, album, genre) VALUES (?, ?, ?, ?, ?)',
          [trackKey, title, artistName, albumTitle, genresList.join(' ')],
        );
      } catch (_) {
        // Individual track processing error must never break the whole library scan
        continue;
      }
    }
  }

  Future<int> _getOrCreateArtist(String name) async {
    final existing = await (_db.select(
      _db.artists,
    )..where((a) => a.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;

    return await _db
        .into(_db.artists)
        .insert(
          ArtistsCompanion(
            name: Value(name),
            nameSort: Value(MetadataUtils.normalizeSortName(name)),
          ),
        );
  }

  Future<int> _getOrCreateAlbum({
    required String title,
    required int artistId,
    int? year,
    String? artworkKey,
  }) async {
    final existing =
        await (_db.select(_db.albums)..where(
              (a) => a.title.equals(title) & a.albumArtistId.equals(artistId),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    return await _db
        .into(_db.albums)
        .insert(
          AlbumsCompanion(
            title: Value(title),
            titleSort: Value(MetadataUtils.normalizeSortName(title)),
            albumArtistId: Value(artistId),
            year: Value(year),
            artworkKey: Value(artworkKey),
          ),
        );
  }

  bool _hasNomedia(String filePath) {
    try {
      var dir = Directory(p.dirname(filePath));
      while (dir.path != dir.parent.path) {
        final nomedia = File(p.join(dir.path, '.nomedia'));
        if (nomedia.existsSync()) {
          return true;
        }
        dir = dir.parent;
      }
    } catch (_) {}
    return false;
  }
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
