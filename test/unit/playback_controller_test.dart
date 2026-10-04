import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';

void main() {
  group('StubPlaybackController', () {
    late StubPlaybackController controller;

    setUp(() {
      controller = StubPlaybackController();
    });

    test('initial state is idle and toggles play/pause', () async {
      expect(controller.currentSnapshot.isPlaying, isFalse);

      await controller.play();
      expect(controller.currentSnapshot.isPlaying, isTrue);
      expect(controller.currentSnapshot.state, equals(PlaybackState.playing));

      await controller.pause();
      expect(controller.currentSnapshot.isPlaying, isFalse);
      expect(controller.currentSnapshot.state, equals(PlaybackState.paused));

      await controller.togglePlayPause();
      expect(controller.currentSnapshot.isPlaying, isTrue);

      await controller.togglePlayPause();
      expect(controller.currentSnapshot.isPlaying, isFalse);
    });

    test('controller streams snapshot updates', () async {
      final snapshot = await controller.snapshotStream.first;
      expect(snapshot.title, equals('Welcome to Sonara'));
    });

    test('invoking stub control methods completes safely', () async {
      await controller.skipToNext();
      await controller.skipToPrevious();
      await controller.seek(const Duration(seconds: 45));
      await controller.setShuffle(true);
      await controller.setRepeatMode(1);
    });
  });
}
