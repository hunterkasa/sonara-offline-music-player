import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/audio_settings/equalizer_screen.dart';

void main() {
  testWidgets('EqualizerScreen renders all controls and interacts properly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final inMemoryDb = AppDatabase.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
        child: const MaterialApp(home: EqualizerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and bypass toggle
    expect(find.text('Equalizer'), findsOneWidget);
    expect(find.text('OFF'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Verify presets
    expect(find.text('PRESETS'), findsOneWidget);
    expect(find.text('Flat'), findsOneWidget);
    expect(find.text('Rock'), findsOneWidget);

    // Verify band labels
    expect(find.text('60 Hz'), findsOneWidget);
    expect(find.text('230 Hz'), findsOneWidget);
    expect(find.text('910 Hz'), findsOneWidget);
    expect(find.text('3.6 kHz'), findsOneWidget);
    expect(find.text('14 kHz'), findsOneWidget);

    // Verify sound enhancements
    expect(find.text('SOUND ENHANCEMENTS'), findsOneWidget);
    expect(
      find.text('Bass Boost'),
      findsNWidgets(2),
    ); // Preset chip + enhancement card
    expect(find.text('Loudness Enhancer'), findsOneWidget);
    expect(find.text('Reset All to Flat'), findsOneWidget);

    // Toggle Equalizer ON
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('ON'), findsOneWidget);

    // Select 'Rock' preset
    await tester.tap(find.text('Rock'));
    await tester.pumpAndSettle();

    // Verify reset button works
    await tester.tap(find.text('Reset All to Flat'));
    await tester.pumpAndSettle();

    await inMemoryDb.close();
  });
}
