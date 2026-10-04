import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  static Future<ExtractedPalette> getPaletteForArtwork({
    required String key,
    Uint8List? imageBytes,
    int? fallbackSeedArgb,
  }) async {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final palette = await compute(
      _extractPaletteIsolated,
      _PaletteExtractRequest(
        imageBytes: imageBytes,
        fallbackArgb: fallbackSeedArgb ?? 0xFF6200EE,
      ),
    );

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
}

class _PaletteExtractRequest {
  final Uint8List? imageBytes;
  final int fallbackArgb;

  _PaletteExtractRequest({this.imageBytes, required this.fallbackArgb});
}

ExtractedPalette _extractPaletteIsolated(_PaletteExtractRequest request) {
  var seedArgb = request.fallbackArgb;

  if (request.imageBytes != null && request.imageBytes!.length > 100) {
    final bytes = request.imageBytes!;
    // Fast dominant color sampling across the middle bytes
    var rSum = 0;
    var gSum = 0;
    var bSum = 0;
    var count = 0;
    final step = (bytes.length ~/ 200).clamp(4, 500);

    for (var i = 0; i < bytes.length - 3; i += step) {
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      // Avoid pure white and pure black for better seed vibrance
      if ((r + g + b) > 60 && (r + g + b) < 700) {
        rSum += r;
        gSum += g;
        bSum += b;
        count++;
      }
    }

    if (count > 0) {
      final avgR = rSum ~/ count;
      final avgG = gSum ~/ count;
      final avgB = bSum ~/ count;
      seedArgb = (0xFF << 24) | (avgR << 16) | (avgG << 8) | avgB;
    }
  }

  return PaletteService.fromSeed(seedArgb);
}
