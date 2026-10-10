import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:sonara/data/sources/palette_service.dart';

void main() {
  group('PaletteService Tests', () {
    setUp(() {
      PaletteService.clearCache();
    });

    test('material_color_utilities QuantizerCelebi and Score extract dominant seed', () async {
      final colors = [0xFFFF0000, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF];
      final quantizer = QuantizerCelebi();
      final result = await quantizer.quantize(colors, 16);
      expect(result.colorToCount.isNotEmpty, isTrue);

      final ranked = Score.score(result.colorToCount);
      expect(ranked.isNotEmpty, isTrue);

      final dominantArgb = ranked.first;
      final palette = PaletteService.fromSeed(dominantArgb);
      expect(palette.primary, isNotNull);
    });

    test('PaletteService.fromSeed generates valid Material 3 palette', () {
      final palette = PaletteService.fromSeed(0xFF007AFF);

      expect(palette.primary, isNotNull);
      expect(palette.surface, isNotNull);
      expect(palette.primaryContainer, isNotNull);
      expect(palette.onPrimaryContainer, isNotNull);

      final map = palette.toMap();
      final restored = ExtractedPalette.fromMap(map);
      expect(restored.primary, equals(palette.primary));
      expect(restored.surface, equals(palette.surface));
    });

    test('PaletteService.getPaletteForArtwork extracts from image bytes and caches', () async {
      // 1x1 Red PNG
      final pngBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        0x90,
        0x77,
        0x53,
        0xDE,
        0x00,
        0x00,
        0x00,
        0x0C,
        0x49,
        0x44,
        0x41,
        0x54,
        0x08,
        0xD7,
        0x63,
        0xF8,
        0xCF,
        0xC0,
        0x00,
        0x00,
        0x03,
        0x01,
        0x01,
        0x00,
        0x18,
        0xDD,
        0x8D,
        0xB0,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

      final palette1 = await PaletteService.getPaletteForArtwork(
        key: 'test_red_art',
        imageBytes: pngBytes,
      );

      expect(palette1.primary, isNotNull);

      // Verify cached hit
      final palette2 = await PaletteService.getPaletteForArtwork(
        key: 'test_red_art',
      );

      expect(palette2.primary, equals(palette1.primary));
    });

    test(
      'PaletteService.getPaletteForArtwork falls back safely for invalid bytes',
      () async {
        final palette = await PaletteService.getPaletteForArtwork(
          key: 'corrupt_key',
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fallbackSeedArgb: 0xFF4CAF50,
        );

        final expected = PaletteService.fromSeed(0xFF4CAF50);
        expect(palette.primary, equals(expected.primary));
      },
    );
  });
}
