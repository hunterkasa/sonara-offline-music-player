import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaStoreItem {
  final int id;
  final String contentUri;
  final String albumArtUri;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String path;
  final int sizeBytes;
  final int dateAdded;
  final int dateModified;
  final int albumId;
  final int trackNumber;
  final String mimeType;
  final int year;
  final String genre;

  const MediaStoreItem({
    required this.id,
    required this.contentUri,
    required this.albumArtUri,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.path,
    required this.sizeBytes,
    required this.dateAdded,
    required this.dateModified,
    required this.albumId,
    required this.trackNumber,
    required this.mimeType,
    required this.year,
    this.genre = '',
  });

  factory MediaStoreItem.fromMap(Map<dynamic, dynamic> map) {
    return MediaStoreItem(
      id: (map['id'] as num?)?.toInt() ?? 0,
      contentUri: (map['contentUri'] as String?) ?? '',
      albumArtUri: (map['albumArtUri'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      artist: (map['artist'] as String?) ?? '',
      album: (map['album'] as String?) ?? '',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      path: (map['path'] as String?) ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      dateAdded: (map['dateAdded'] as num?)?.toInt() ?? 0,
      dateModified: (map['dateModified'] as num?)?.toInt() ?? 0,
      albumId: (map['albumId'] as num?)?.toInt() ?? 0,
      trackNumber: (map['trackNumber'] as num?)?.toInt() ?? 0,
      mimeType: (map['mimeType'] as String?) ?? '',
      year: (map['year'] as num?)?.toInt() ?? 0,
      genre: (map['genre'] as String?) ?? '',
    );
  }
}

abstract class MediaStoreSource {
  Future<List<MediaStoreItem>> queryAudioFiles({
    int minDurationMs = 30000,
    int modifiedSinceSec = 0,
  });

  Future<List<int>> getKnownMediaIds();

  Stream<void> observeMediaStore();
}

class AndroidMediaStoreSource implements MediaStoreSource {
  static const _methodChannel = MethodChannel('com.example.sonara/mediastore');
  static const _eventChannel = EventChannel(
    'com.example.sonara/mediastore_observer',
  );

  @override
  Future<List<MediaStoreItem>> queryAudioFiles({
    int minDurationMs = 30000,
    int modifiedSinceSec = 0,
  }) async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final List<dynamic>? rawList = await _methodChannel.invokeListMethod(
        'queryAudioFiles',
        {'minDurationMs': minDurationMs, 'modifiedSinceSec': modifiedSinceSec},
      );

      if (rawList == null) return [];
      return rawList
          .map((item) => MediaStoreItem.fromMap(item as Map<dynamic, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<int>> getKnownMediaIds() async {
    if (!Platform.isAndroid) return [];

    try {
      final List<dynamic>? rawList = await _methodChannel.invokeListMethod(
        'getKnownMediaIds',
      );
      if (rawList == null) return [];
      return rawList.map((id) => (id as num).toInt()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<void> observeMediaStore() {
    if (!Platform.isAndroid) {
      return const Stream.empty();
    }
    return _eventChannel.receiveBroadcastStream().map((_) {});
  }
}

final mediaStoreSourceProvider = Provider<MediaStoreSource>((ref) {
  return AndroidMediaStoreSource();
});
