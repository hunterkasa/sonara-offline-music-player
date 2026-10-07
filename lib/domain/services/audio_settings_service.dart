import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../models/audio_device_profile.dart';
import '../models/audio_settings.dart';
import '../models/equalizer_preset.dart';

class AudioSettingsNotifier extends StateNotifier<AudioSettings> {
  final AppDatabase db;

  AudioSettingsNotifier(this.db) : super(const AudioSettings()) {
    _loadSettings();
  }

  static const String _settingsKey = 'audio_settings';

  AudioSettings get currentSettings => state;

  Future<void> _loadSettings() async {
    final raw = await db.getSetting(_settingsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = AudioSettings.fromJson(raw);
      } catch (_) {
        // Fallback to default
      }
    }
  }

  Future<void> _saveSettings(AudioSettings newSettings) async {
    state = newSettings;
    await db.setSetting(_settingsKey, newSettings.toJson());
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    await _saveSettings(state.copyWith(equalizerEnabled: enabled));
  }

  Future<void> setEqualizerPreset(String presetId) async {
    if (presetId == 'custom') {
      await _saveSettings(state.copyWith(equalizerPreset: 'custom'));
      return;
    }

    final preset = EqualizerPreset.getPreset(presetId);
    await _saveSettings(
      state.copyWith(
        equalizerPreset: presetId,
        bandGains: List<double>.from(preset.bandGainsDb),
      ),
    );
  }

  Future<void> setBandGain(int index, double gainDb) async {
    final currentGains = List<double>.from(state.bandGains);
    if (index >= 0 && index < currentGains.length) {
      currentGains[index] = gainDb;
      await _saveSettings(
        state.copyWith(equalizerPreset: 'custom', bandGains: currentGains),
      );
    }
  }

  Future<void> setBassBoost(double value) async {
    await _saveSettings(state.copyWith(bassBoost: value.clamp(0.0, 1.0)));
  }

  Future<void> setLoudnessGain(double valueDb) async {
    await _saveSettings(state.copyWith(loudnessGain: valueDb.clamp(0.0, 10.0)));
  }

  Future<void> setCrossfadeDuration(int seconds) async {
    await _saveSettings(
      state.copyWith(crossfadeDurationSeconds: seconds.clamp(0, 12)),
    );
  }

  Future<void> setSmoothFades(bool enabled) async {
    await _saveSettings(state.copyWith(smoothFades: enabled));
  }

  Future<void> setReplayGainMode(ReplayGainMode mode) async {
    await _saveSettings(state.copyWith(replayGainMode: mode));
  }

  Future<void> setReplayGainPreAmp(double preAmpDb) async {
    await _saveSettings(
      state.copyWith(replayGainPreAmpDb: preAmpDb.clamp(-12.0, 12.0)),
    );
  }

  Future<void> setPreventClipping(bool enabled) async {
    await _saveSettings(state.copyWith(preventClipping: enabled));
  }

  Future<void> setSkipSilence(bool enabled) async {
    await _saveSettings(state.copyWith(skipSilence: enabled));
  }

  Future<void> setStereoBalance(double balance) async {
    await _saveSettings(
      state.copyWith(stereoBalance: balance.clamp(-1.0, 1.0)),
    );
  }

  Future<void> setMonoDownmix(bool enabled) async {
    await _saveSettings(state.copyWith(monoDownmix: enabled));
  }

  Future<void> setLongAudioPositionMemory(bool enabled) async {
    await _saveSettings(state.copyWith(longAudioPositionMemory: enabled));
  }

  Future<void> setPitchSemitones(int semitones) async {
    await _saveSettings(
      state.copyWith(pitchSemitones: semitones.clamp(-12, 12)),
    );
  }

  Future<void> setDeviceProfilesEnabled(bool enabled) async {
    await _saveSettings(state.copyWith(deviceProfilesEnabled: enabled));
  }

  Future<void> setVisualizerMode(String mode) async {
    await _saveSettings(state.copyWith(visualizerMode: mode));
  }

  Future<void> setNowPlayingSkin(NowPlayingSkin skin) async {
    await _saveSettings(state.copyWith(nowPlayingSkin: skin));
  }

  Future<void> setBackgroundPlayback(bool enabled) async {
    await _saveSettings(state.copyWith(backgroundPlayback: enabled));
  }

  Future<void> applyDeviceProfile(AudioDeviceProfile profile) async {
    await _saveSettings(
      state.copyWith(
        activeDeviceProfileId: profile.id,
        equalizerPreset: profile.equalizerPreset,
        bandGains: List<double>.from(profile.bandGains),
        bassBoost: profile.bassBoost,
        loudnessGain: profile.loudnessGain,
        crossfadeDurationSeconds: profile.crossfadeSeconds,
        stereoBalance: profile.stereoBalance,
        monoDownmix: profile.monoDownmix,
      ),
    );
  }
}

final audioSettingsProvider =
    StateNotifierProvider<AudioSettingsNotifier, AudioSettings>((ref) {
      final db = ref.watch(databaseProvider);
      return AudioSettingsNotifier(db);
    });
