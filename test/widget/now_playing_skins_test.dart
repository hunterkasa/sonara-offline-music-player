import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/features/now_playing/skins/minimalist_oled_skin.dart';
import 'package:sonara/features/now_playing/skins/retro_cassette_skin.dart';
import 'package:sonara/features/now_playing/skins/spinning_vinyl_skin.dart';

void main() {
  group('Now Playing Player Skins Widget Tests', () {
    testWidgets('SpinningVinylSkin renders turntable, title and artist', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 500,
                child: SpinningVinylSkin(
                  snapshot: PlaybackSnapshot(
                    state: PlaybackState.playing,
                    title: 'Vinyl Dream',
                    artist: 'Analog Master',
                  ),
                  title: 'Vinyl Dream',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SpinningVinylSkin), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('RetroCassetteSkin renders cassette tape and reels', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 500,
                child: RetroCassetteSkin(
                  snapshot: PlaybackSnapshot(
                    state: PlaybackState.playing,
                    title: 'Tape Deck 90s',
                    artist: 'Cassette Boy',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RetroCassetteSkin), findsOneWidget);
      expect(find.text('Tape Deck 90s'), findsOneWidget);
      expect(find.text('Cassette Boy'), findsOneWidget);
      expect(find.textContaining('NORMAL BIAS'), findsOneWidget);
    });

    testWidgets('MinimalistOledSkin renders high-contrast OLED typography', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: SizedBox(
                width: 400,
                height: 500,
                child: MinimalistOledSkin(
                  snapshot: PlaybackSnapshot(
                    state: PlaybackState.playing,
                    title: 'Pure Darkness',
                    artist: 'OLED Nocturne',
                  ),
                  title: 'Pure Darkness',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MinimalistOledSkin), findsOneWidget);
      expect(find.text('Pure Darkness'), findsOneWidget);
      expect(find.text('OLED Nocturne'), findsOneWidget);
      expect(find.text('OLED PURE BLACK'), findsOneWidget);
    });
  });
}
