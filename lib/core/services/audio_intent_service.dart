import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../audio/playback_controller.dart';
import '../../data/db/app_database.dart';

class AudioIntentService {
  AudioIntentService({
    required this.playbackController,
    required this.db,
    this.onNavigate,
  });

  final PlaybackController playbackController;
  final AppDatabase db;
  final void Function(String route)? onNavigate;

  static const _channel = MethodChannel('com.example.sonara/mediastore');

  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAudioIntent') {
        final uri = call.arguments as String?;
        if (uri != null) {
          await handleAudioUri(uri);
        }
      }
    });

    try {
      final initialUri = await _channel.invokeMethod<String>(
        'getInitialAudioIntent',
      );
      if (initialUri != null) {
        await handleAudioUri(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial audio intent: $e');
    }
  }

  Future<void> handleAudioUri(String uriString) async {
    try {
      // 0. Handle sonara:// deep links
      if (uriString.startsWith('sonara://')) {
        await _handleSonaraDeepLink(Uri.parse(uriString));
        return;
      }

      // 1. Search if track exists in DB by contentUri or path
      final allTracks = await db.watchAllTracks().first;
      final match = allTracks.cast<Track?>().firstWhere(
        (t) => t?.contentUri == uriString || t?.path == uriString,
        orElse: () => null,
      );

      if (match != null) {
        await playbackController.playTrack(match.trackKey);
        return;
      }

      // 2. If not indexed, create a synthesized track entry
      final uri = Uri.parse(uriString);
      final filename = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'External Audio';
      final tempKey = 'ext_${uriString.hashCode}';
      await db
          .into(db.tracks)
          .insertOnConflictUpdate(
            TracksCompanion.insert(
              trackKey: tempKey,
              contentUri: uriString,
              path: uri.isScheme('file') ? uri.toFilePath() : uriString,
              title: filename,
              titleSort: filename.toLowerCase(),
              durationMs: 0,
              sizeBytes: 0,
            ),
          );

      // Play via controller
      await playbackController.playQueue([tempKey], initialIndex: 0);
    } catch (e) {
      debugPrint('Failed to handle audio intent: $e');
    }
  }

  Future<void> _handleSonaraDeepLink(Uri uri) async {
    final host = uri.host.toLowerCase();
    switch (host) {
      case 'shuffle':
        final allTracks = await (db.select(
          db.tracks,
        )..where((t) => t.isHidden.equals(false))).get();
        if (allTracks.isNotEmpty) {
          final keys = allTracks.map((t) => t.trackKey).toList()..shuffle();
          await playbackController.playQueue(keys, initialIndex: 0);
        }
        break;

      case 'favorites':
      case 'liked':
        final likedTracks =
            await (db.select(db.tracks)
                  ..where(
                    (t) => t.isFavorite.equals(true) & t.isHidden.equals(false),
                  )
                  ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)]))
                .get();
        if (likedTracks.isNotEmpty) {
          final keys = likedTracks.map((t) => t.trackKey).toList();
          await playbackController.playQueue(keys, initialIndex: 0);
        }
        break;

      case 'recent':
      case 'recently-played':
        final recentTracks =
            await (db.select(db.tracks)
                  ..where(
                    (t) =>
                        t.lastPlayedAt.isNotNull() & t.isHidden.equals(false),
                  )
                  ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
                  ..limit(50))
                .get();
        if (recentTracks.isNotEmpty) {
          final keys = recentTracks.map((t) => t.trackKey).toList();
          await playbackController.playQueue(keys, initialIndex: 0);
        }
        break;

      case 'search':
        if (onNavigate != null) {
          onNavigate!('/search');
        }
        break;

      default:
        debugPrint('Unknown deep link target: $host');
    }
  }
}
