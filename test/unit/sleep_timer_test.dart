import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/audio/sleep_timer.dart';
import 'package:sonara/domain/models/audio_settings.dart';

void main() {
  group('SleepTimerController Unit Tests', () {
    late StubPlaybackController playback;
    late SleepTimerController controller;

    setUp(() {
      playback = StubPlaybackController();
      controller = SleepTimerController(
        audioHandler: null,
        playbackController: playback,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is idle and inactive', () {
      expect(controller.state.isActive, isFalse);
      expect(controller.state.mode, equals(SleepTimerMode.none));
      expect(controller.state.remaining, equals(Duration.zero));
    });

    test('startTimer initiates countdown state', () {
      controller.startTimer(const Duration(minutes: 20));
      expect(controller.state.isActive, isTrue);
      expect(controller.state.mode, equals(SleepTimerMode.duration));
      expect(controller.state.remaining, equals(const Duration(minutes: 20)));
      expect(
        controller.state.totalDuration,
        equals(const Duration(minutes: 20)),
      );
    });

    test('extendTimer increments remaining and total duration', () {
      controller.startTimer(const Duration(minutes: 15));
      controller.extendTimer(additionalDuration: const Duration(minutes: 15));

      expect(controller.state.remaining, equals(const Duration(minutes: 30)));
      expect(
        controller.state.totalDuration,
        equals(const Duration(minutes: 30)),
      );
    });

    test('cancelTimer resets state back to idle', () {
      controller.startTimer(const Duration(minutes: 45));
      expect(controller.state.isActive, isTrue);

      controller.cancelTimer();
      expect(controller.state.isActive, isFalse);
      expect(controller.state.mode, equals(SleepTimerMode.none));
      expect(controller.state.remaining, equals(Duration.zero));
    });

    test('startEndOfTrack sets endOfTrack mode', () {
      controller.startEndOfTrack();
      expect(controller.state.isActive, isTrue);
      expect(controller.state.mode, equals(SleepTimerMode.endOfTrack));
    });

    test('setFadeCurve updates state.fadeCurve accurately', () {
      expect(controller.state.fadeCurve, equals(SleepTimerFadeCurve.linear));

      controller.setFadeCurve(SleepTimerFadeCurve.logarithmic);
      expect(
        controller.state.fadeCurve,
        equals(SleepTimerFadeCurve.logarithmic),
      );

      controller.setFadeCurve(SleepTimerFadeCurve.exponential);
      expect(
        controller.state.fadeCurve,
        equals(SleepTimerFadeCurve.exponential),
      );
    });
  });
}
