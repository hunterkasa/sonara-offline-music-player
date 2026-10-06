// ignore_for_file: experimental_member_use

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/models/audio_device_profile.dart';
import 'package:sonara/domain/services/audio_settings_service.dart';
import 'package:sonara/domain/services/device_profile_service.dart';

void main() {
  group('DeviceProfileService Route Resolution & Auto-Switching Tests', () {
    late AppDatabase db;
    late AudioSettingsNotifier settingsNotifier;
    late DeviceProfileService service;

    setUp(() {
      db = AppDatabase.inMemory();
      settingsNotifier = AudioSettingsNotifier(db);
      service = DeviceProfileService(
        db: db,
        settingsNotifier: settingsNotifier,
      );
    });

    tearDown(() async {
      service.dispose();
      await db.close();
    });

    test('default profiles have audiophile characteristics per target', () {
      final speaker = service.getProfile(AudioOutputCategory.speaker);
      expect(speaker.category, equals(AudioOutputCategory.speaker));
      expect(speaker.monoDownmix, isTrue); // optimize phone mono speaker
      expect(speaker.loudnessGain, greaterThan(0.0));

      final bluetooth = service.getProfile(AudioOutputCategory.bluetooth);
      expect(bluetooth.category, equals(AudioOutputCategory.bluetooth));
      expect(bluetooth.bassBoost, greaterThan(0.0));
      expect(bluetooth.crossfadeSeconds, equals(4));

      final wired = service.getProfile(AudioOutputCategory.wired);
      expect(wired.category, equals(AudioOutputCategory.wired));
      expect(wired.equalizerPreset, equals('flat'));
      expect(wired.crossfadeSeconds, equals(0)); // bit-perfect gapless

      final usb = service.getProfile(AudioOutputCategory.usb);
      expect(usb.category, equals(AudioOutputCategory.usb));
      expect(usb.equalizerPreset, equals('flat'));
    });

    test('resolveCategory correctly prioritizes routes', () {
      final btDevice = AudioDevice(
        id: '1',
        name: 'Sony WH-1000XM4',
        isInput: false,
        isOutput: true,
        type: AudioDeviceType.bluetoothA2dp,
      );

      final wiredDevice = AudioDevice(
        id: '2',
        name: 'Sennheiser IE200',
        isInput: false,
        isOutput: true,
        type: AudioDeviceType.wiredHeadphones,
      );

      final usbDevice = AudioDevice(
        id: '3',
        name: 'FiiO BTR5 DAC',
        isInput: false,
        isOutput: true,
        type: AudioDeviceType.usbAudio,
      );

      final speakerDevice = AudioDevice(
        id: '4',
        name: 'Phone Speaker',
        isInput: false,
        isOutput: true,
        type: AudioDeviceType.builtInSpeaker,
      );

      expect(
        service.resolveCategory({btDevice}),
        equals(AudioOutputCategory.bluetooth),
      );
      expect(
        service.resolveCategory({wiredDevice}),
        equals(AudioOutputCategory.wired),
      );
      expect(
        service.resolveCategory({usbDevice}),
        equals(AudioOutputCategory.usb),
      );
      expect(
        service.resolveCategory({speakerDevice}),
        equals(AudioOutputCategory.speaker),
      );
      expect(service.resolveCategory({}), equals(AudioOutputCategory.speaker));
    });

    test('saveProfile persists to database and reloads on startup', () async {
      const customWired = AudioDeviceProfile(
        id: 'wired',
        name: 'Audiophile IEMs',
        category: AudioOutputCategory.wired,
        equalizerPreset: 'electronic',
        crossfadeSeconds: 2,
        bassBoost: 0.2,
      );

      await service.saveProfile(customWired);

      final retrieved = service.getProfile(AudioOutputCategory.wired);
      expect(retrieved.equalizerPreset, equals('electronic'));
      expect(retrieved.crossfadeSeconds, equals(2));
      expect(retrieved.bassBoost, equals(0.2));
    });

    test('handleDevicesChanged auto-applies profile when deviceProfilesEnabled is true', () async {
      await settingsNotifier.setDeviceProfilesEnabled(true);

      final btDevice = AudioDevice(
        id: 'bt_1',
        name: 'Car Audio Bluetooth',
        isInput: false,
        isOutput: true,
        type: AudioDeviceType.bluetoothA2dp,
      );

      await service.handleDevicesChanged({btDevice});

      expect(service.currentCategory, equals(AudioOutputCategory.bluetooth));
      expect(
        settingsNotifier.currentSettings.activeDeviceProfileId,
        equals('bluetooth'),
      );
      expect(
        settingsNotifier.currentSettings.crossfadeDurationSeconds,
        equals(4),
      );
    });

    test('handleDevicesChanged does not change settings when deviceProfilesEnabled is false', () async {
      await settingsNotifier.setDeviceProfilesEnabled(false);
      await settingsNotifier.setCrossfadeDuration(0);

      final btDevice = AudioDevice(
        id: 'bt_1',
        name: 'Bluetooth Speaker',
        isInput: false,
        isOutput: true,
        type: AudioDeviceType.bluetoothA2dp,
      );

      await service.handleDevicesChanged({btDevice});

      expect(service.currentCategory, equals(AudioOutputCategory.bluetooth));
      // Crossfade duration remains unchanged at 0
      expect(
        settingsNotifier.currentSettings.crossfadeDurationSeconds,
        equals(0),
      );
    });

    test('AudioDeviceProfile serialization round-trip and copyWith', () {
      final original = AudioDeviceProfile.bluetoothDefault().copyWith(
        name: 'Custom BT',
        bassBoost: 0.5,
        monoDownmix: true,
      );

      final json = original.toJson();
      final restored = AudioDeviceProfile.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals('Custom BT'));
      expect(restored.bassBoost, equals(0.5));
      expect(restored.monoDownmix, isTrue);
      expect(restored.category, equals(AudioOutputCategory.bluetooth));
      expect(restored.crossfadeSeconds, equals(original.crossfadeSeconds));
    });
  });
}
