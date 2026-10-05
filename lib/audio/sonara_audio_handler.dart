import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/db/app_database.dart';
import '../domain/models/audio_settings.dart';
import '../domain/services/long_audio_service.dart';
import '../domain/services/queue_manager.dart';
import '../domain/services/replay_gain_calculator.dart';

/// Background AudioHandler managing AudioService MediaSession,
/// AudioSession focus & noisy events, and just_audio playback engine.
class SonaraAudioHandler extends BaseAudioHandler with SeekHandler {
  SonaraAudioHandler({
    required this.queueManager,
    this.db,
    this.longAudioService,
    AudioPlayer? player,
    AndroidEqualizer? equalizer,
    AndroidLoudnessEnhancer? loudnessEnhancer,
    bool enablePersistenceTimer = true,
  }) : equalizer = equalizer ?? (player == null ? _defaultEffects.$2 : null),
       loudnessEnhancer =
           loudnessEnhancer ?? (player == null ? _defaultEffects.$3 : null),
       _player = player ?? _defaultEffects.$1 {
    _initAudioSession();
    _listenToPlayerEvents();
    _listenToQueueManager();
    if (enablePersistenceTimer) {
      _startPersistenceTimer();
    }
  }

  static (AudioPlayer, AndroidEqualizer?, AndroidLoudnessEnhancer?)
  get _defaultEffects {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final eq = AndroidEqualizer();
        final le = AndroidLoudnessEnhancer();
        final pipeline = AudioPipeline(androidAudioEffects: [eq, le]);
        final player = AudioPlayer(audioPipeline: pipeline);
        return (player, eq, le);
      } catch (e) {
        debugPrint('AudioPipeline creation skipped: $e');
      }
    }
    return (AudioPlayer(), null, null);
  }

  final QueueManager queueManager;
  final AppDatabase? db;
  final LongAudioService? longAudioService;
  final AndroidEqualizer? equalizer;
  final AndroidLoudnessEnhancer? loudnessEnhancer;
  final AudioPlayer _player;

  AudioSettings _audioSettings = const AudioSettings();
  double _currentVolumeMultiplier = 1.0;
  Timer? _persistTimer;
  bool _wasPlayingBeforeInterruption = false;
  int _consecutiveErrors = 0;
  ConcatenatingAudioSource? _audioSource;
  bool _isSwitchingSource = false;

  AudioPlayer get player => _player;
  AudioSettings get audioSettings => _audioSettings;

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
        final current = queueManager.currentTrack;
        final pos = _player.position.inMilliseconds;
        queueManager.persistState(positionMs: pos);

        // Long-audio memory persistence (>= 20m)
        if (_audioSettings.longAudioPositionMemory &&
            current != null &&
            (longAudioService?.isLongAudio(current.durationMs) ?? false)) {
          longAudioService?.savePosition(
            current.trackKey,
            positionMs: pos,
            speed: _player.speed,
          );
        }
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

      var targetPosition = initialPosition;
      if (targetPosition == null &&
          _audioSettings.longAudioPositionMemory &&
          window.isNotEmpty &&
          (longAudioService?.isLongAudio(window.first.durationMs) ?? false)) {
        final saved = await longAudioService?.getSavedPosition(
          window.first.trackKey,
        );
        if (saved != null && saved.positionMs > 10000) {
          targetPosition = Duration(milliseconds: saved.positionMs);
          if (saved.speed != 1.0) {
            await setSpeed(saved.speed);
          }
        }
      }

      _audioSource = ConcatenatingAudioSource(children: children);
      await _player.setAudioSource(
        _audioSource!,
        initialPosition: targetPosition,
        initialIndex: 0,
      );
      _consecutiveErrors = 0;

      await _updateEffectiveVolume();

      if (resumePlaying) {
        if (_audioSettings.smoothFades) {
          try {
            await _player.setVolume(0.0);
          } catch (_) {}
          await _player.play();
          await _fadeVolume(from: 0.0, to: _currentVolumeMultiplier);
        } else {
          await _player.play();
        }
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

  Future<void> _fadeVolume({
    required double from,
    required double to,
    Duration duration = const Duration(milliseconds: 200),
  }) async {
    const steps = 4;
    final stepDuration = Duration(
      milliseconds: duration.inMilliseconds ~/ steps,
    );
    final delta = (to - from) / steps;
    var current = from;
    for (var i = 0; i < steps; i++) {
      current += delta;
      try {
        await _player.setVolume(current.clamp(0.0, 1.0));
      } catch (_) {}
      await Future<void>.delayed(stepDuration);
    }
    try {
      await _player.setVolume(to.clamp(0.0, 1.0));
    } catch (_) {}
  }

  /// Apply audio settings from user preferences
  Future<void> applyAudioSettings(AudioSettings settings) async {
    _audioSettings = settings;

    // 1. Equalizer
    if (equalizer != null) {
      try {
        await equalizer!.setEnabled(settings.equalizerEnabled);
        if (settings.equalizerEnabled) {
          final params = await equalizer!.parameters;
          for (var i = 0; i < params.bands.length; i++) {
            if (i < settings.bandGains.length) {
              final gain = settings.bandGains[i].clamp(
                params.minDecibels,
                params.maxDecibels,
              );
              await params.bands[i].setGain(gain);
            }
          }
        }
      } catch (e) {
        debugPrint('Equalizer apply skipped: $e');
      }
    }

    // 2. Loudness Enhancer
    if (loudnessEnhancer != null) {
      try {
        final shouldEnable = settings.loudnessGain > 0;
        await loudnessEnhancer!.setEnabled(shouldEnable);
        if (shouldEnable) {
          await loudnessEnhancer!.setTargetGain(settings.loudnessGain);
        }
      } catch (e) {
        debugPrint('LoudnessEnhancer apply skipped: $e');
      }
    }

    // 3. Skip Silence
    try {
      await _player.setSkipSilenceEnabled(settings.skipSilence);
    } catch (e) {
      debugPrint('Skip silence skipped: $e');
    }

    // 4. ReplayGain & Volume
    await _updateEffectiveVolume();
  }

  Future<void> _updateEffectiveVolume() async {
    final current = queueManager.currentTrack;
    final multiplier = ReplayGainCalculator.computeVolumeMultiplier(
      trackGainDb: current?.replayGainTrackDb,
      albumGainDb: current?.replayGainAlbumDb,
      mode: _audioSettings.replayGainMode,
      preAmpDb: _audioSettings.replayGainPreAmpDb,
      preventClipping: _audioSettings.preventClipping,
      isShuffle: queueManager.state.shuffleEnabled,
    );
    _currentVolumeMultiplier = multiplier;
    if (_player.playing) {
      try {
        await _player.setVolume(_currentVolumeMultiplier.clamp(0.0, 1.0));
      } catch (_) {}
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
    if (_audioSettings.smoothFades) {
      try {
        await _player.setVolume(0.0);
      } catch (_) {}
      await _player.play();
      await _fadeVolume(from: 0.0, to: _currentVolumeMultiplier);
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    final current = queueManager.currentTrack;
    if (current != null &&
        _audioSettings.longAudioPositionMemory &&
        (longAudioService?.isLongAudio(current.durationMs) ?? false)) {
      await longAudioService?.savePosition(
        current.trackKey,
        positionMs: _player.position.inMilliseconds,
        speed: _player.speed,
      );
    }

    if (_audioSettings.smoothFades && _player.playing) {
      await _fadeVolume(from: _currentVolumeMultiplier, to: 0.0);
      await _player.pause();
      try {
        await _player.setVolume(_currentVolumeMultiplier.clamp(0.0, 1.0));
      } catch (_) {}
    } else {
      await _player.pause();
    }
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

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _broadcastPlaybackState(_player.playbackEvent);
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
