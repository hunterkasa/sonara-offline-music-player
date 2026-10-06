import 'dart:convert';

enum AudioOutputCategory { speaker, bluetooth, wired, usb }

class AudioDeviceProfile {
  final String id;
  final String name;
  final AudioOutputCategory category;
  final String equalizerPreset;
  final List<double> bandGains;
  final double bassBoost;
  final double loudnessGain;
  final int crossfadeSeconds;
  final double stereoBalance;
  final bool monoDownmix;

  const AudioDeviceProfile({
    required this.id,
    required this.name,
    required this.category,
    this.equalizerPreset = 'flat',
    this.bandGains = const [0.0, 0.0, 0.0, 0.0, 0.0],
    this.bassBoost = 0.0,
    this.loudnessGain = 0.0,
    this.crossfadeSeconds = 0,
    this.stereoBalance = 0.0,
    this.monoDownmix = false,
  });

  static AudioDeviceProfile speakerDefault() => const AudioDeviceProfile(
    id: 'speaker',
    name: 'Built-in Speaker',
    category: AudioOutputCategory.speaker,
    equalizerPreset: 'vocal',
    bandGains: [0.0, 1.0, 2.0, 1.5, 0.0],
    bassBoost: 0.0,
    loudnessGain: 2.0,
    crossfadeSeconds: 0,
    stereoBalance: 0.0,
    monoDownmix: true,
  );

  static AudioDeviceProfile bluetoothDefault() => const AudioDeviceProfile(
    id: 'bluetooth',
    name: 'Bluetooth Audio',
    category: AudioOutputCategory.bluetooth,
    equalizerPreset: 'bass_boost',
    bandGains: [4.0, 2.5, 0.0, 1.0, 2.0],
    bassBoost: 0.35,
    loudnessGain: 0.0,
    crossfadeSeconds: 4,
    stereoBalance: 0.0,
    monoDownmix: false,
  );

  static AudioDeviceProfile wiredDefault() => const AudioDeviceProfile(
    id: 'wired',
    name: 'Wired Headphones / IEMs',
    category: AudioOutputCategory.wired,
    equalizerPreset: 'flat',
    bandGains: [0.0, 0.0, 0.0, 0.0, 0.0],
    bassBoost: 0.0,
    loudnessGain: 0.0,
    crossfadeSeconds: 0,
    stereoBalance: 0.0,
    monoDownmix: false,
  );

  static AudioDeviceProfile usbDefault() => const AudioDeviceProfile(
    id: 'usb',
    name: 'USB DAC / External Output',
    category: AudioOutputCategory.usb,
    equalizerPreset: 'flat',
    bandGains: [0.0, 0.0, 0.0, 0.0, 0.0],
    bassBoost: 0.0,
    loudnessGain: 0.0,
    crossfadeSeconds: 0,
    stereoBalance: 0.0,
    monoDownmix: false,
  );

  AudioDeviceProfile copyWith({
    String? name,
    String? equalizerPreset,
    List<double>? bandGains,
    double? bassBoost,
    double? loudnessGain,
    int? crossfadeSeconds,
    double? stereoBalance,
    bool? monoDownmix,
  }) {
    return AudioDeviceProfile(
      id: id,
      name: name ?? this.name,
      category: category,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      bandGains: bandGains ?? this.bandGains,
      bassBoost: bassBoost ?? this.bassBoost,
      loudnessGain: loudnessGain ?? this.loudnessGain,
      crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
      stereoBalance: stereoBalance ?? this.stereoBalance,
      monoDownmix: monoDownmix ?? this.monoDownmix,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category.name,
    'equalizerPreset': equalizerPreset,
    'bandGains': bandGains,
    'bassBoost': bassBoost,
    'loudnessGain': loudnessGain,
    'crossfadeSeconds': crossfadeSeconds,
    'stereoBalance': stereoBalance,
    'monoDownmix': monoDownmix,
  };

  factory AudioDeviceProfile.fromMap(Map<String, dynamic> map) {
    return AudioDeviceProfile(
      id: map['id'] as String? ?? 'speaker',
      name: map['name'] as String? ?? 'Audio Output',
      category: AudioOutputCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => AudioOutputCategory.speaker,
      ),
      equalizerPreset: map['equalizerPreset'] as String? ?? 'flat',
      bandGains:
          (map['bandGains'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [0.0, 0.0, 0.0, 0.0, 0.0],
      bassBoost: (map['bassBoost'] as num?)?.toDouble() ?? 0.0,
      loudnessGain: (map['loudnessGain'] as num?)?.toDouble() ?? 0.0,
      crossfadeSeconds: map['crossfadeSeconds'] as int? ?? 0,
      stereoBalance: (map['stereoBalance'] as num?)?.toDouble() ?? 0.0,
      monoDownmix: map['monoDownmix'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AudioDeviceProfile.fromJson(String source) =>
      AudioDeviceProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
