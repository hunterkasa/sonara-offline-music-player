import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/playback_controller.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

final trackRadioServiceProvider = Provider<TrackRadioService>((ref) {
  final db = ref.watch(databaseProvider);
  final playbackController = ref.watch(playbackControllerProvider);
  return TrackRadioService(db: db, playbackController: playbackController);
});

class TrackRadioService {
  const TrackRadioService({required this.db, required this.playbackController});

  final AppDatabase db;
  final PlaybackController playbackController;

  /// Generates a similarity-clustered playlist seeded by [seedTrack].
  Future<List<Track>> generateRadioQueue(
    Track seedTrack, {
    int limit = 35,
    Random? random,
  }) async {
    final rng = random ?? Random();
    final allTracks = await db.getAllTracks();
    final candidates = allTracks
        .where(
          (t) =>
              t.trackKey != seedTrack.trackKey && !t.isMissing && !t.isHidden,
        )
        .toList();

    if (candidates.isEmpty) {
      return [seedTrack];
    }

    final allTrackGenresMap = await db.getAllTrackGenresMap();
    final seedGenres =
        allTrackGenresMap[seedTrack.id] ??
        await db.getTrackGenres(seedTrack.id);
    final seedGenreNames = seedGenres.map((g) => g.toLowerCase()).toSet();

    // Cache album years and artists
    final albumYearMap = <int, int?>{};
    final allAlbums = await db.getAllAlbums();
    for (final alb in allAlbums) {
      albumYearMap[alb.id] = alb.year;
    }
    final seedYear = seedTrack.albumId != null
        ? albumYearMap[seedTrack.albumId!]
        : null;

    final allArtists = await db.getAllArtists();
    final artistNameMap = {
      for (final a in allArtists) a.id: a.name.toLowerCase(),
    };
    final seedArtistName = seedTrack.artistId != null
        ? (artistNameMap[seedTrack.artistId!] ?? '')
        : '';

    final scoredCandidates = <(Track, double)>[];

    for (final candidate in candidates) {
      // 1. Genre Score (weight 0.40)
      var genreScore = 0.4;
      final candGenres = allTrackGenresMap[candidate.id] ?? const [];
      if (seedGenreNames.isNotEmpty && candGenres.isNotEmpty) {
        final candGenreNames = candGenres.map((g) => g.toLowerCase()).toSet();
        final intersection = seedGenreNames.intersection(candGenreNames);
        if (intersection.isNotEmpty) {
          genreScore = 1.0;
        } else {
          genreScore = 0.1;
        }
      }

      // 2. Year / Era Proximity Score (weight 0.25)
      var eraScore = 0.5;
      final candYear = candidate.albumId != null
          ? albumYearMap[candidate.albumId!]
          : null;
      if (seedYear != null && candYear != null) {
        final diff = (seedYear - candYear).abs();
        if (diff <= 2) {
          eraScore = 1.0;
        } else if (diff <= 10) {
          eraScore = (1.0 - (diff / 12.0)).clamp(0.1, 1.0);
        } else {
          eraScore = 0.15;
        }
      }

      // 3. Artist & Album Affinity Score (weight 0.20)
      var artistScore = 0.25;
      final candArtistName = candidate.artistId != null
          ? (artistNameMap[candidate.artistId!] ?? '')
          : '';

      if (candidate.artistId != null &&
          candidate.artistId == seedTrack.artistId) {
        artistScore = 0.95;
      } else if (candidate.albumId != null &&
          candidate.albumId == seedTrack.albumId) {
        artistScore = 0.7;
      } else if (seedArtistName.isNotEmpty &&
          candArtistName.isNotEmpty &&
          (candArtistName.contains(seedArtistName) ||
              seedArtistName.contains(candArtistName))) {
        artistScore = 0.8;
      }

      // 4. Duration Similarity Score (weight 0.15)
      final durDiff = (seedTrack.durationMs - candidate.durationMs).abs();
      final maxDur = max(seedTrack.durationMs, 1000);
      final durScore = (1.0 - (durDiff / maxDur)).clamp(0.0, 1.0);

      final totalScore =
          (0.40 * genreScore) +
          (0.25 * eraScore) +
          (0.20 * artistScore) +
          (0.15 * durScore);

      scoredCandidates.add((candidate, totalScore));
    }

    // Sort descending by score
    scoredCandidates.sort((a, b) => b.$2.compareTo(a.$2));

    // Take top candidate pool
    final poolSize = min(scoredCandidates.length, limit * 2);
    final topPool = scoredCandidates.take(poolSize).toList();

    // Add mild random jitter to give varied listening sessions
    topPool.shuffle(rng);
    topPool.sort((a, b) {
      final scoreDiff = b.$2 - a.$2;
      if (scoreDiff.abs() > 0.25) {
        return b.$2.compareTo(a.$2);
      }
      return rng.nextBool() ? 1 : -1;
    });

    final radioTracks = <Track>[seedTrack];
    for (final item in topPool.take(limit - 1)) {
      radioTracks.add(item.$1);
    }

    return radioTracks;
  }

  /// Builds a radio queue from [seedTrack] and begins playback immediately.
  Future<List<Track>> startRadio(Track seedTrack, {int limit = 35}) async {
    final queue = await generateRadioQueue(seedTrack, limit: limit);
    await playbackController.playQueue(
      queue.map((t) => t.trackKey).toList(),
      initialIndex: 0,
    );
    return queue;
  }
}
