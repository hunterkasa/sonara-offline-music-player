import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/shared/artwork/playlist_artwork_widget.dart';

void main() {
  group('PlaylistArtworkWidget Widget Tests', () {
    testWidgets('renders Liked Songs gradient and heart icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaylistArtworkWidget(size: 80, isLikedSongs: true),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('renders Daily Mix badge with correct mix index', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaylistArtworkWidget(
              size: 100,
              isDailyMix: true,
              dailyMixIndex: 2,
            ),
          ),
        ),
      );

      expect(find.text('DAILY'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // index 2 -> 3
      expect(find.text('MIX'), findsOneWidget);
    });

    testWidgets('renders preset theme and preset icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaylistArtworkWidget(
              size: 80,
              coverUri: 'preset:neon_synth',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
    });

    testWidgets('renders fallback queue_music icon when no cover is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlaylistArtworkWidget(size: 80, coverUri: null)),
        ),
      );

      expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
    });

    testWidgets('renders auto_awesome icon for smart playlist with no cover', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlaylistArtworkWidget(size: 80, isSmart: true)),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    testWidgets('PlaylistCoverPresets catalog contains all presets', (
      tester,
    ) async {
      expect(PlaylistCoverPresets.presets.length, equals(8));

      final preset = PlaylistCoverPresets.getPreset('preset:retro_vinyl');
      expect(preset, isNotNull);
      expect(preset!.name, equals('Retro Vinyl'));
      expect(preset.icon, equals(Icons.album_rounded));

      final nonExistent = PlaylistCoverPresets.getPreset(
        'preset:does_not_exist',
      );
      expect(nonExistent, isNull);
    });
  });
}
