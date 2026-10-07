import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/playback_controller.dart';
import '../../audio/sleep_timer.dart';
import 'haptic_service.dart';

final gestureSensorServiceProvider = Provider<GestureSensorService>((ref) {
  final sleepTimer = ref.watch(sleepTimerProvider.notifier);
  final playback = ref.watch(playbackControllerProvider);
  final haptics = ref.watch(hapticServiceProvider);

  final service = GestureSensorService(
    sleepTimer: sleepTimer,
    playback: playback,
    haptics: haptics,
  );

  // Auto-listen when sleep timer becomes active or when enabled
  ref.listen<SleepTimerState>(sleepTimerProvider, (prev, next) {
    if (next.isActive && !(prev?.isActive ?? false)) {
      service.startListening();
    } else if (!next.isActive && (prev?.isActive ?? false)) {
      service.stopListening();
    }
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

class GestureSensorService {
  GestureSensorService({
    required this.sleepTimer,
    required this.playback,
    required this.haptics,
    EventChannel? eventChannel,
  }) : _eventChannel =
           eventChannel ?? const EventChannel('com.example.sonara/sensors');

  final SleepTimerController sleepTimer;
  final PlaybackController playback;
  final HapticService haptics;
  final EventChannel _eventChannel;

  StreamSubscription<dynamic>? _subscription;
  bool _isListening = false;
  bool get isListening => _isListening;

  /// Starts listening to the native accelerometer and gesture events.
  void startListening() {
    if (_isListening) return;
    _isListening = true;

    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (data) {
          if (data is Map) {
            final event = data['event'] as String?;
            _handleEvent(event);
          }
        },
        onError: (Object e) {
          debugPrint('GestureSensorService error: $e');
        },
      );
    } catch (e) {
      debugPrint('GestureSensorService startListening failed: $e');
    }
  }

  /// Stops listening and unregisters native sensor listeners (0% battery drain).
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  void _handleEvent(String? event) {
    if (event == 'shake') {
      onShakeDetected();
    } else if (event == 'flip_face_down') {
      onFlipFaceDownDetected();
    }
  }

  /// Triggered on device shake gesture.
  void onShakeDetected() {
    if (sleepTimer.isActive) {
      haptics.heavy();
      sleepTimer.extendTimer(additionalDuration: const Duration(minutes: 15));
    }
  }

  /// Triggered when device is flipped face-down flat.
  void onFlipFaceDownDetected() {
    if (playback.currentSnapshot.isPlaying) {
      haptics.medium();
      unawaited(playback.pause());
    }
  }

  void dispose() {
    stopListening();
  }
}
