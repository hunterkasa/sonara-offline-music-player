import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../models/wrapped_data.dart';

final wrappedServiceProvider = Provider<WrappedService>((ref) {
  final db = ref.watch(databaseProvider);
  return WrappedService(db);
});

class WrappedService {
  const WrappedService(this._db);

  final AppDatabase _db;

  /// Generates 100% offline listening insights for a given time window.
  Future<WrappedData> generateWrapped({
    DateTime? startDate,
    DateTime? endDate,
    String? periodLabel,
  }) async {
    final now = DateTime.now();
    final effectiveStart = startDate ?? DateTime(now.year, 1, 1);
    final effectiveEnd = endDate ?? now;
    final label = periodLabel ?? '${effectiveStart.year} Wrapped';

    final startEpoch = effectiveStart.millisecondsSinceEpoch ~/ 1000;
    final endEpoch = effectiveEnd.millisecondsSinceEpoch ~/ 1000;

    final historyList = await _db.getPlayHistoryInRange(
      startEpochSeconds: startEpoch,
      endEpochSeconds: endEpoch,
    );
    final allTracks = await _db.getAllTracks();
    final trackMap = {for (final t in allTracks) t.trackKey: t};
    final allArtists = await _db.getAllArtists();
    final artistMap = {for (final a in allArtists) a.id: a};

    var totalMs = 0;
    final trackListenMap = <String, int>{};
    final trackCountMap = <String, int>{};
    final hourBuckets = List<int>.filled(24, 0);
    final activeDates = <DateTime>{};

    for (final entry in historyList) {
      final ms = entry.listenedMs > 0
          ? entry.listenedMs
          : (trackMap[entry.trackKey]?.durationMs ?? 0);
      totalMs += ms;
      trackListenMap[entry.trackKey] =
          (trackListenMap[entry.trackKey] ?? 0) + ms;
      trackCountMap[entry.trackKey] = (trackCountMap[entry.trackKey] ?? 0) + 1;

      final dt = DateTime.fromMillisecondsSinceEpoch(entry.startedAt * 1000);
      hourBuckets[dt.hour]++;
      activeDates.add(DateTime(dt.year, dt.month, dt.day));
    }

    // Fallback if playHistory is sparse (e.g. tracks played before detailed history logging)
    if (historyList.isEmpty) {
      for (final t in allTracks.where((t) => t.playCount > 0)) {
        final estMs = t.playCount * t.durationMs;
        totalMs += estMs;
        trackListenMap[t.trackKey] = estMs;
        trackCountMap[t.trackKey] = t.playCount;
        if (t.lastPlayedAt != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(
            t.lastPlayedAt! * 1000,
          );
          hourBuckets[dt.hour]++;
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        }
      }
    }

    // 1. Top Tracks
    final sortedTrackKeys = trackListenMap.keys.toList()
      ..sort((a, b) {
        final cA = trackCountMap[a] ?? 0;
        final cB = trackCountMap[b] ?? 0;
        if (cA != cB) return cB.compareTo(cA);
        return (trackListenMap[b] ?? 0).compareTo(trackListenMap[a] ?? 0);
      });

    final topTracks = <WrappedTrack>[];
    for (final key in sortedTrackKeys.take(5)) {
      final track = trackMap[key];
      if (track != null) {
        topTracks.add(
          WrappedTrack(
            trackKey: track.trackKey,
            title: track.title,
            artist: artistMap[track.artistId]?.name ?? 'Unknown Artist',
            playCount: trackCountMap[key] ?? track.playCount,
            durationMs: track.durationMs,
            artworkKey: track.artworkKey,
            skipCount: track.skipCount,
          ),
        );
      }
    }

    // 2. Top Artists
    final artistPlayCount = <String, int>{};
    final artistDurationMs = <String, int>{};
    final artistArtworkMap = <String, String?>{};

    for (final key in trackCountMap.keys) {
      final track = trackMap[key];
      if (track == null) continue;
      final artistName = artistMap[track.artistId]?.name ?? 'Unknown Artist';
      final count = trackCountMap[key] ?? 0;
      final ms = trackListenMap[key] ?? 0;

      artistPlayCount[artistName] = (artistPlayCount[artistName] ?? 0) + count;
      artistDurationMs[artistName] = (artistDurationMs[artistName] ?? 0) + ms;
      if (track.artistId != null) {
        artistArtworkMap[artistName] =
            artistMap[track.artistId]?.artworkKey ?? track.artworkKey;
      }
    }

    final sortedArtistNames = artistPlayCount.keys.toList()
      ..sort(
        (a, b) => (artistPlayCount[b] ?? 0).compareTo(artistPlayCount[a] ?? 0),
      );

    final topArtists = <WrappedArtist>[];
    for (final name in sortedArtistNames.take(5)) {
      topArtists.add(
        WrappedArtist(
          name: name,
          playCount: artistPlayCount[name] ?? 0,
          totalMinutes: (artistDurationMs[name] ?? 0) ~/ 60000,
          artworkKey: artistArtworkMap[name],
        ),
      );
    }

    // 3. Top Genres
    final genreCounts = <String, int>{};
    for (final track in allTracks) {
      final count = trackCountMap[track.trackKey] ?? 0;
      if (count > 0) {
        final genres = await _db.getTrackGenres(track.id);
        if (genres.isEmpty) {
          genreCounts['Other'] = (genreCounts['Other'] ?? 0) + count;
        } else {
          for (final g in genres) {
            genreCounts[g] = (genreCounts[g] ?? 0) + count;
          }
        }
      }
    }

    final totalGenrePlays = genreCounts.values.fold(0, (a, b) => a + b);
    final sortedGenreNames = genreCounts.keys.toList()
      ..sort((a, b) => (genreCounts[b] ?? 0).compareTo(genreCounts[a] ?? 0));

    final topGenres = <WrappedGenre>[];
    for (final name in sortedGenreNames.take(5)) {
      final count = genreCounts[name] ?? 0;
      final pct = totalGenrePlays > 0
          ? ((count / totalGenrePlays) * 100.0)
          : 0.0;
      topGenres.add(
        WrappedGenre(
          name: name,
          trackCount: count,
          percentage: double.parse(pct.toStringAsFixed(1)),
        ),
      );
    }

    // 4. Most Skipped
    final skippedCandidates = allTracks.where((t) => t.skipCount > 0).toList()
      ..sort((a, b) => b.skipCount.compareTo(a.skipCount));
    final mostSkippedTracks = skippedCandidates
        .take(5)
        .map(
          (t) => WrappedTrack(
            trackKey: t.trackKey,
            title: t.title,
            artist: artistMap[t.artistId]?.name ?? 'Unknown Artist',
            playCount: t.playCount,
            durationMs: t.durationMs,
            artworkKey: t.artworkKey,
            skipCount: t.skipCount,
          ),
        )
        .toList();

    // 5. Peak Hour & Personality
    var peakHour = 20; // Default 8 PM
    var maxHourCount = -1;
    for (var h = 0; h < 24; h++) {
      if (hourBuckets[h] > maxHourCount) {
        maxHourCount = hourBuckets[h];
        peakHour = h;
      }
    }

    final peakHourLabel = _formatPeakHourLabel(peakHour);
    final (title, desc) = _computePersonality(peakHour, topGenres.length);

    // 6. Streak calculation
    final streakDays = _calculateStreak(activeDates);

    return WrappedData(
      periodLabel: label,
      totalListeningMinutes: totalMs ~/ 60000,
      totalTracksPlayed: trackListenMap.length,
      totalPlaysCount: trackCountMap.values.fold(0, (a, b) => a + b),
      topTracks: topTracks,
      topArtists: topArtists,
      topGenres: topGenres,
      mostSkippedTracks: mostSkippedTracks,
      peakHour: peakHour,
      peakHourLabel: peakHourLabel,
      personalityTitle: title,
      personalityDescription: desc,
      listeningStreakDays: streakDays,
    );
  }

