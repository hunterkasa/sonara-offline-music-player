import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/models/audio_settings.dart';
import 'package:sonara/domain/models/equalizer_preset.dart';
import 'package:sonara/domain/services/audio_settings_service.dart';

void main() {
  late AppDatabase db;
  late AudioSettingsNotifier notifier;

  setUp(() {
    db = AppDatabase.inMemory();
    notifier = AudioSettingsNotifier(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AudioSettingsNotifier & Persistence', () {
    test('initializes with expected default audio quality settings', () {
      final s = notifier.state;
      expect(s.equalizerEnabled, isFalse);
      expect(s.equalizerPreset, equals('flat'));
      expect(s.bandGains, equals([0.0, 0.0, 0.0, 0.0, 0.0]));
      expect(s.bassBoost, equals(0.0));
      expect(s.loudnessGain, equals(0.0));
      expect(s.crossfadeDurationSeconds, equals(0));
      expect(s.smoothFades, isTrue);
      expect(s.replayGainMode, equals(ReplayGainMode.smart));
      expect(s.replayGainPreAmpDb, equals(0.0));
      expect(s.preventClipping, isTrue);
      expect(s.skipSilence, isFalse);
      expect(s.stereoBalance, equals(0.0));
      expect(s.monoDownmix, isFalse);
      expect(s.longAudioPositionMemory, isTrue);
    });

    test('updates equalizer enabled state', () async {
      await notifier.setEqualizerEnabled(true);
      expect(notifier.state.equalizerEnabled, isTrue);
    });

    test('sets preset and updates band gains accordingly', () async {
      await notifier.setEqualizerPreset('rock');
      expect(notifier.state.equalizerPreset, equals('rock'));
      final rockPreset = EqualizerPreset.getPreset('rock');
      expect(notifier.state.bandGains, equals(rockPreset.bandGainsDb));
    });

    test('setting individual band gain marks preset as custom', () async {
      await notifier.setEqualizerPreset('rock');
      await notifier.setBandGain(0, 6.0);
      expect(notifier.state.equalizerPreset, equals('custom'));
      expect(notifier.state.bandGains[0], equals(6.0));
    });

    test('sets bass boost and loudness gain with clamping', () async {
      await notifier.setBassBoost(1.5); // should clamp to 1.0
      expect(notifier.state.bassBoost, equals(1.0));

      await notifier.setLoudnessGain(12.0); // should clamp to 10.0
      expect(notifier.state.loudnessGain, equals(10.0));
    });

    test('sets crossfade duration clamped between 0 and 12 seconds', () async {
      await notifier.setCrossfadeDuration(8);
      expect(notifier.state.crossfadeDurationSeconds, equals(8));

      await notifier.setCrossfadeDuration(20);
      expect(notifier.state.crossfadeDurationSeconds, equals(12));
    });

    test('sets smooth fades, ReplayGain, and platform controls', () async {
      await notifier.setSmoothFades(false);
      expect(notifier.state.smoothFades, isFalse);

      await notifier.setReplayGainMode(ReplayGainMode.album);
      expect(notifier.state.replayGainMode, equals(ReplayGainMode.album));

      await notifier.setReplayGainPreAmp(3.5);
      expect(notifier.state.replayGainPreAmpDb, equals(3.5));

      await notifier.setPreventClipping(false);
      expect(notifier.state.preventClipping, isFalse);

      await notifier.setSkipSilence(true);
      expect(notifier.state.skipSilence, isTrue);

      await notifier.setStereoBalance(-0.5);
      expect(notifier.state.stereoBalance, equals(-0.5));

      await notifier.setMonoDownmix(true);
      expect(notifier.state.monoDownmix, isTrue);

      await notifier.setLongAudioPositionMemory(false);
      expect(notifier.state.longAudioPositionMemory, isFalse);
    });

    test(
      'persists settings to database and restores across instances',
      () async {
        await notifier.setEqualizerEnabled(true);
        await notifier.setEqualizerPreset('jazz');
        await notifier.setCrossfadeDuration(4);
        await notifier.setBassBoost(0.6);

        // Create new notifier from same database
        final reloadedNotifier = AudioSettingsNotifier(db);
        // Allow async _loadSettings to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final restored = reloadedNotifier.state;
        expect(restored.equalizerEnabled, isTrue);
        expect(restored.equalizerPreset, equals('jazz'));
        expect(restored.crossfadeDurationSeconds, equals(4));
        expect(restored.bassBoost, equals(0.6));
      },
    );
  });
}
