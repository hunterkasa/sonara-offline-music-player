import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sonara/app/theme/theme_tokens.dart';

/// A preset theme/gradient option for playlist covers
class PlaylistCoverPreset {
  final String id;
  final String name;
  final LinearGradient gradient;
  final IconData icon;
  final String description;

  const PlaylistCoverPreset({
    required this.id,
    required this.name,
    required this.gradient,
    required this.icon,
    required this.description,
  });

  String get uri => 'preset:$id';
}

/// Catalog of curated playlist cover presets
class PlaylistCoverPresets {
  static const List<PlaylistCoverPreset> presets = [
    PlaylistCoverPreset(
      id: 'neon_synth',
      name: 'Neon Synth',
      description: 'Vibrant cyberpunk waves',
      icon: Icons.graphic_eq_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF007A), Color(0xFF7928CA), Color(0xFF4A00E0)],
      ),
    ),
    PlaylistCoverPreset(
      id: 'midnight_vibes',
      name: 'Midnight Vibes',
      description: 'Deep nocturnal atmosphere',
      icon: Icons.nightlife_rounded,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      ),
    ),
    PlaylistCoverPreset(
      id: 'sunset_chill',
      name: 'Sunset Chill',
      description: 'Golden hour warmth',
      icon: Icons.wb_twilight_rounded,
      gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFFF512F), Color(0xFFF09819), Color(0xFFFFD194)],
      ),
    ),
    PlaylistCoverPreset(
      id: 'retro_vinyl',
      name: 'Retro Vinyl',
      description: 'Classic analog groove',
      icon: Icons.album_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF232526), Color(0xFF414345), Color(0xFF1E1E24)],
      ),
    ),
    PlaylistCoverPreset(
      id: 'emerald_groove',
      name: 'Emerald Groove',
      description: 'Lush organic rhythms',
      icon: Icons.eco_rounded,
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      ),
    ),
    PlaylistCoverPreset(
      id: 'electric_violet',
      name: 'Electric Violet',
      description: 'Energetic purple pulse',
      icon: Icons.electric_bolt_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
      ),
    ),
    PlaylistCoverPreset(
      id: 'warm_acoustic',
      name: 'Warm Acoustic',
      description: 'Intimate woody tones',
      icon: Icons.music_note_rounded,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8E0E00), Color(0xFF3A1C1A), Color(0xFF1F1C18)],
      ),
    ),
    PlaylistCoverPreset(
      id: 'cyber_pulse',
      name: 'Cyber Pulse',
      description: 'High-energy electronic flow',
      icon: Icons.headphones_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
      ),
    ),
  ];

  static PlaylistCoverPreset? getPreset(String? uri) {
    if (uri == null || !uri.startsWith('preset:')) return null;
    final id = uri.substring('preset:'.length);
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// A unified, responsive artwork widget for playlists.
/// Supports custom image files, preset themes, Liked Songs, Daily Mixes, and fallbacks.
class PlaylistArtworkWidget extends StatelessWidget {
  final String? coverUri;
  final double? width;
  final double? height;
  final double? size;
  final BorderRadiusGeometry? borderRadius;
  final bool isLikedSongs;
  final bool isDailyMix;
  final int? dailyMixIndex;
  final bool isSmart;
  final IconData? fallbackIcon;
  final String? heroTag;
  final Widget? overlay;

  const PlaylistArtworkWidget({
    super.key,
    this.coverUri,
    this.width,
    this.height,
    this.size,
    this.borderRadius,
    this.isLikedSongs = false,
    this.isDailyMix = false,
    this.dailyMixIndex,
    this.isSmart = false,
    this.fallbackIcon,
    this.heroTag,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = size ?? width ?? 48.0;
    final effectiveHeight = size ?? height ?? 48.0;
    final effectiveRadius = borderRadius ?? AppRadii.cardRadius;

    Widget content = RepaintBoundary(
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: SizedBox(
          width: effectiveWidth,
          height: effectiveHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildArtworkBody(context, effectiveWidth, effectiveHeight),
              ?overlay,
            ],
          ),
        ),
      ),
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(tag: heroTag!, child: content);
    }

    return content;
  }

  Widget _buildArtworkBody(
    BuildContext context,
    double targetWidth,
    double targetHeight,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final minDim = targetWidth < targetHeight ? targetWidth : targetHeight;
    final iconSize = (minDim * 0.45).clamp(18.0, 56.0);

    // 1. Liked Songs
    if (isLikedSongs) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.pink.shade400],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      );
    }

    // 2. Daily Mix
    if (isDailyMix) {
      final index = dailyMixIndex ?? 0;
      final mixPalettes = [
        (const Color(0xFFE91E63), const Color(0xFF9C27B0)),
        (const Color(0xFF2196F3), const Color(0xFF00BCD4)),
        (const Color(0xFFFF9800), const Color(0xFFFF5722)),
        (const Color(0xFF4CAF50), const Color(0xFF8BC34A)),
        (const Color(0xFF673AB7), const Color(0xFF3F51B5)),
        (const Color(0xFF009688), const Color(0xFF4DB6AC)),
      ];
      final colors = mixPalettes[index % mixPalettes.length];

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.$1, colors.$2],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DAILY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w900,
                  letterSpacing: minDim > 60 ? 2.0 : 1.0,
                  fontSize: (minDim * 0.12).clamp(7.0, 11.0),
                ),
              ),
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: (minDim * 0.35).clamp(14.0, 42.0),
                  height: 1.05,
                ),
              ),
              Text(
                'MIX',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w900,
                  letterSpacing: minDim > 60 ? 2.0 : 1.0,
                  fontSize: (minDim * 0.12).clamp(7.0, 11.0),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Preset cover
    final preset = PlaylistCoverPresets.getPreset(coverUri);
    if (preset != null) {
      return Container(
        decoration: BoxDecoration(gradient: preset.gradient),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(minDim * 0.1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            child: Icon(preset.icon, color: Colors.white, size: iconSize),
          ),
        ),
      );
    }

    // 4. Custom image file
    if (coverUri != null && coverUri!.isNotEmpty) {
      final file = File(coverUri!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: (targetWidth * 2).toInt(),
        cacheHeight: (targetHeight * 2).toInt(),
        errorBuilder: (ctx, err, stack) {
          return _buildFallback(context, colorScheme, iconSize);
        },
      );
    }

    // 5. Default Fallback
    return _buildFallback(context, colorScheme, iconSize);
  }

  Widget _buildFallback(
    BuildContext context,
    ColorScheme colorScheme,
    double iconSize,
  ) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          fallbackIcon ??
              (isSmart
                  ? Icons.auto_awesome_rounded
                  : Icons.queue_music_rounded),
          color: colorScheme.primary,
          size: iconSize,
        ),
      ),
    );
  }
}
