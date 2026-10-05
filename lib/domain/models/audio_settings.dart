import 'dart:convert';

enum ReplayGainMode { off, track, album, smart }

class AudioSettings {
  final bool equalizerEnabled;
  final String equalizerPreset;
  final List<double> bandGains; // list of gains in dB
  final double bassBoost; // 0.0 to 1.0
  final double loudnessGain; // 0.0 to 10.0 dB
  final int crossfadeDurationSeconds; // 0 to 12s (0 = off / gapless)
  final bool smoothFades; // fade on manual pause/resume/skip
  final ReplayGainMode replayGainMode;
  final double replayGainPreAmpDb; // -12.0 to +12.0 dB
  final bool preventClipping;
  final bool skipSilence;
  final double stereoBalance; // -1.0 (Left) to +1.0 (Right), 0.0 (Center)
  final bool monoDownmix;
  final bool longAudioPositionMemory; // resume podcasts/long audio >= 20m

  const AudioSettings({
    this.equalizerEnabled = false,
    this.equalizerPreset = 'flat',
    this.bandGains = const [0.0, 0.0, 0.0, 0.0, 0.0],
    this.bassBoost = 0.0,
    this.loudnessGain = 0.0,
    this.crossfadeDurationSeconds = 0,
    this.smoothFades = true,
    this.replayGainMode = ReplayGainMode.smart,
    this.replayGainPreAmpDb = 0.0,
    this.preventClipping = true,
    this.skipSilence = false,
    this.stereoBalance = 0.0,
    this.monoDownmix = false,
    this.longAudioPositionMemory = true,
  });

  AudioSettings copyWith({
    bool? equalizerEnabled,
    String? equalizerPreset,
    List<double>? bandGains,
    double? bassBoost,
    double? loudnessGain,
    int? crossfadeDurationSeconds,
    bool? smoothFades,
    ReplayGainMode? replayGainMode,
    double? replayGainPreAmpDb,
    bool? preventClipping,
    bool? skipSilence,
    double? stereoBalance,
    bool? monoDownmix,
    bool? longAudioPositionMemory,
  }) {
    return AudioSettings(
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      bandGains: bandGains ?? this.bandGains,
      bassBoost: bassBoost ?? this.bassBoost,
      loudnessGain: loudnessGain ?? this.loudnessGain,
      crossfadeDurationSeconds:
          crossfadeDurationSeconds ?? this.crossfadeDurationSeconds,
      smoothFades: smoothFades ?? this.smoothFades,
      replayGainMode: replayGainMode ?? this.replayGainMode,
      replayGainPreAmpDb: replayGainPreAmpDb ?? this.replayGainPreAmpDb,
      preventClipping: preventClipping ?? this.preventClipping,
      skipSilence: skipSilence ?? this.skipSilence,
      stereoBalance: stereoBalance ?? this.stereoBalance,
      monoDownmix: monoDownmix ?? this.monoDownmix,
      longAudioPositionMemory:
          longAudioPositionMemory ?? this.longAudioPositionMemory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equalizerEnabled': equalizerEnabled,
      'equalizerPreset': equalizerPreset,
      'bandGains': bandGains,
      'bassBoost': bassBoost,
      'loudnessGain': loudnessGain,
      'crossfadeDurationSeconds': crossfadeDurationSeconds,
      'smoothFades': smoothFades,
      'replayGainMode': replayGainMode.name,
      'replayGainPreAmpDb': replayGainPreAmpDb,
      'preventClipping': preventClipping,
      'skipSilence': skipSilence,
      'stereoBalance': stereoBalance,
      'monoDownmix': monoDownmix,
      'longAudioPositionMemory': longAudioPositionMemory,
    };
  }

  factory AudioSettings.fromMap(Map<String, dynamic> map) {
    return AudioSettings(
      equalizerEnabled: map['equalizerEnabled'] as bool? ?? false,
      equalizerPreset: map['equalizerPreset'] as String? ?? 'flat',
      bandGains:
          (map['bandGains'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [0.0, 0.0, 0.0, 0.0, 0.0],
      bassBoost: (map['bassBoost'] as num?)?.toDouble() ?? 0.0,
      loudnessGain: (map['loudnessGain'] as num?)?.toDouble() ?? 0.0,
      crossfadeDurationSeconds: map['crossfadeDurationSeconds'] as int? ?? 0,
      smoothFades: map['smoothFades'] as bool? ?? true,
      replayGainMode: ReplayGainMode.values.firstWhere(
        (e) => e.name == map['replayGainMode'],
        orElse: () => ReplayGainMode.smart,
      ),
      replayGainPreAmpDb:
          (map['replayGainPreAmpDb'] as num?)?.toDouble() ?? 0.0,
      preventClipping: map['preventClipping'] as bool? ?? true,
      skipSilence: map['skipSilence'] as bool? ?? false,
      stereoBalance: (map['stereoBalance'] as num?)?.toDouble() ?? 0.0,
      monoDownmix: map['monoDownmix'] as bool? ?? false,
      longAudioPositionMemory: map['longAudioPositionMemory'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AudioSettings.fromJson(String source) =>
      AudioSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
