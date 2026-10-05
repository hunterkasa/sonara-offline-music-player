import 'dart:async';
import 'dart:convert';

import '../../data/db/app_database.dart';
import 'shuffle_strategy.dart';

enum QueueRepeatMode { off, all, one }

class QueueState {
  const QueueState({
    required this.queue,
    required this.currentIndex,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.seed,
    required this.shuffledIndices,
  });

  final List<Track> queue;
  final int currentIndex;
  final bool shuffleEnabled;
  final QueueRepeatMode repeatMode;
  final int seed;
  final List<int> shuffledIndices;

  Track? get currentTrack => (currentIndex >= 0 && currentIndex < queue.length)
      ? queue[currentIndex]
      : null;

  QueueState copyWith({
    List<Track>? queue,
    int? currentIndex,
    bool? shuffleEnabled,
    QueueRepeatMode? repeatMode,
    int? seed,
    List<int>? shuffledIndices,
  }) {
    return QueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      seed: seed ?? this.seed,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
    );
  }
}

class QueueManager {
  QueueManager({this.db}) {
    _state = const QueueState(
      queue: [],
      currentIndex: -1,
      shuffleEnabled: false,
      repeatMode: QueueRepeatMode.off,
      seed: 0,
      shuffledIndices: [],
    );
  }

  final AppDatabase? db;
  final _stateController = StreamController<QueueState>.broadcast();

  late QueueState _state;

  QueueState get state => _state;
  List<Track> get queue => _state.queue;
  int get currentIndex => _state.currentIndex;
  Track? get currentTrack => _state.currentTrack;
  bool get shuffleEnabled => _state.shuffleEnabled;
  QueueRepeatMode get repeatMode => _state.repeatMode;
  Stream<QueueState> get stateStream => _stateController.stream;

  bool _isEmitting = false;
  QueueState? _pendingState;

  void _emit(QueueState newState) {
    _state = newState;
    if (_stateController.isClosed) return;
    if (_isEmitting) {
      _pendingState = newState;
      return;
    }
    _isEmitting = true;
    try {
      _stateController.add(_state);
    } finally {
      _isEmitting = false;
      if (_pendingState != null) {
        final pending = _pendingState!;
        _pendingState = null;
        _emit(pending);
      }
    }
  }

  /// Sets a new queue of tracks and sets the active track index.
  void setQueue(List<Track> tracks, {int initialIndex = 0, bool? shuffle}) {
    if (tracks.isEmpty) {
      clear();
      return;
    }

    final validIndex = initialIndex.clamp(0, tracks.length - 1);
    final useShuffle = shuffle ?? _state.shuffleEnabled;
    final seed = DateTime.now().millisecondsSinceEpoch;

    List<int> shuffled = [];
    if (useShuffle) {
      shuffled = ShuffleStrategy.generatePermutation(
        count: tracks.length,
        firstIndex: validIndex,
        seed: seed,
      );
    }

    _emit(
      QueueState(
        queue: List.unmodifiable(tracks),
        currentIndex: validIndex,
        shuffleEnabled: useShuffle,
        repeatMode: _state.repeatMode,
        seed: seed,
        shuffledIndices: List.unmodifiable(shuffled),
      ),
    );
  }

  /// Plays a single track immediately. If present in queue, jumps to it;
  /// otherwise inserts it after the current track and sets as active.
  void playNow(Track track) {
    final existingIndex = _state.queue.indexWhere(
      (t) => t.trackKey == track.trackKey,
    );
    if (existingIndex != -1) {
      jumpToIndex(existingIndex);
      return;
    }

    final newQueue = List<Track>.from(_state.queue);
    final insertPos =
        (_state.currentIndex >= 0 && _state.currentIndex < newQueue.length)
        ? _state.currentIndex + 1
        : newQueue.length;

    newQueue.insert(insertPos, track);

    // Rebuild shuffle if enabled
    List<int> shuffled = [];
    if (_state.shuffleEnabled) {
      shuffled = ShuffleStrategy.generatePermutation(
        count: newQueue.length,
        firstIndex: insertPos,
        seed: _state.seed,
      );
    }

    _emit(
      _state.copyWith(
        queue: List.unmodifiable(newQueue),
        currentIndex: insertPos,
        shuffledIndices: List.unmodifiable(shuffled),
      ),
    );
  }

