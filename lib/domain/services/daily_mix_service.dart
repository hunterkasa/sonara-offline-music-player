import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import 'track_radio_service.dart';

/// Represents a Spotify-style daily mix playlist
class DailyMix {
  const DailyMix({
    required this.id,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tracks,
    required this.primaryColor,
    required this.secondaryColor,
    this.genre,
  });

  /// Virtual playlist ID (-101, -102, -103, etc.)
  final int id;

  /// Mix number (1, 2, 3, etc.)
  final int index;

  /// Display title, e.g. "Daily Mix 1"
  final String title;

  /// Featured artists, e.g. "Queen, The Beatles, Pink Floyd"
  final String subtitle;

  /// Full description
  final String description;

  /// Curated tracks in this mix
  final List<Track> tracks;

  /// Gradient start color
  final Color primaryColor;

  /// Gradient end color
  final Color secondaryColor;

  /// Associated genre if clustered by genre
  final String? genre;
}

/// Represents the daily spotlight track recommendation
class TodaysPick {
  const TodaysPick({
    required this.track,
    required this.artistName,
    this.albumTitle,
    this.artworkKey,
    required this.reason,
    required this.dateLabel,
    required this.queue,
  });

  /// Spotlight track
  final Track track;

  /// Artist name
  final String artistName;

  /// Album title
  final String? albumTitle;

  /// Artwork key
  final String? artworkKey;

  /// Human-friendly reason, e.g. "In your heavy rotation"
  final String reason;

  /// Formatted date, e.g. "Wed, Oct 7"
  final String dateLabel;

  /// Complementary radio queue seeded by this track
  final List<Track> queue;
}

final dailyMixServiceProvider = Provider<DailyMixService>((ref) {
  final db = ref.watch(databaseProvider);
  final radioService = ref.watch(trackRadioServiceProvider);
  return DailyMixService(db: db, radioService: radioService);
});

final todaysPickProvider = StreamProvider<TodaysPick?>((ref) {
  final service = ref.watch(dailyMixServiceProvider);
  final db = ref.watch(databaseProvider);
  return db
      .watchAllTracks()
      .debounceAfterInitial(const Duration(milliseconds: 600))
      .asyncMap((_) => service.getTodaysPick());
});

final dailyMixesStreamProvider = StreamProvider<List<DailyMix>>((ref) {
  final service = ref.watch(dailyMixServiceProvider);
  final db = ref.watch(databaseProvider);
  return db
      .watchAllTracks()
      .debounceAfterInitial(const Duration(milliseconds: 600))
      .asyncMap((_) => service.getDailyMixes());
});

