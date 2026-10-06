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
  });
}
