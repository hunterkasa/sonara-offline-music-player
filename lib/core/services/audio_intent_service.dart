import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../audio/playback_controller.dart';
import '../../data/db/app_database.dart';

class AudioIntentService {
  AudioIntentService({required this.playbackController, required this.db});

  final PlaybackController playbackController;
  final AppDatabase db;

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
      debugPrint('Failed to handle external audio intent: $e');
    }
  }
}