extension _StreamDebounce<T> on Stream<T> {
  Stream<T> debounceAfterInitial(Duration duration) {
    late final StreamController<T> controller;
    StreamSubscription<T>? sub;
    Timer? timer;
    var hasEmittedFirst = false;

    controller = StreamController<T>(
      onListen: () {
        sub = listen(
          (data) {
            if (!hasEmittedFirst) {
              hasEmittedFirst = true;
              if (!controller.isClosed) {
                controller.add(data);
              }
            } else {
              timer?.cancel();
              timer = Timer(duration, () {
                if (!controller.isClosed) {
                  controller.add(data);
                }
              });
            }
          },
          onError: (Object err, StackTrace st) {
            if (!controller.isClosed) {
              controller.addError(err, st);
            }
          },
          onDone: () {
            timer?.cancel();
            if (!controller.isClosed) {
              controller.close();
            }
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        sub?.cancel();
      },
      sync: true,
    );

    return controller.stream;
  }
}

class DailyMixService {
  DailyMixService({required this.db, required this.radioService});

  final AppDatabase db;
  final TrackRadioService radioService;

  static const List<(Color, Color)> mixGradients = [
    (Color(0xFF00B4D8), Color(0xFF03045E)), // Mix 1: Cyan / Deep Ocean
    (Color(0xFF9D4EDD), Color(0xFF240046)), // Mix 2: Neon Purple / Dark Violet
    (Color(0xFFFF9E00), Color(0xFF800020)), // Mix 3: Sunset Orange / Crimson
    (Color(0xFF06D6A0), Color(0xFF073B4C)), // Mix 4: Emerald / Deep Teal
    (Color(0xFFFF007F), Color(0xFF2B0938)), // Mix 5: Electric Rose / Midnight
    (Color(0xFF4361EE), Color(0xFF1B263B)), // Mix 6: Azure Blue / Dark Slate
  ];

  static int getDailySeed([DateTime? date]) {
    final d = date ?? DateTime.now();
    return d.year * 10000 + d.month * 100 + d.day;
  }

  static String formatDailyDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[(date.weekday - 1) % 7];
    final month = months[(date.month - 1) % 12];
    return '$weekday, $month ${date.day}';
  }

  /// Selects the daily spotlight track deterministically for [date].
  Future<TodaysPick?> getTodaysPick({DateTime? date}) async {
    final now = date ?? DateTime.now();
    final seed = getDailySeed(now);
    final rng = Random(seed);

    final allTracks = (await db.getAllTracks())
        .where((t) => !t.isMissing && !t.isHidden)
        .toList();
    if (allTracks.isEmpty) return null;

    final favorites = allTracks
        .where((t) => t.isFavorite || t.playCount > 0)
        .toList();
    Track selectedTrack;
    String reason;

    if (favorites.isNotEmpty) {
      favorites.sort((a, b) => a.trackKey.compareTo(b.trackKey));
      selectedTrack = favorites[rng.nextInt(favorites.length)];
      if (selectedTrack.isFavorite) {
        reason = 'From your favorites';
      } else if (selectedTrack.playCount > 5) {
        reason = 'In your heavy rotation';
      } else {
        reason = 'Based on your listening history';
      }
    } else {
      allTracks.sort((a, b) => a.trackKey.compareTo(b.trackKey));
      selectedTrack = allTracks[rng.nextInt(allTracks.length)];
      reason = 'Daily music spotlight';
    }

    final artistName =
        await db.getArtistName(selectedTrack.artistId) ?? 'Unknown Artist';
    final albumTitle = await db.getAlbumTitle(selectedTrack.albumId);

    // Complementary queue seeded by the spotlight track
    final queue = await radioService.generateRadioQueue(
      selectedTrack,
      limit: 25,
      random: Random(seed + 99),
    );

    return TodaysPick(
      track: selectedTrack,
      artistName: artistName,
      albumTitle: albumTitle,
      artworkKey: selectedTrack.artworkKey,
      reason: reason,
      dateLabel: formatDailyDate(now),
      queue: queue,
    );
  }

  /// Generates Spotify-style daily mixes clustered by genres and artists.
  Future<List<DailyMix>> getDailyMixes({DateTime? date}) async {
    final now = date ?? DateTime.now();
    final seed = getDailySeed(now);

    final allTracks = (await db.getAllTracks())
        .where((t) => !t.isMissing && !t.isHidden)
        .toList();
    if (allTracks.isEmpty) return [];

    final allArtists = await db.getAllArtists();
    final artistNameMap = {for (final a in allArtists) a.id: a.name};

    // Small library fallback (<= 15 tracks): Single Daily Mix
    if (allTracks.length <= 15) {
      final shuffled = List<Track>.from(allTracks)..shuffle(Random(seed));
      final subtitle = _getFeaturedArtists(shuffled, artistNameMap);
      return [
        DailyMix(
          id: -101,
          index: 1,
          title: 'Daily Mix 1',
          subtitle: subtitle,
          description: 'Featuring $subtitle and more',
          tracks: shuffled,
          primaryColor: mixGradients[0].$1,
          secondaryColor: mixGradients[0].$2,
        ),
      ];
    }

    // Try genre clustering
    final trackGenresMap = await db.getAllTrackGenresMap();
    final genreClusters = <String, List<Track>>{};

    for (final track in allTracks) {
      final genres = trackGenresMap[track.id] ?? [];
      for (final g in genres) {
        final cleanGenre = g.trim();
        if (cleanGenre.isNotEmpty) {
          genreClusters.putIfAbsent(cleanGenre, () => []).add(track);
        }
      }
    }

    // Viable genres with at least 3 tracks
    final viableGenres = genreClusters.entries
        .where((e) => e.value.length >= 3)
        .toList();

    if (viableGenres.length >= 2) {
      // Sort genres by popularity (total plays + track count)
      viableGenres.sort((a, b) {
        final playsA = a.value.fold<int>(0, (sum, t) => sum + t.playCount);
        final playsB = b.value.fold<int>(0, (sum, t) => sum + t.playCount);
        final scoreA = playsA * 2 + a.value.length;
        final scoreB = playsB * 2 + b.value.length;
        return scoreB.compareTo(scoreA);
      });

      final mixCount = min(6, viableGenres.length);
      final mixes = <DailyMix>[];

      for (var i = 0; i < mixCount; i++) {
        final entry = viableGenres[i];
        final genreName = entry.key;
        final rawTracks = List<Track>.from(entry.value);

        // Sort: favorites and high play counts first, then shuffle remainder with daily seed
        rawTracks.sort((a, b) {
          final favDiff = (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0);
          if (favDiff != 0) return favDiff;
          return b.playCount.compareTo(a.playCount);
        });

        final topTier = rawTracks.take(8).toList();
        final restTier = rawTracks.skip(8).toList()..shuffle(Random(seed + i));
        final combined = [...topTier, ...restTier].take(25).toList();

        final subtitle = _getFeaturedArtists(combined, artistNameMap);
        final gradient = mixGradients[i % mixGradients.length];

        mixes.add(
          DailyMix(
            id: -101 - i,
            index: i + 1,
            title: 'Daily Mix ${i + 1}',
            subtitle: subtitle,
            description: 'Featuring $subtitle and more $genreName music',
            tracks: combined,
            primaryColor: gradient.$1,
            secondaryColor: gradient.$2,
            genre: genreName,
          ),
        );
      }
      return mixes;
    }

    // Fallback: Artist-based clustering
    final artistClusters = <int, List<Track>>{};
    for (final track in allTracks) {
      if (track.artistId != null) {
        artistClusters.putIfAbsent(track.artistId!, () => []).add(track);
      }
    }

    final viableArtists = artistClusters.entries
        .where((e) => e.value.length >= 2)
        .toList();
    if (viableArtists.length >= 2) {
      viableArtists.sort((a, b) {
        final playsA = a.value.fold<int>(0, (sum, t) => sum + t.playCount);
        final playsB = b.value.fold<int>(0, (sum, t) => sum + t.playCount);
        return playsB.compareTo(playsA);
      });

      final mixCount = min(6, viableArtists.length);
      final mixes = <DailyMix>[];

      for (var i = 0; i < mixCount; i++) {
        final artistEntry = viableArtists[i];
        final seedTrack = artistEntry.value.first;
        final queue = await radioService.generateRadioQueue(
          seedTrack,
          limit: 25,
          random: Random(seed + (i * 13)),
        );

        final subtitle = _getFeaturedArtists(queue, artistNameMap);
        final gradient = mixGradients[i % mixGradients.length];

        mixes.add(
          DailyMix(
            id: -101 - i,
            index: i + 1,
            title: 'Daily Mix ${i + 1}',
            subtitle: subtitle,
            description: 'Featuring $subtitle and related music',
            tracks: queue,
            primaryColor: gradient.$1,
            secondaryColor: gradient.$2,
          ),
        );
      }
      return mixes;
    }

    // Broad library partition fallback
    final shuffled = List<Track>.from(allTracks)..shuffle(Random(seed));
    final mixCount = min(4, (shuffled.length / 8).ceil().clamp(1, 4));
    final mixes = <DailyMix>[];
    final chunkSize = (shuffled.length / mixCount).ceil();

    for (var i = 0; i < mixCount; i++) {
      final chunkTracks = shuffled.skip(i * chunkSize).take(chunkSize).toList();
      if (chunkTracks.isEmpty) continue;

      final subtitle = _getFeaturedArtists(chunkTracks, artistNameMap);
      final gradient = mixGradients[i % mixGradients.length];

      mixes.add(
        DailyMix(
          id: -101 - i,
          index: i + 1,
          title: 'Daily Mix ${i + 1}',
          subtitle: subtitle,
          description: 'Featuring $subtitle and more',
          tracks: chunkTracks,
          primaryColor: gradient.$1,
          secondaryColor: gradient.$2,
        ),
      );
    }

    return mixes;
  }

  /// Get a specific daily mix by its virtual ID (-101 to -106)
  Future<DailyMix?> getDailyMixById(int id, {DateTime? date}) async {
    final mixes = await getDailyMixes(date: date);
    for (final mix in mixes) {
      if (mix.id == id) return mix;
    }
    return null;
  }

  /// Watch a specific daily mix by its virtual ID
  Stream<DailyMix?> watchDailyMixById(int id, {DateTime? date}) {
    return db.watchAllTracks().asyncMap((_) => getDailyMixById(id, date: date));
  }

  /// Get tracks for a specific daily mix
  Future<List<Track>> getDailyMixTracks(int id, {DateTime? date}) async {
    final mix = await getDailyMixById(id, date: date);
    return mix?.tracks ?? [];
  }

  /// Watch tracks for a specific daily mix
  Stream<List<Track>> watchDailyMixTracks(int id, {DateTime? date}) {
    return db.watchAllTracks().asyncMap(
      (_) => getDailyMixTracks(id, date: date),
    );
  }

  String _getFeaturedArtists(
    List<Track> tracks,
    Map<int, String> artistNameMap,
  ) {
    final artistCounts = <String, int>{};
    for (final t in tracks) {
      if (t.artistId != null) {
        final name = artistNameMap[t.artistId!];
        if (name != null && name.trim().isNotEmpty) {
          artistCounts[name] = (artistCounts[name] ?? 0) + 1;
        }
      }
    }

    if (artistCounts.isEmpty) return 'Various Artists';

    final sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topArtists = sortedArtists.take(3).map((e) => e.key).toList();
    return topArtists.join(', ');
  }
}
