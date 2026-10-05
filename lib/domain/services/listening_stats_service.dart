import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';

final listeningStatsServiceProvider = Provider<ListeningStatsService>((ref) {
  final db = ref.watch(databaseProvider);
  return ListeningStatsService(db);
});

class ListeningStatsService {
  final AppDatabase _db;

  String? _currentTrackKey;
  int _currentDurationMs = 0;
  int _accumulatedListenMs = 0;
  bool _playRecorded = false;
  DateTime? _lastTickTime;

  ListeningStatsService(this._db);

  /// Called whenever the active track or playback state changes
  void onTrackChanged(String? newTrackKey, int durationMs) {
    if (_currentTrackKey != null && _currentTrackKey != newTrackKey) {
      _flushCurrentTrack(skipped: !_playRecorded);
    }

    _currentTrackKey = newTrackKey;
    _currentDurationMs = durationMs;
    _accumulatedListenMs = 0;
    _playRecorded = false;
    _lastTickTime = DateTime.now();
  }

  /// Called periodically during playback (e.g., from position stream ticks)
  void onPositionUpdate(int positionMs, bool isPlaying) {
    if (_currentTrackKey == null || !isPlaying) {
      _lastTickTime = null;
      return;
    }

    final now = DateTime.now();
    if (_lastTickTime != null) {
      final delta = now.difference(_lastTickTime!).inMilliseconds;
      if (delta > 0 && delta < 5000) {
        _accumulatedListenMs += delta;
      }
    }
    _lastTickTime = now;

    // Check completion threshold: >= 30s or >= 50% of track
    if (!_playRecorded && _accumulatedListenMs > 0) {
      final thresholdMs = _currentDurationMs > 0
          ? (_currentDurationMs * 0.5).round().clamp(0, 30000)
          : 30000;

      if (_accumulatedListenMs >= thresholdMs) {
        _playRecorded = true;
        _db.recordPlayCompleted(
          _currentTrackKey!,
          listenedMs: _accumulatedListenMs,
        );
      }
    }
  }

  void _flushCurrentTrack({required bool skipped}) {
    if (_currentTrackKey == null) return;

    if (skipped && _accumulatedListenMs < 10000 && _accumulatedListenMs > 500) {
      _db.recordSkip(_currentTrackKey!);
    }
  }

  /// Manually record an explicit completed play
  Future<void> recordPlay(String trackKey, {int listenedMs = 0}) {
    return _db.recordPlayCompleted(trackKey, listenedMs: listenedMs);
  }

  /// Manually record an explicit skip
  Future<void> recordSkip(String trackKey) {
    return _db.recordSkip(trackKey);
  }
}
