import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../db/database_provider.dart';
import 'artwork_service.dart';

class ExtractedPalette {
  final Color primary;
  final Color surface;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  const ExtractedPalette({
    required this.primary,
    required this.surface,
    required this.primaryContainer,
    required this.onPrimaryContainer,
  });

  Map<String, int> toMap() => {
    'primary': primary.toARGB32(),
    'surface': surface.toARGB32(),
    'primaryContainer': primaryContainer.toARGB32(),
    'onPrimaryContainer': onPrimaryContainer.toARGB32(),
  };

  factory ExtractedPalette.fromMap(Map<String, dynamic> map) {
    return ExtractedPalette(
      primary: Color(map['primary'] as int),
      surface: Color(map['surface'] as int),
      primaryContainer: Color(map['primaryContainer'] as int),
      onPrimaryContainer: Color(map['onPrimaryContainer'] as int),
    );
  }
}

class PaletteService {
  static final Map<String, ExtractedPalette> _cache = {};

  /// Extracts or retrieves cached palette for a given artwork key.
  /// Uses downsampled image decoding and [QuantizerCelebi] with [Score.score]
  /// to extract authentic Material 3 color seeds.
  static Future<ExtractedPalette> getPaletteForArtwork({
    required String key,
    Uint8List? imageBytes,
    int? fallbackSeedArgb,
  }) async {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    var seedArgb = fallbackSeedArgb ?? 0xFF6200EE;

    if (imageBytes != null && imageBytes.length > 50) {
      try {
        final codec = await ui.instantiateImageCodec(
          imageBytes,
          targetWidth: 24,
          targetHeight: 24,
        );
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (byteData != null) {
          final buffer = byteData.buffer.asUint8List();
          final pixels = <int>[];
          for (var i = 0; i < buffer.length - 3; i += 4) {
            final r = buffer[i];
            final g = buffer[i + 1];
            final b = buffer[i + 2];
            final a = buffer[i + 3];
            // Filter transparent pixels
            if (a >= 128) {
              pixels.add((0xFF << 24) | (r << 16) | (g << 8) | b);
            }
          }
          if (pixels.isNotEmpty) {
            final quantizer = QuantizerCelebi();
            final result = await quantizer.quantize(pixels, 16);
            final ranked = Score.score(result.colorToCount);
            if (ranked.isNotEmpty) {
              seedArgb = ranked.first;
            }
          }
        }
      } catch (e) {
        debugPrint('PaletteService extraction error: $e');
      }
    }

    final palette = fromSeed(seedArgb);
    _cache[key] = palette;
    return palette;
  }

  static ExtractedPalette fromSeed(int argb) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(argb),
      brightness: Brightness.dark,
    );
    return ExtractedPalette(
      primary: scheme.primary,
      surface: scheme.surface,
      primaryContainer: scheme.primaryContainer,
      onPrimaryContainer: scheme.onPrimaryContainer,
    );
  }

  static void clearCache() {
    _cache.clear();
  }
}

/// Provides a dynamically extracted [ExtractedPalette] for the current track key.
final paletteForTrackProvider = FutureProvider.family<ExtractedPalette, String>(
  (ref, trackKey) async {
    if (trackKey.isEmpty) {
      return PaletteService.fromSeed(0xFF6200EE);
    }

    final track = await ref.watch(trackStreamProvider(trackKey).future);
    final seed = track != null
        ? (track.title.hashCode.abs() | 0xFF000000)
        : (trackKey.hashCode.abs() | 0xFF000000);

    if (track == null) {
      return PaletteService.fromSeed(seed);
    }

    final artworkService = ref.read(artworkServiceProvider);
    final file = await artworkService.resolveArtworkFile(
      artworkKey: track.artworkKey,
      filePath: track.path,
    );

    Uint8List? bytes;
    if (file != null && await file.exists()) {
      try {
        bytes = await file.readAsBytes();
      } catch (_) {}
    }

    return PaletteService.getPaletteForArtwork(
      key: track.artworkKey ?? trackKey,
      imageBytes: bytes,
      fallbackSeedArgb: seed,
    );
  },
);
