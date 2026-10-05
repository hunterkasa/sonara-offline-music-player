import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/audio_settings/audio_settings_screen.dart';

void main() {
  testWidgets(
    'AudioSettingsScreen renders all sections and handles interaction',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final inMemoryDb = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
          child: const MaterialApp(home: AudioSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title & Sections
      expect(find.text('Audio Settings'), findsOneWidget);
      expect(find.text('EQUALIZER & SOUND EFFECTS'), findsOneWidget);
      expect(find.text('PLAYBACK TRANSITIONS'), findsOneWidget);
      expect(find.text('VOLUME NORMALIZATION (REPLAYGAIN)'), findsOneWidget);
      expect(find.text('PLAYBACK ENGINE & HARDWARE'), findsOneWidget);
      expect(find.text('LONG AUDIO RESUMPTION'), findsOneWidget);

      // Verify key controls exist
      expect(find.text('Equalizer & Presets'), findsOneWidget);
      expect(find.text('Crossfade Duration'), findsOneWidget);
      expect(find.text('Smooth Volume Fades'), findsOneWidget);
      expect(find.text('ReplayGain Mode'), findsOneWidget);
      expect(find.text('Pre-Amp Gain'), findsOneWidget);
      expect(find.text('Prevent Clipping'), findsOneWidget);
      expect(find.text('Skip Silence'), findsOneWidget);
      expect(find.text('Stereo Channel Balance'), findsOneWidget);
      expect(find.text('Mono Downmix'), findsOneWidget);
      expect(find.text('Long-Audio Position Memory'), findsOneWidget);

      // Open ReplayGain Mode Dialog
      await tester.tap(find.text('ReplayGain Mode'));
      await tester.pumpAndSettle();

      expect(find.text('Track Gain'), findsOneWidget);
      expect(find.text('Album Gain'), findsOneWidget);

      // Select Album Gain
      await tester.tap(find.text('Album Gain'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and setting updated
      expect(
        find.text('Album Gain (Preserves album dynamic master)'),
        findsOneWidget,
      );

      await inMemoryDb.close();
    },
  );
}