  String _formatPeakHourLabel(int hour) {
    final nextHour = (hour + 1) % 24;
    final hStr = _format12Hour(hour);
    final nextHStr = _format12Hour(nextHour);
    if (hour >= 5 && hour < 12) {
      return 'Morning Glow ($hStr - $nextHStr)';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon Focus ($hStr - $nextHStr)';
    } else if (hour >= 17 && hour < 22) {
      return 'Evening Groove ($hStr - $nextHStr)';
    } else {
      return 'Night Owl Echoes ($hStr - $nextHStr)';
    }
  }

  String _format12Hour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  (String, String) _computePersonality(int peakHour, int genreCount) {
    if (peakHour >= 22 || peakHour < 5) {
      return (
        'Night Owl Voyager',
        'You explore sonic frequencies in the calm silence of midnight.',
      );
    } else if (peakHour >= 5 && peakHour < 11) {
      return (
        'Morning Sunseeker',
        'Rhythm and melody ignite your energy as dawn breaks.',
      );
    } else if (genreCount >= 4) {
      return (
        'Eclectic Alchemist',
        'Boundaries mean nothing to your ears—you embrace every vibration.',
      );
    } else {
      return (
        'Resolute Audiophile',
        'When you fall in love with a sound, you listen with deep devotion.',
      );
    }
  }

  int _calculateStreak(Set<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final sorted = dates.toList()..sort();
    var maxStreak = 1;
    var currentStreak = 1;

    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      final diff = curr.difference(prev).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }
    return maxStreak;
  }
}
