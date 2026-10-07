import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/utils/pitch_calculator.dart';
import '../data/db/app_database.dart';
import '../domain/models/audio_settings.dart';
import '../domain/services/device_profile_service.dart';
import '../domain/services/long_audio_service.dart';
import '../domain/services/queue_manager.dart';
import '../domain/services/replay_gain_calculator.dart';

/// Background AudioHandler managing AudioService MediaSession,
/// AudioSession focus & noisy events, and just_audio playback engine.
class SonaraAudioHandler extends BaseAudioHandler with SeekHandler {
  SonaraAudioHandler({
    required QueueManager queueManager,
    AppDatabase? db,
    LongAudioService? longAudioService,
    DeviceProfileService? deviceProfileService,
    AudioPlayer? player,
    AndroidEqualizer? equalizer,
    AndroidLoudnessEnhancer? loudnessEnhancer,
    bool enablePersistenceTimer = true,
  }) : this._fromEffects(
         queueManager: queueManager,
         db: db,
         longAudioService: longAudioService,
         deviceProfileService: deviceProfileService,
         effects: player != null
             ? (player, equalizer, loudnessEnhancer)
             : _createDefaultEffects(),
         enablePersistenceTimer: enablePersistenceTimer,
       );

  SonaraAudioHandler._fromEffects({
    required this.queueManager,
    this.db,
    this.longAudioService,
    this.deviceProfileService,
    required (AudioPlayer, AndroidEqualizer?, AndroidLoudnessEnhancer?) effects,
    bool enablePersistenceTimer = true,
  }) : _player = effects.$1,
       equalizer = effects.$2,
       loudnessEnhancer = effects.$3 {
    _initAudioSession();
    _listenToPlayerEvents();
    _listenToQueueManager();
    if (enablePersistenceTimer) {
      _startPersistenceTimer();
    }
  }

