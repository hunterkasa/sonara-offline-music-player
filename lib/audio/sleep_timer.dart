import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'playback_controller.dart';
import 'sonara_audio_handler.dart';

enum SleepTimerMode { none, duration, endOfTrack }

@immutable
class SleepTimerState {
  const SleepTimerState({
    this.mode = SleepTimerMode.none,
    this.remaining = Duration.zero,
    this.totalDuration = Duration.zero,
    this.isActive = false,
  });

  final SleepTimerMode mode;
  final Duration remaining;
  final Duration totalDuration;
  final bool isActive;

  SleepTimerState copyWith({
    SleepTimerMode? mode,
    Duration? remaining,
    Duration? totalDuration,
    bool? isActive,
  }) {
    return SleepTimerState(
      mode: mode ?? this.mode,
      remaining: remaining ?? this.remaining,
      totalDuration: totalDuration ?? this.totalDuration,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SleepTimerController extends StateNotifier<SleepTimerState> {
  SleepTimerController({
    required this.audioHandler,
    required this.playbackController,
  }) : super(const SleepTimerState());

  final SonaraAudioHandler? audioHandler;
  final PlaybackController playbackController;

  Timer? _countdownTimer;
  StreamSubscription<dynamic>? _trackEndSubscription;
  String? _initialTrackKey;

  /// Starts a duration-based timer with gentle fade-out in the last 20 seconds.
  void startTimer(Duration duration) {
    cancelTimer();

    state = SleepTimerState(
      mode: SleepTimerMode.duration,
      remaining: duration,
      totalDuration: duration,
      isActive: true,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remaining.inSeconds <= 1) {
        _onTimerExpired();
      } else {
        final newRemaining = state.remaining - const Duration(seconds: 1);
        _handleFadeOut(newRemaining);
        state = state.copyWith(remaining: newRemaining);
      }
    });
  }

  /// Sets timer to pause at the end of the currently playing track.
  void startEndOfTrack() {
    cancelTimer();

    _initialTrackKey = playbackController.currentSnapshot.currentTrackKey;
    state = const SleepTimerState(
      mode: SleepTimerMode.endOfTrack,
      remaining: Duration.zero,
      totalDuration: Duration.zero,
      isActive: true,
    );

    // Listen to snapshot changes. When track changes or completes, pause and cancel.
    _trackEndSubscription = playbackController.snapshotStream.listen((
      snapshot,
    ) {
      if (state.isActive && state.mode == SleepTimerMode.endOfTrack) {
        if (snapshot.currentTrackKey != _initialTrackKey ||
            snapshot.state == PlaybackState.idle) {
          _onTimerExpired();
        }
      }
    });
  }

  /// Extends active timer by [additionalDuration] (default +15 minutes).
  void extendTimer({
    Duration additionalDuration = const Duration(minutes: 15),
  }) {
    if (!state.isActive) return;

    if (state.mode == SleepTimerMode.duration) {
      final newRemaining = state.remaining + additionalDuration;
      final newTotal = state.totalDuration + additionalDuration;
      // Reset volume in case fade-out was already active
      unawaited(audioHandler?.player.setVolume(1.0));
      state = state.copyWith(remaining: newRemaining, totalDuration: newTotal);
    }
  }

  /// Cancels any active sleep timer and restores volume to full.
  void cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _trackEndSubscription?.cancel();
    _trackEndSubscription = null;
    _initialTrackKey = null;

    unawaited(audioHandler?.player.setVolume(1.0));

    state = const SleepTimerState();
  }

  void _handleFadeOut(Duration remaining) {
    if (audioHandler == null) return;
    const fadeOutWindow = Duration(seconds: 20);

    if (remaining <= fadeOutWindow) {
      final ratio = (remaining.inMilliseconds / fadeOutWindow.inMilliseconds)
          .clamp(0.0, 1.0);
      unawaited(audioHandler!.player.setVolume(ratio));
    } else {
      unawaited(audioHandler!.player.setVolume(1.0));
    }
  }

  Future<void> _onTimerExpired() async {
    cancelTimer();
    await playbackController.pause();
    await audioHandler?.player.setVolume(1.0);
  }

  @override
  void dispose() {
    cancelTimer();
    super.dispose();
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerController, SleepTimerState>((ref) {
      final audioHandler = ref.watch(audioHandlerProvider);
      final playback = ref.watch(playbackControllerProvider);
      return SleepTimerController(
        audioHandler: audioHandler,
        playbackController: playback,
      );
    });
