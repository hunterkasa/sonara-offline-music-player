import 'package:flutter/material.dart';

/// A preset theme/gradient and icon option for song artworks.
class SongArtworkPreset {
  final String id;
  final String name;
  final LinearGradient gradient;
  final IconData icon;
  final String description;

  const SongArtworkPreset({
    required this.id,
    required this.name,
    required this.gradient,
    required this.icon,
    required this.description,
  });

  String get uri => 'preset:$id';
}

/// Catalog of curated song artwork and icon placeholder presets.
class SongArtworkPresets {
  const SongArtworkPresets._();

  static const List<SongArtworkPreset> presets = [
    SongArtworkPreset(
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
    SongArtworkPreset(
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
    SongArtworkPreset(
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
    SongArtworkPreset(
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
    SongArtworkPreset(
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
    SongArtworkPreset(
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
    SongArtworkPreset(
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
    SongArtworkPreset(
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
    SongArtworkPreset(
      id: 'lofi_cloud',
      name: 'Lo-Fi Cloud',
      description: 'Mellow pastel dream',
      icon: Icons.cloud_queue_rounded,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)],
      ),
    ),
    SongArtworkPreset(
      id: 'crimson_rock',
      name: 'Crimson Rock',
      description: 'Heavy overdrive & beat',
      icon: Icons.whatshot_rounded,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFED213A), Color(0xFF93291E)],
      ),
    ),
  ];

  /// Resolves a preset by its 'preset:id' identifier or id string.
  static SongArtworkPreset? getPreset(String? uri) {
    if (uri == null) return null;
    final id = uri.startsWith('preset:')
        ? uri.substring('preset:'.length)
        : uri;
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }
}