  static (AudioPlayer, AndroidEqualizer?, AndroidLoudnessEnhancer?)
  _createDefaultEffects() {
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
  final DeviceProfileService? deviceProfileService;
  final AndroidEqualizer? equalizer;
  final AndroidLoudnessEnhancer? loudnessEnhancer;
  final AudioPlayer _player;

  AudioSettings _audioSettings = const AudioSettings();
  int _pitchSemitones = 0;
  int get pitchSemitones => _pitchSemitones;
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

      session.devicesChangedEventStream.listen((event) async {
        try {
          final devices = await session.getDevices();
          await deviceProfileService?.handleDevicesChanged(devices);
        } catch (e) {
          debugPrint('Devices changed listener skipped: $e');
        }
      });

      try {
        final initialDevices = await session.getDevices();
        await deviceProfileService?.handleDevicesChanged(initialDevices);
      } catch (_) {}
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
        final uri = Uri.parse(
          track.contentUri.isNotEmpty ? track.contentUri : track.path,
        );
        final mediaItem = MediaItem(
          id: track.trackKey,
          title: track.title,
          artist: 'Unknown Artist',
          duration: Duration(milliseconds: track.durationMs),
        );

        if (track.cueStartMs != null && track.cueEndMs != null) {
          children.add(
            ClippingAudioSource(
              child: AudioSource.uri(uri),
              start: Duration(milliseconds: track.cueStartMs!),
              end: Duration(milliseconds: track.cueEndMs!),
              tag: mediaItem,
            ),
          );
        } else {
          children.add(AudioSource.uri(uri, tag: mediaItem));
        }
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
      await _applyEqualizerSettings();
      await _applyLoudnessEnhancer();

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

  AndroidEqualizerParameters? _cachedEqualizerParams;
  bool _isApplyingEqualizer = false;
  bool _equalizerNeedsReapply = false;
  bool _isApplyingLoudness = false;
  bool _loudnessNeedsReapply = false;

  /// Apply audio settings from user preferences
  Future<void> applyAudioSettings(AudioSettings settings) async {
    _audioSettings = settings;

    // 1. Equalizer & Bass Boost
    await _applyEqualizerSettings();

    // 2. Loudness Enhancer
    await _applyLoudnessEnhancer();

    // 3. Skip Silence
    try {
      await _player.setSkipSilenceEnabled(settings.skipSilence);
    } catch (e) {
      debugPrint('Skip silence skipped: $e');
    }

    // 4. ReplayGain & Volume
    await _updateEffectiveVolume();

    // 5. Musical Pitch Transposition
    if (settings.pitchSemitones != _pitchSemitones) {
      await setPitchSemitones(settings.pitchSemitones);
    }
  }

  Future<void> _applyEqualizerSettings() async {
    if (equalizer == null) return;
    if (_isApplyingEqualizer) {
      _equalizerNeedsReapply = true;
      return;
    }
    _isApplyingEqualizer = true;
    try {
      do {
        _equalizerNeedsReapply = false;
        await equalizer!.setEnabled(_audioSettings.equalizerEnabled);
        if (!_audioSettings.equalizerEnabled) break;

        AndroidEqualizerParameters? params = _cachedEqualizerParams;
        if (params == null) {
          try {
            params = await equalizer!.parameters.timeout(
              const Duration(milliseconds: 350),
            );
            _cachedEqualizerParams = params;
          } on TimeoutException {
            debugPrint(
              'Equalizer parameters pending platform activation (deferred to playback)',
            );
            break;
          } catch (e) {
            debugPrint('Error retrieving equalizer parameters: $e');
            break;
          }
        }

        for (var i = 0; i < params.bands.length; i++) {
          var targetGain = 0.0;
          if (i < _audioSettings.bandGains.length) {
            targetGain = _audioSettings.bandGains[i];
          }

          // Apply Bass Boost: boost sub-bass (band 0, 60Hz) and mid-bass (band 1, 230Hz)
          if (_audioSettings.bassBoost > 0) {
            if (i == 0) {
              targetGain += _audioSettings.bassBoost * 6.0;
            } else if (i == 1) {
              targetGain += _audioSettings.bassBoost * 3.5;
            }
          }

          final clampedGain = targetGain.clamp(
            params.minDecibels,
            params.maxDecibels,
          );
          await params.bands[i].setGain(clampedGain);
        }
      } while (_equalizerNeedsReapply);
    } catch (e) {
      debugPrint('Equalizer apply error: $e');
    } finally {
      _isApplyingEqualizer = false;
    }
  }

  Future<void> _applyLoudnessEnhancer() async {
    if (loudnessEnhancer == null) return;
    if (_isApplyingLoudness) {
      _loudnessNeedsReapply = true;
      return;
    }
    _isApplyingLoudness = true;
    try {
      do {
        _loudnessNeedsReapply = false;
        final shouldEnable = _audioSettings.loudnessGain > 0;
        await loudnessEnhancer!.setEnabled(shouldEnable);
        if (shouldEnable) {
          await loudnessEnhancer!.setTargetGain(_audioSettings.loudnessGain);
        }
      } while (_loudnessNeedsReapply);
    } catch (e) {
      debugPrint('LoudnessEnhancer apply error: $e');
    } finally {
      _isApplyingLoudness = false;
    }
  }

  Future<void> setPitchSemitones(int semitones) async {
    _pitchSemitones = semitones.clamp(-12, 12);
    final multiplier = PitchCalculator.semitonesToMultiplier(_pitchSemitones);
    try {
      await _player.setPitch(multiplier);
    } catch (e) {
      debugPrint('Error setting player pitch: $e');
    }
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
    try {
      await _player.setVolume(_currentVolumeMultiplier.clamp(0.0, 1.0));
    } catch (_) {}
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
    try {
      await _player.setVolume(_currentVolumeMultiplier.clamp(0.0, 1.0));
    } catch (_) {}
    if (_cachedEqualizerParams == null &&
        equalizer != null &&
        _audioSettings.equalizerEnabled) {
      await _applyEqualizerSettings();
    }
    await _player.play();
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
    await _player.pause();
    try {
      await _player.setVolume(_currentVolumeMultiplier.clamp(0.0, 1.0));
    } catch (_) {}
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
      // 100ms smooth transition prevents abrupt hardware DAC pops on skip
      await Future<void>.delayed(const Duration(milliseconds: 100));
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
      await Future<void>.delayed(const Duration(milliseconds: 100));
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

  // ==========================================
  // ANDROID AUTO & MEDIABROWSERSERVICE SUPPORT
  // ==========================================

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    final database = db;
    if (database == null) return [];

    if (parentMediaId == AudioService.browsableRootId ||
        parentMediaId == 'root') {
      return const [
        MediaItem(id: 'root_playlists', title: 'Playlists', playable: false),
        MediaItem(id: 'root_liked', title: 'Liked Songs', playable: false),
        MediaItem(id: 'root_artists', title: 'Artists', playable: false),
        MediaItem(id: 'root_albums', title: 'Albums', playable: false),
        MediaItem(
          id: 'root_recents',
          title: 'Recently Played',
          playable: false,
        ),
      ];
    }

    if (parentMediaId == 'root_playlists') {
      final playlists = await database.getAllPlaylists();
      return playlists
          .map(
            (p) => MediaItem(
              id: 'playlist_${p.id}',
              title: p.name,
              playable: false,
            ),
          )
          .toList();
    }

    if (parentMediaId.startsWith('playlist_')) {
      final id = int.tryParse(parentMediaId.replaceFirst('playlist_', ''));
      if (id != null) {
        final tracks = await database.getPlaylistTracks(id);
        return _tracksToMediaItems(tracks);
      }
    }

    if (parentMediaId == 'root_liked') {
      final tracks = await database.getLikedTracks();
      return _tracksToMediaItems(tracks);
    }

    if (parentMediaId == 'root_artists') {
      final artists = await database.getAllArtists();
      return artists
          .map(
            (a) =>
                MediaItem(id: 'artist_${a.id}', title: a.name, playable: false),
          )
          .toList();
    }

    if (parentMediaId.startsWith('artist_')) {
      final id = int.tryParse(parentMediaId.replaceFirst('artist_', ''));
      if (id != null) {
        final tracks = await database.getTracksForArtist(id);
        return _tracksToMediaItems(tracks);
      }
    }

    if (parentMediaId == 'root_albums') {
      final albums = await database.getAllAlbums();
      return albums
          .map(
            (alb) => MediaItem(
              id: 'album_${alb.id}',
              title: alb.title,
              playable: false,
            ),
          )
          .toList();
    }

    if (parentMediaId.startsWith('album_')) {
      final id = int.tryParse(parentMediaId.replaceFirst('album_', ''));
      if (id != null) {
        final tracks = await database.getTracksForAlbum(id);
        return _tracksToMediaItems(tracks);
      }
    }

    if (parentMediaId == 'root_recents') {
      final tracks = await database.getRecentlyPlayedTracks();
      return _tracksToMediaItems(tracks);
    }

    return [];
  }

  Future<MediaItem?> getItem(String mediaId) async {
    final database = db;
    if (database == null) return null;
    final track = await database.getTrackByKey(mediaId);
    if (track == null) return null;
    final artistName = await database.getArtistName(track.artistId);
    final albumTitle = await database.getAlbumTitle(track.albumId);
    return _trackToMediaItem(track, artistName, albumTitle);
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final database = db;
    if (database == null) return;

    if (mediaId.startsWith('playlist_')) {
      final id = int.tryParse(mediaId.replaceFirst('playlist_', ''));
      if (id != null) {
        final tracks = await database.getPlaylistTracks(id);
        if (tracks.isNotEmpty) {
          await playQueue(tracks);
        }
      }
      return;
    }

    if (mediaId.startsWith('artist_')) {
      final id = int.tryParse(mediaId.replaceFirst('artist_', ''));
      if (id != null) {
        final tracks = await database.getTracksForArtist(id);
        if (tracks.isNotEmpty) {
          await playQueue(tracks);
        }
      }
      return;
    }

    if (mediaId.startsWith('album_')) {
      final id = int.tryParse(mediaId.replaceFirst('album_', ''));
      if (id != null) {
        final tracks = await database.getTracksForAlbum(id);
        if (tracks.isNotEmpty) {
          await playQueue(tracks);
        }
      }
      return;
    }

    if (mediaId == 'root_liked') {
      final tracks = await database.getLikedTracks();
      if (tracks.isNotEmpty) {
        await playQueue(tracks);
      }
      return;
    }

    // Play specific track
    final track = await database.getTrackByKey(mediaId);
    if (track != null) {
      final allTracks = await database.getAllTracks();
      final idx = allTracks.indexWhere((t) => t.trackKey == track.trackKey);
      if (idx >= 0) {
        await playQueue(allTracks, initialIndex: idx);
      } else {
        await playTrack(track);
      }
    }
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final database = db;
    if (database == null) return [];
    final results = await database.searchTracksFts(query);
    return _tracksToMediaItems(results);
  }

  Future<List<MediaItem>> _tracksToMediaItems(List<Track> tracks) async {
    final database = db;
    final items = <MediaItem>[];
    for (final t in tracks) {
      final artistName = database != null
          ? await database.getArtistName(t.artistId)
          : null;
      final albumTitle = database != null
          ? await database.getAlbumTitle(t.albumId)
          : null;
      items.add(_trackToMediaItem(t, artistName, albumTitle));
    }
    return items;
  }

  MediaItem _trackToMediaItem(
    Track t, [
    String? artistName,
    String? albumTitle,
  ]) {
    return MediaItem(
      id: t.trackKey,
      title: t.title,
      artist: artistName ?? 'Unknown Artist',
      album: albumTitle ?? 'Unknown Album',
      duration: Duration(milliseconds: t.durationMs),
      artUri: t.artworkKey != null
          ? Uri.parse(
              'content://media/external/audio/albumart/${t.albumId ?? 0}',
            )
          : null,
      playable: true,
    );
  }

  Future<void> dispose() async {
    _persistTimer?.cancel();
    await _player.dispose();
  }
}
