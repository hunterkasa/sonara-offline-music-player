import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Computes a stable, deterministic trackKey from track metadata.
///
/// Formula: SHA-256 of normalized (title, artist, album, durationMs, sizeBytes).
/// Normalization trims whitespace and converts to lower-case.
class TrackKeyUtil {
  const TrackKeyUtil._();

  static String generate({
    required String title,
    required String artist,
    required String album,
    required int durationMs,
    required int sizeBytes,
  }) {
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedArtist = artist.trim().toLowerCase();
    final normalizedAlbum = album.trim().toLowerCase();

    final payload =
        '$normalizedTitle|$normalizedArtist|$normalizedAlbum|$durationMs|$sizeBytes';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
