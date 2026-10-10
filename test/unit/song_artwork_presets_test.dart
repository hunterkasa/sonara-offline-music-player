import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/shared/artwork/song_artwork_presets.dart';

void main() {
  group('SongArtworkPresets Tests', () {
    test('contains curated presets with valid gradient and icon', () {
      expect(SongArtworkPresets.presets, isNotEmpty);
      expect(SongArtworkPresets.presets.length, greaterThanOrEqualTo(8));

      for (final preset in SongArtworkPresets.presets) {
        expect(preset.id, isNotEmpty);
        expect(preset.name, isNotEmpty);
        expect(preset.description, isNotEmpty);
        expect(preset.uri, startsWith('preset:'));
        expect(preset.gradient.colors, isNotEmpty);
        expect(preset.icon, isA<IconData>());
      }
    });

    test(
      'getPreset resolves preset correctly with or without preset: prefix',
      () {
        final neon = SongArtworkPresets.getPreset('preset:neon_synth');
        expect(neon, isNotNull);
        expect(neon!.id, equals('neon_synth'));
        expect(neon.name, equals('Neon Synth'));

        final retro = SongArtworkPresets.getPreset('retro_vinyl');
        expect(retro, isNotNull);
        expect(retro!.id, equals('retro_vinyl'));
        expect(retro.name, equals('Retro Vinyl'));

        final nonExistent = SongArtworkPresets.getPreset(
          'preset:unknown_preset_123',
        );
        expect(nonExistent, isNull);

        final nullPreset = SongArtworkPresets.getPreset(null);
        expect(nullPreset, isNull);
      },
    );
  });
}
