import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/db/app_database.dart';
import '../domain/services/queue_manager.dart';

/// Background AudioHandler managing AudioService MediaSession,
/// AudioSession focus & noisy events, and just_audio playback engine.
class SonaraAudioHandler extends BaseAudioHandler with SeekHandler {
  SonaraAudioHandler({
    required this.queueManager,
    this.db,
    AudioPlayer? player,
    bool enablePersistenceTimer = true,
  }) : _player = player ?? AudioPlayer() {
    _initAudioSession();
    _listenToPlayerEvents();
    _listenToQueueManager();
    if (enablePersistenceTimer) {
      _startPersistenceTimer();
    }
  }

  final QueueManager queueManager;
  final AppDatabase? db;
  final AudioPlayer _player;

  Timer? _persistTimer;
  bool _wasPlayingBeforeInterruption = false;
  int _consecutiveErrors = 0;
  ConcatenatingAudioSource? _audioSource;
  bool _isSwitchingSource = false;

  AudioPlayer get player => _player;

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.3);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _wasPlayingBeforeInterruption = _player.playing;
              pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              if (_wasPlayingBeforeInterruption) {
                play();
              }
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      session.becomingNoisyEventStream.listen((_) {
        // Unplugged / Bluetooth disconnected
        pause();
      });
    } catch (e) {
      debugPrint('AudioSession setup skipped: $e');
    }
  }

  void _listenToPlayerEvents() {
    // 1. Broadcast playback state to MediaSession and notification
    _player.playbackEventStream.listen(
      _broadcastPlaybackState,
      onError: (Object e, StackTrace st) {
        debugPrint('Playback error event: $e');
        _handlePlaybackError();
      },
    );

    _player.playerStateStream.listen((state) {
      _broadcastPlaybackState(_player.playbackEvent);
      if (!state.playing) {
        // Persist queue and position on pause
        queueManager.persistState(positionMs: _player.position.inMilliseconds);
      }
    });

    // 2. Decoder duration reconciliation (Pitfall 6 in PRD / AGENTS.md)
    _player.durationStream.listen((duration) {
      if (duration != null && queueManager.currentTrack != null) {
        final current = queueManager.currentTrack!;
        final diff = (duration.inMilliseconds - current.durationMs).abs();
        if (diff > 1000) {
          db?.updateTrackDuration(current.trackKey, duration.inMilliseconds);
          _updateCurrentMediaItem(duration: duration);
        }
      }
    });

    // 3. Gapless sliding window progression
    _player.currentIndexStream.listen((index) {
      if (_isSwitchingSource || index == null) return;
      if (index > 0) {
        // Player smoothly finished current track and transitioned to next track in sliding window
        queueManager.advanceToNext();
        _reloadSlidingWindow(resumePlaying: _player.playing);
      }
    });
  }

  void _listenToQueueManager() {
    queueManager.stateStream.listen((state) {
      _syncMediaItemFromQueue();
    });
  }

  void _startPersistenceTimer() {
    _persistTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_player.playing) {
        queueManager.persistState(positionMs: _player.position.inMilliseconds);
      }
    });
  }

  void _broadcastPlaybackState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = _mapProcessingState(_player.processingState);

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: queueManager.currentIndex,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> _syncMediaItemFromQueue() async {
    final current = queueManager.currentTrack;
    if (current == null) {
      mediaItem.add(null);
      return;
    }

    String? artistName;
    String? albumTitle;
    if (db != null) {
      artistName = await db!.getArtistName(current.artistId);
      albumTitle = await db!.getAlbumTitle(current.albumId);
    }

    final item = MediaItem(
      id: current.trackKey,
      title: current.title,
      artist: artistName ?? 'Unknown Artist',
      album: albumTitle ?? 'Unknown Album',
      duration: Duration(milliseconds: current.durationMs),
      artUri: current.artworkKey != null
          ? Uri.parse(
              'content://media/external/audio/albumart/${current.albumId ?? 0}',
            )
          : null,
    );
    mediaItem.add(item);
  }

  void _updateCurrentMediaItem({required Duration duration}) {
    final current = mediaItem.value;
    if (current != null) {
      mediaItem.add(current.copyWith(duration: duration));
    }
  }

  /// Reloads sliding window into just_audio player
  Future<void> _reloadSlidingWindow({
    bool resumePlaying = true,
    Duration? initialPosition,
  }) async {
    final window = queueManager.getSlidingWindow(windowSize: 5);
    if (window.isEmpty) {
      await _player.stop();
      _audioSource = null;
      return;
    }

    _isSwitchingSource = true;
    try {
      final children = <AudioSource>[];
      for (final track in window) {
        final uri = Uri.parse(track.contentUri);
        children.add(
          AudioSource.uri(
            uri,
            tag: MediaItem(
              id: track.trackKey,
              title: track.title,
              artist: 'Unknown Artist',
              duration: Duration(milliseconds: track.durationMs),
            ),
          ),
        );
      }

      _audioSource = ConcatenatingAudioSource(children: children);
      await _player.setAudioSource(
        _audioSource!,
        initialPosition: initialPosition,
        initialIndex: 0,
      );
      _consecutiveErrors = 0;

      if (resumePlaying) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('Failed to load sliding window: $e');
      _handlePlaybackError();
    } finally {
      _isSwitchingSource = false;
    }
  }

  void _handlePlaybackError() {
    _consecutiveErrors++;
    final current = queueManager.currentTrack;
    if (current != null) {
      db?.markTrackMissing(current.trackKey);
    }

    if (_consecutiveErrors >= 5 || queueManager.queue.length <= 1) {
      debugPrint('Too many consecutive playback failures. Pausing.');
      pause();
      _consecutiveErrors = 0;
    } else {
      debugPrint('Corrupt or missing file, skipping smoothly to next track.');
      skipToNext();
    }
  }

  @override
  Future<void> play() async {
    if (queueManager.currentTrack == null && queueManager.queue.isNotEmpty) {
      queueManager.jumpToIndex(0);
      await _reloadSlidingWindow(resumePlaying: true);
      return;
    }
    if (_audioSource == null && queueManager.currentTrack != null) {
      await _reloadSlidingWindow(resumePlaying: true);
      return;
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    final hasNext = queueManager.advanceToNext();
    if (hasNext) {
      await _reloadSlidingWindow(resumePlaying: _player.playing);
    } else {
      await _player.stop();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final hasPrev = queueManager.retreatToPrevious();
    if (hasPrev) {
      await _reloadSlidingWindow(resumePlaying: _player.playing);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    queueManager.setShuffle(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        queueManager.setRepeatMode(QueueRepeatMode.off);
        break;
      case AudioServiceRepeatMode.one:
        queueManager.setRepeatMode(QueueRepeatMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        queueManager.setRepeatMode(QueueRepeatMode.all);
        break;
    }
  }

  /// Sets entire queue and starts playing
  Future<void> playQueue(
    List<Track> tracks, {
    int initialIndex = 0,
    bool? shuffle,
  }) async {
    queueManager.setQueue(tracks, initialIndex: initialIndex, shuffle: shuffle);
    await _reloadSlidingWindow(resumePlaying: true);
  }

  /// Plays a single track immediately
  Future<void> playTrack(Track track) async {
    queueManager.playNow(track);
    await _reloadSlidingWindow(resumePlaying: true);
  }

  /// Restores queue state from DB (called on app startup)
  Future<void> restoreSavedState() async {
    final result = await queueManager.restoreState();
    if (result.restored) {
      await _syncMediaItemFromQueue();
      await _reloadSlidingWindow(
        resumePlaying: false,
        initialPosition: Duration(milliseconds: result.positionMs),
      );
    }
  }

  Future<void> dispose() async {
    _persistTimer?.cancel();
    await _player.dispose();
  }
}