  /// Inserts a track immediately after current track (Play Next).
  void playNext(Track track) {
    if (_state.queue.isEmpty) {
      setQueue([track]);
      return;
    }

    final newQueue = List<Track>.from(_state.queue);
    final insertPos = _state.currentIndex + 1;
    newQueue.insert(insertPos, track);

    // If shuffle is active, insert in shuffle order after current position
    List<int> newShuffled = [];
    if (_state.shuffleEnabled) {
      newShuffled = List<int>.from(_state.shuffledIndices);
      // Indices >= insertPos must be incremented by 1
      for (var i = 0; i < newShuffled.length; i++) {
        if (newShuffled[i] >= insertPos) {
          newShuffled[i] = newShuffled[i] + 1;
        }
      }
      final curShufflePos = newShuffled.indexOf(_state.currentIndex);
      final insertShufflePos = curShufflePos != -1
          ? curShufflePos + 1
          : newShuffled.length;
      newShuffled.insert(insertShufflePos, insertPos);
    }

    _emit(
      _state.copyWith(
        queue: List.unmodifiable(newQueue),
        shuffledIndices: List.unmodifiable(newShuffled),
      ),
    );
  }

  /// Appends a track to the end of the queue.
  void addToQueue(Track track) {
    if (_state.queue.isEmpty) {
      setQueue([track]);
      return;
    }

    final newQueue = List<Track>.from(_state.queue)..add(track);
    final newIndex = newQueue.length - 1;

    List<int> newShuffled = [];
    if (_state.shuffleEnabled) {
      newShuffled = List<int>.from(_state.shuffledIndices)..add(newIndex);
    }

    _emit(
      _state.copyWith(
        queue: List.unmodifiable(newQueue),
        shuffledIndices: List.unmodifiable(newShuffled),
      ),
    );
  }

  /// Removes track at [index].
  void removeAt(int index) {
    if (index < 0 || index >= _state.queue.length) return;

    final newQueue = List<Track>.from(_state.queue)..removeAt(index);
    if (newQueue.isEmpty) {
      clear();
      return;
    }

    var newCurrentIndex = _state.currentIndex;
    if (index < _state.currentIndex) {
      newCurrentIndex--;
    } else if (index == _state.currentIndex &&
        newCurrentIndex >= newQueue.length) {
      newCurrentIndex = newQueue.length - 1;
    }

    List<int> newShuffled = [];
    if (_state.shuffleEnabled) {
      for (final i in _state.shuffledIndices) {
        if (i == index) continue;
        newShuffled.add(i > index ? i - 1 : i);
      }
    }

    _emit(
      _state.copyWith(
        queue: List.unmodifiable(newQueue),
        currentIndex: newCurrentIndex,
        shuffledIndices: List.unmodifiable(newShuffled),
      ),
    );
  }

