import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

enum DuplicateMatchType { exactFile, metadataAndDuration }

class DuplicateCluster {
  final DuplicateMatchType matchType;
  final String label;
  final List<Track> tracks;

  const DuplicateCluster({
    required this.matchType,
    required this.label,
    required this.tracks,
  });

  int get totalSize => tracks.fold(0, (acc, t) => acc + t.sizeBytes);
}

class DuplicateFinderService {
  final AppDatabase db;

  DuplicateFinderService(this.db);

  /// Scans all active tracks and groups duplicates into clusters
  Future<List<DuplicateCluster>> findDuplicates() async {
    final allTracks = await db.getAllTracks(includeHidden: false);
    final clusters = <DuplicateCluster>[];

    // 1. Exact Match: same file size and duration within 500ms
    final sizeMap = <int, List<Track>>{};
    for (final track in allTracks) {
      sizeMap.putIfAbsent(track.sizeBytes, () => []).add(track);
    }

    final exactTrackKeys = <String>{};
    for (final entry in sizeMap.entries) {
      if (entry.value.length > 1) {
        // Check duration similarity
        final group = entry.value;
        final baseDuration = group.first.durationMs;
        final allSameDuration = group.every(
          (t) => (t.durationMs - baseDuration).abs() < 1000,
        );
        if (allSameDuration) {
          clusters.add(
            DuplicateCluster(
              matchType: DuplicateMatchType.exactFile,
              label: '${group.first.title} (${_formatBytes(entry.key)})',
              tracks: group,
            ),
          );
          for (final t in group) {
            exactTrackKeys.add(t.trackKey);
          }
        }
      }
    }

    // 2. Metadata Match: normalized title and duration within 2 seconds
    final metaMap = <String, List<Track>>{};
    for (final track in allTracks) {
      if (exactTrackKeys.contains(track.trackKey)) continue;

      final normalizedTitle = track.title.trim().toLowerCase();
      final durationSec = track.durationMs ~/ 1000;
      final key = '${normalizedTitle}_$durationSec';
      metaMap.putIfAbsent(key, () => []).add(track);
    }

    for (final entry in metaMap.entries) {
      if (entry.value.length > 1) {
        clusters.add(
          DuplicateCluster(
            matchType: DuplicateMatchType.metadataAndDuration,
            label: entry.value.first.title,
            tracks: entry.value,
          ),
        );
      }
    }

    return clusters;
  }

  /// Hides a track from the music library
  Future<void> hideTrack(String trackKey) async {
    await db.setTrackHidden(trackKey, true);
  }

  /// Unhides a track
  Future<void> unhideTrack(String trackKey) async {
    await db.setTrackHidden(trackKey, false);
  }

  /// Permanently removes track from DB and optionally deletes file
  Future<void> deleteTrack(Track track, {bool deleteFile = false}) async {
    await db.deleteTrack(track.trackKey);
    if (deleteFile && track.path.isNotEmpty) {
      try {
        final file = File(track.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Scoped storage or permission denial fallback
      }
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

final duplicateFinderServiceProvider = Provider<DuplicateFinderService>((ref) {
  final db = ref.watch(databaseProvider);
  return DuplicateFinderService(db);
});
