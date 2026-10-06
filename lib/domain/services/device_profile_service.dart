// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../models/audio_device_profile.dart';
import 'audio_settings_service.dart';

final deviceProfileServiceProvider = Provider<DeviceProfileService>((ref) {
  final db = ref.watch(databaseProvider);
  final settingsNotifier = ref.watch(audioSettingsProvider.notifier);
  return DeviceProfileService(db: db, settingsNotifier: settingsNotifier);
});

final activeOutputCategoryProvider = StreamProvider<AudioOutputCategory>((ref) {
  final service = ref.watch(deviceProfileServiceProvider);
  return service.categoryStream;
});

class DeviceProfileService {
  final AppDatabase db;
  final AudioSettingsNotifier settingsNotifier;

  static const String _profilesKey = 'audio_device_profiles';

  final _categoryController = StreamController<AudioOutputCategory>.broadcast();
  Stream<AudioOutputCategory> get categoryStream => _categoryController.stream;

  AudioOutputCategory _currentCategory = AudioOutputCategory.speaker;
  AudioOutputCategory get currentCategory => _currentCategory;

  final Map<AudioOutputCategory, AudioDeviceProfile> _profiles = {
    AudioOutputCategory.speaker: AudioDeviceProfile.speakerDefault(),
    AudioOutputCategory.bluetooth: AudioDeviceProfile.bluetoothDefault(),
    AudioOutputCategory.wired: AudioDeviceProfile.wiredDefault(),
    AudioOutputCategory.usb: AudioDeviceProfile.usbDefault(),
  };

  DeviceProfileService({required this.db, required this.settingsNotifier}) {
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final raw = await db.getSetting(_profilesKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final cat = AudioOutputCategory.values.firstWhere(
            (c) => c.name == entry.key,
            orElse: () => AudioOutputCategory.speaker,
          );
          _profiles[cat] = AudioDeviceProfile.fromMap(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load device profiles: $e');
    }
  }

  Future<void> saveProfile(AudioDeviceProfile profile) async {
    _profiles[profile.category] = profile;
    final map = <String, dynamic>{};
    for (final entry in _profiles.entries) {
      map[entry.key.name] = entry.value.toMap();
    }
    await db.setSetting(_profilesKey, jsonEncode(map));

    // If saving the currently active category, immediately apply settings
    if (profile.category == _currentCategory) {
      await applyProfile(profile);
    }
  }

  AudioDeviceProfile getProfile(AudioOutputCategory category) {
    return _profiles[category] ?? _getDefaultProfileForCategory(category);
  }

  AudioDeviceProfile _getDefaultProfileForCategory(
    AudioOutputCategory category,
  ) {
    switch (category) {
      case AudioOutputCategory.speaker:
        return AudioDeviceProfile.speakerDefault();
      case AudioOutputCategory.bluetooth:
        return AudioDeviceProfile.bluetoothDefault();
      case AudioOutputCategory.wired:
        return AudioDeviceProfile.wiredDefault();
      case AudioOutputCategory.usb:
        return AudioDeviceProfile.usbDefault();
    }
  }

  /// Maps a set of AudioDevices from audio_session to our AudioOutputCategory
  AudioOutputCategory resolveCategory(Set<AudioDevice> devices) {
    for (final d in devices) {
      if (!d.isOutput) continue;
      switch (d.type) {
        case AudioDeviceType.bluetoothA2dp:
        case AudioDeviceType.bluetoothSco:
        case AudioDeviceType.bluetoothLe:
        case AudioDeviceType.hearingAid:
          return AudioOutputCategory.bluetooth;
        case AudioDeviceType.usbAudio:
          return AudioOutputCategory.usb;
        case AudioDeviceType.wiredHeadphones:
        case AudioDeviceType.wiredHeadset:
        case AudioDeviceType.lineAnalog:
        case AudioDeviceType.lineDigital:
        case AudioDeviceType.auxLine:
          return AudioOutputCategory.wired;
        default:
          break;
      }
    }
    return AudioOutputCategory.speaker;
  }

  /// Called when audio_session detects a route change
  Future<void> handleDevicesChanged(Set<AudioDevice> devices) async {
    final newCategory = resolveCategory(devices);
    if (newCategory != _currentCategory) {
      _currentCategory = newCategory;
      _categoryController.add(newCategory);

      // Auto-switch profile if enabled in settings
      final currentSettings = settingsNotifier.currentSettings;
      if (currentSettings.deviceProfilesEnabled) {
        final profile = getProfile(newCategory);
        await applyProfile(profile);
      }
    }
  }

  Future<void> applyProfile(AudioDeviceProfile profile) async {
    await settingsNotifier.applyDeviceProfile(profile);
  }

  void dispose() {
    _categoryController.close();
  }
}
