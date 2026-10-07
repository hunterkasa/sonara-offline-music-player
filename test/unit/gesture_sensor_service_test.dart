import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/audio/sleep_timer.dart';
import 'package:sonara/core/services/gesture_sensor_service.dart';
import 'package:sonara/core/services/haptic_service.dart';

class FakeSleepTimerController extends SleepTimerController {
  FakeSleepTimerController({bool initialActive = false})
    : _fakeActive = initialActive,
      super(audioHandler: null, playbackController: FakePlaybackController());

  bool _fakeActive;
  Duration extendedBy = Duration.zero;

  @override
  bool get isActive => _fakeActive;

  void setActive(bool active) {
    _fakeActive = active;
  }

  @override
  void extendTimer({
    Duration additionalDuration = const Duration(minutes: 15),
  }) {
    extendedBy += additionalDuration;
  }
}

class FakePlaybackController extends StubPlaybackController {
  bool pauseCalled = false;
  bool isPlayingState = false;

  @override
  PlaybackSnapshot get currentSnapshot => PlaybackSnapshot(
    state: isPlayingState ? PlaybackState.playing : PlaybackState.paused,
  );

  @override
  Future<void> pause() async {
    pauseCalled = true;
    isPlayingState = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeSleepTimerController sleepTimer;
  late FakePlaybackController playback;
  late HapticService haptics;
  late GestureSensorService service;

  setUp(() {
    container = ProviderContainer();
    sleepTimer = FakeSleepTimerController();
    playback = FakePlaybackController();
    haptics = container.read(hapticServiceProvider);

    service = GestureSensorService(
      sleepTimer: sleepTimer,
      playback: playback,
      haptics: haptics,
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('onShakeDetected extends sleep timer when sleep timer is active', () {
    sleepTimer.setActive(true);

    service.onShakeDetected();

    expect(sleepTimer.extendedBy, equals(const Duration(minutes: 15)));
  });

  test(
    'onShakeDetected does not extend timer when sleep timer is inactive',
    () {
      sleepTimer.setActive(false);

      service.onShakeDetected();

      expect(sleepTimer.extendedBy, equals(Duration.zero));
    },
  );

  test('onFlipFaceDownDetected pauses playback when playing', () {
    playback.isPlayingState = true;

    service.onFlipFaceDownDetected();

    expect(playback.pauseCalled, isTrue);
  });

  test('onFlipFaceDownDetected does nothing when already paused or idle', () {
    playback.isPlayingState = false;

    service.onFlipFaceDownDetected();

    expect(playback.pauseCalled, isFalse);
  });
}