  /// Reorders a track from [oldIndex] to [newIndex].
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _state.queue.length) return;
    if (newIndex < 0 || newIndex >= _state.queue.length) return;
    if (oldIndex == newIndex) return;

    final newQueue = List<Track>.from(_state.queue);
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);

    var newCurrentIndex = _state.currentIndex;
    if (_state.currentIndex == oldIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < _state.currentIndex &&
        newIndex >= _state.currentIndex) {
      newCurrentIndex--;
    } else if (oldIndex > _state.currentIndex &&
        newIndex <= _state.currentIndex) {
      newCurrentIndex++;
    }

    _emit(
      _state.copyWith(
        queue: List.unmodifiable(newQueue),
        currentIndex: newCurrentIndex,
      ),
    );
  }

  /// Clears the queue.
  void clear() {
    _emit(
      _state.copyWith(
        queue: const [],
        currentIndex: -1,
        shuffledIndices: const [],
      ),
    );
  }

  /// Toggles or sets shuffle mode.
  void setShuffle(bool enable) {
    if (_state.shuffleEnabled == enable) return;

    if (!enable) {
      _emit(_state.copyWith(shuffleEnabled: false, shuffledIndices: const []));
      return;
    }

    final seed = DateTime.now().millisecondsSinceEpoch;
    final perm = ShuffleStrategy.generatePermutation(
      count: _state.queue.length,
      firstIndex: _state.currentIndex >= 0 ? _state.currentIndex : 0,
      seed: seed,
    );

    _emit(
      _state.copyWith(
        shuffleEnabled: true,
        seed: seed,
        shuffledIndices: List.unmodifiable(perm),
      ),
    );
  }

  /// Sets repeat mode (off, all, one).
  void setRepeatMode(QueueRepeatMode mode) {
    if (_state.repeatMode == mode) return;
    _emit(_state.copyWith(repeatMode: mode));
  }

  /// Jumps directly to a given logical index.
  void jumpToIndex(int index) {
    if (index < 0 || index >= _state.queue.length) return;
    _emit(_state.copyWith(currentIndex: index));
  }

  /// Returns the next logical track index according to shuffle and repeat modes.
  int? getNextIndex() {
    if (_state.queue.isEmpty) return null;

    if (_state.repeatMode == QueueRepeatMode.one) {
      return _state.currentIndex;
    }

    if (_state.shuffleEnabled && _state.shuffledIndices.isNotEmpty) {
      final currentPos = _state.shuffledIndices.indexOf(_state.currentIndex);
      if (currentPos == -1) return _state.shuffledIndices.first;

      final nextPos = currentPos + 1;
      if (nextPos < _state.shuffledIndices.length) {
        return _state.shuffledIndices[nextPos];
      }

      // Exhausted all shuffled tracks!
      if (_state.repeatMode == QueueRepeatMode.all) {
        // Regenerate new permutation for loop
        final newSeed = DateTime.now().millisecondsSinceEpoch;
        final newPerm = ShuffleStrategy.generatePermutation(
          count: _state.queue.length,
          seed: newSeed,
        );
        _emit(
          _state.copyWith(
            seed: newSeed,
            shuffledIndices: List.unmodifiable(newPerm),
          ),
        );
        return newPerm.isNotEmpty ? newPerm.first : null;
      }

      return null; // Queue finished
    }

    // Unshuffled sequential mode
    final next = _state.currentIndex + 1;
    if (next < _state.queue.length) {
      return next;
    }

    if (_state.repeatMode == QueueRepeatMode.all) {
      return 0;
    }

    return null;
  }

  /// Returns the previous logical track index according to shuffle and repeat modes.
  int? getPreviousIndex() {
    if (_state.queue.isEmpty) return null;

    if (_state.repeatMode == QueueRepeatMode.one) {
      return _state.currentIndex;
    }

    if (_state.shuffleEnabled && _state.shuffledIndices.isNotEmpty) {
      final currentPos = _state.shuffledIndices.indexOf(_state.currentIndex);
      if (currentPos > 0) {
        return _state.shuffledIndices[currentPos - 1];
      }
      if (_state.repeatMode == QueueRepeatMode.all) {
        return _state.shuffledIndices.last;
      }
      return _state.shuffledIndices.first;
    }

    final prev = _state.currentIndex - 1;
    if (prev >= 0) {
      return prev;
    }

    if (_state.repeatMode == QueueRepeatMode.all) {
      return _state.queue.length - 1;
    }

    return 0;
  }

  /// Advances to next track in queue.
  bool advanceToNext() {
    final next = getNextIndex();
    if (next != null) {
      _emit(_state.copyWith(currentIndex: next));
      return true;
    }
    return false;
  }

  /// Reverts to previous track in queue.
  bool retreatToPrevious() {
    final prev = getPreviousIndex();
    if (prev != null) {
      _emit(_state.copyWith(currentIndex: prev));
      return true;
    }
    return false;
  }

  /// Sliding window of tracks to load into AudioPlayer.
  /// Always includes [currentTrack] followed by upcoming tracks up to [windowSize].
  /// This prevents memory spikes or OOM when queue contains 20,000+ tracks.
  List<Track> getSlidingWindow({int windowSize = 5}) {
    if (_state.queue.isEmpty || _state.currentIndex < 0) return const [];

    final window = <Track>[];
    final current = _state.currentTrack;
    if (current == null) return const [];
    window.add(current);

    if (_state.repeatMode == QueueRepeatMode.one) {
      return window;
    }

    if (_state.shuffleEnabled && _state.shuffledIndices.isNotEmpty) {
      final currentPos = _state.shuffledIndices.indexOf(_state.currentIndex);
      if (currentPos != -1) {
        for (var i = 1; i < windowSize; i++) {
          final targetPos = currentPos + i;
          if (targetPos < _state.shuffledIndices.length) {
            final trackIndex = _state.shuffledIndices[targetPos];
            if (trackIndex < _state.queue.length) {
              window.add(_state.queue[trackIndex]);
            }
          } else if (_state.repeatMode == QueueRepeatMode.all) {
            final wrapPos = (targetPos) % _state.shuffledIndices.length;
            final trackIndex = _state.shuffledIndices[wrapPos];
            if (trackIndex < _state.queue.length) {
              window.add(_state.queue[trackIndex]);
            }
          }
        }
      }
      return window;
    }

    // Sequential mode
    for (var i = 1; i < windowSize; i++) {
      final nextIdx = _state.currentIndex + i;
      if (nextIdx < _state.queue.length) {
        window.add(_state.queue[nextIdx]);
      } else if (_state.repeatMode == QueueRepeatMode.all) {
        final wrapIdx = nextIdx % _state.queue.length;
        window.add(_state.queue[wrapIdx]);
      }
    }

    return window;
  }

  /// Persists current queue state to Drift DB.
  Future<void> persistState({required int positionMs}) async {
    final database = db;
    if (database == null) return;

    final keys = _state.queue.map((t) => t.trackKey).toList();
    await database.saveQueueState(
      currentTrackKey: _state.currentTrack?.trackKey,
      positionMs: positionMs,
      shuffle: _state.shuffleEnabled,
      repeatMode: _state.repeatMode.index,
      seed: _state.seed,
      queueJson: jsonEncode(keys),
    );
  }

  /// Restores queue state from Drift DB.
  Future<({bool restored, int positionMs})> restoreState() async {
    final database = db;
    if (database == null) return (restored: false, positionMs: 0);

    final saved = await database.getQueueState();
    if (saved == null || saved.queueJson.isEmpty) {
      return (restored: false, positionMs: 0);
    }

    try {
      final decoded = jsonDecode(saved.queueJson) as List<dynamic>;
      final keys = decoded.map((e) => e.toString()).toList();
      if (keys.isEmpty) return (restored: false, positionMs: 0);

      final restoredTracks = await database.getTracksByKeys(keys);
      if (restoredTracks.isEmpty) return (restored: false, positionMs: 0);

      var restoredIndex = 0;
      if (saved.currentTrackKey != null) {
        final found = restoredTracks.indexWhere(
          (t) => t.trackKey == saved.currentTrackKey,
        );
        if (found != -1) restoredIndex = found;
      }

      final repeat =
          (saved.repeatMode >= 0 &&
              saved.repeatMode < QueueRepeatMode.values.length)
          ? QueueRepeatMode.values[saved.repeatMode]
          : QueueRepeatMode.off;

      List<int> shuffled = [];
      if (saved.shuffle) {
        shuffled = ShuffleStrategy.generatePermutation(
          count: restoredTracks.length,
          firstIndex: restoredIndex,
          seed: saved.seed,
        );
      }

      _emit(
        QueueState(
          queue: List.unmodifiable(restoredTracks),
          currentIndex: restoredIndex,
          shuffleEnabled: saved.shuffle,
          repeatMode: repeat,
          seed: saved.seed,
          shuffledIndices: List.unmodifiable(shuffled),
        ),
      );

      return (restored: true, positionMs: saved.positionMs);
    } catch (_) {
      return (restored: false, positionMs: 0);
    }
  }

  void dispose() {
    _stateController.close();
  }
}
