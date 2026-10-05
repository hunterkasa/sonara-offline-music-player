enum EqualizerPresetType {
  flat,
  bassBoost,
  trebleBoost,
  rock,
  pop,
  jazz,
  electronic,
  vocal,
  classical,
  custom,
}

class EqualizerPreset {
  final String id;
  final String name;
  final List<double>
  bandGainsDb; // 5 standard bands: 60Hz, 230Hz, 910Hz, 3600Hz, 14000Hz

  const EqualizerPreset({
    required this.id,
    required this.name,
    required this.bandGainsDb,
  });

  static const List<EqualizerPreset> defaultPresets = [
    EqualizerPreset(
      id: 'flat',
      name: 'Flat',
      bandGainsDb: [0.0, 0.0, 0.0, 0.0, 0.0],
    ),
    EqualizerPreset(
      id: 'bass_boost',
      name: 'Bass Boost',
      bandGainsDb: [5.0, 3.5, 0.0, 0.0, 0.0],
    ),
    EqualizerPreset(
      id: 'treble_boost',
      name: 'Treble Boost',
      bandGainsDb: [0.0, 0.0, 1.0, 3.5, 5.0],
    ),
    EqualizerPreset(
      id: 'rock',
      name: 'Rock',
      bandGainsDb: [4.5, 2.0, -1.0, 2.5, 4.0],
    ),
    EqualizerPreset(
      id: 'pop',
      name: 'Pop',
      bandGainsDb: [1.5, 3.0, 3.5, 2.0, -1.0],
    ),
    EqualizerPreset(
      id: 'jazz',
      name: 'Jazz',
      bandGainsDb: [3.0, 1.5, -1.5, 1.5, 3.0],
    ),
    EqualizerPreset(
      id: 'electronic',
      name: 'Electronic',
      bandGainsDb: [4.0, 3.0, 0.0, 2.0, 4.0],
    ),
    EqualizerPreset(
      id: 'vocal',
      name: 'Vocal / Acoustic',
      bandGainsDb: [-1.0, 2.0, 4.0, 3.0, 1.0],
    ),
    EqualizerPreset(
      id: 'classical',
      name: 'Classical',
      bandGainsDb: [4.0, 2.5, 1.5, 2.5, 3.5],
    ),
  ];

  static EqualizerPreset getPreset(String id) {
    return defaultPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => defaultPresets.first,
    );
  }
}
