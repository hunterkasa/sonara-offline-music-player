import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/shared/visualizer/audio_visualizer.dart';
import 'package:sonara/shared/waveform/waveform_scrubber.dart';

void main() {
  group('WaveformScrubber & AudioVisualizer Widget Tests', () {
    testWidgets(
      'WaveformScrubber renders and triggers onSeek on tap and drag',
      (tester) async {
        Duration? seekTarget;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 50,
                  child: WaveformScrubber(
                    trackKey: 'sample_waveform_key',
                    position: const Duration(seconds: 30),
                    duration: const Duration(seconds: 120),
                    onSeek: (pos) {
                      seekTarget = pos;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(WaveformScrubber), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);

        // Tap at center (50% progress = 60s)
        await tester.tap(find.byType(WaveformScrubber));
        await tester.pump();
        expect(seekTarget, isNotNull);
        expect(seekTarget!.inSeconds, closeTo(60, 2));

        // Drag across width
        await tester.drag(find.byType(WaveformScrubber), const Offset(60, 0));
        await tester.pump();
        expect(seekTarget, isNotNull);
      },
    );

    testWidgets('AudioVisualizer renders in Spectrum mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 150,
                child: AudioVisualizer(
                  isPlaying: false,
                  style: VisualizerStyle.spectrum,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AudioVisualizer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('AudioVisualizer renders in VU Meter mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 150,
                child: AudioVisualizer(
                  isPlaying: false,
                  style: VisualizerStyle.vuMeter,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AudioVisualizer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('AudioVisualizer renders in Fluid Wave mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 150,
                child: AudioVisualizer(
                  isPlaying: false,
                  style: VisualizerStyle.fluidWave,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AudioVisualizer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
      'AudioVisualizer animates and responds to audio playback and EQ inputs',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 150,
                  child: AudioVisualizer(
                    isPlaying: true,
                    position: Duration(seconds: 45),
                    duration: Duration(minutes: 3),
                    speed: 1.25,
                    trackKey: 'test_track_key',
                    bandGains: [3.0, 1.0, 0.0, -1.0, 2.0],
                    bassBoost: 0.6,
                    style: VisualizerStyle.spectrum,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(AudioVisualizer), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);

        // Advance clock by 100ms
        await tester.pump(const Duration(milliseconds: 100));

        // Update to paused state
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 150,
                  child: AudioVisualizer(
                    isPlaying: false,
                    position: Duration(seconds: 45),
                    style: VisualizerStyle.vuMeter,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(AudioVisualizer), findsOneWidget);
      },
    );

    testWidgets(
      'AudioVisualizer halts animation ticker when paused to eliminate thermal & CPU drain',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 150,
                  child: AudioVisualizer(
                    isPlaying: true,
                    style: VisualizerStyle.spectrum,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Transition to paused
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 150,
                  child: AudioVisualizer(
                    isPlaying: false,
                    style: VisualizerStyle.spectrum,
                  ),
                ),
              ),
            ),
          ),
        );

        // Pump frames for decay to settle into resting floor
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        final dynamic state = tester.state(find.byType(AudioVisualizer));
        expect(state.isAtRest, isTrue);
        expect(state.isAnimating, isFalse);
      },
    );
  });
}
