import 'package:flutter/foundation.dart';

@immutable
class WrappedTrack {
  const WrappedTrack({
    required this.trackKey,
    required this.title,
    required this.artist,
    required this.playCount,
    required this.durationMs,
    this.artworkKey,
    this.skipCount = 0,
  });

  final String trackKey;
  final String title;
  final String artist;
  final int playCount;
  final int durationMs;
  final String? artworkKey;
  final int skipCount;
}

@immutable
class WrappedArtist {
  const WrappedArtist({
    required this.name,
    required this.playCount,
    required this.totalMinutes,
    this.artworkKey,
  });

  final String name;
  final int playCount;
  final int totalMinutes;
  final String? artworkKey;
}

@immutable
class WrappedGenre {
  const WrappedGenre({
    required this.name,
    required this.trackCount,
    required this.percentage,
  });

  final String name;
  final int trackCount;
  final double percentage; // 0.0 - 100.0
}

@immutable
class WrappedData {
  const WrappedData({
    required this.periodLabel,
    required this.totalListeningMinutes,
    required this.totalTracksPlayed,
    required this.totalPlaysCount,
    required this.topTracks,
    required this.topArtists,
    required this.topGenres,
    required this.mostSkippedTracks,
    required this.peakHour,
    required this.peakHourLabel,
    required this.personalityTitle,
    required this.personalityDescription,
    required this.listeningStreakDays,
  });

  final String periodLabel;
  final int totalListeningMinutes;
  final int totalTracksPlayed;
  final int totalPlaysCount;
  final List<WrappedTrack> topTracks;
  final List<WrappedArtist> topArtists;
  final List<WrappedGenre> topGenres;
  final List<WrappedTrack> mostSkippedTracks;
  final int peakHour;
  final String peakHourLabel;
  final String personalityTitle;
  final String personalityDescription;
  final int listeningStreakDays;

  bool get isEmpty => totalListeningMinutes == 0 && topTracks.isEmpty;
}
