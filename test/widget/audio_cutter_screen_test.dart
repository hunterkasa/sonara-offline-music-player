import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/audio_cutter/audio_cutter_screen.dart';
import 'package:sonara/features/audio_cutter/widgets/waveform_trimmer.dart';

class MockHapticService implements HapticService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final methodCalls = <MethodCall>[];

  setUp(() async {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.example.sonara/audio_cutter'),
          (MethodCall methodCall) async {
            methodCalls.add(methodCall);
            switch (methodCall.method) {
              case 'trimAudio':
                return true;
              case 'setAsRingtone':
                return true;
              case 'canWriteSystemSettings':
                return true;
              case 'openWriteSettings':
                return true;
              case 'shareAudio':
                return true;
              default:
                return null;
            }
          },
        );

    // In-memory sqlite db
    db = AppDatabase.inMemory();

    // Seed test artist
    final artistId = await db.getOrCreateArtist('Beethoven');

    // Seed test track
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'cut_test_key_1',
            title: 'Cutter Symphony No. 5',
            titleSort: 'cutter symphony no. 5',
            contentUri: 'content://media/external/audio/media/101',
            path: '/storage/music/beethoven_5.mp3',
            artistId: Value(artistId),
            durationMs: 180000, // 3 minutes
            sizeBytes: 5000000,
          ),
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.example.sonara/audio_cutter'),
          null,
        );
    await db.close();
  });

  testWidgets(
    'AudioCutterScreen renders waveform trimmer, time indicators and controls',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            hapticServiceProvider.overrideWithValue(MockHapticService()),
          ],
          child: const MaterialApp(
            home: AudioCutterScreen(trackKey: 'cut_test_key_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify track information
      expect(find.text('Cutter Symphony No. 5'), findsOneWidget);
      expect(find.text('Beethoven'), findsOneWidget);
      expect(find.text('MP3'), findsOneWidget);

      // Verify Waveform Trimmer widget
      expect(find.byType(WaveformTrimmer), findsOneWidget);

      // Verify Time Stats Card
      expect(find.text('Start Point'), findsOneWidget);
      expect(find.text('Clip Duration'), findsOneWidget);
      expect(find.text('End Point'), findsOneWidget);
      expect(find.text('00:00.00'), findsOneWidget); // Initial start
      expect(
        find.text('00:30.00'),
        findsNWidgets(2),
      ); // Initial clip duration & end

      // Verify Nudge controls
      expect(find.text('Start Marker'), findsOneWidget);
      expect(find.text('End Marker'), findsOneWidget);
      expect(find.text('+1s'), findsNWidgets(2));
      expect(find.text('-1s'), findsNWidgets(2));

      // Verify Action Buttons
      expect(find.text('Set as Phone Ringtone'), findsOneWidget);
      expect(find.text('Notification'), findsOneWidget);
      expect(find.text('Alarm Tone'), findsOneWidget);
      expect(find.text('Save Clip'), findsOneWidget);
      expect(find.text('Share Clip'), findsOneWidget);

      // Test nudging Start Marker by +1s
      final plusOneSecStart = find.widgetWithText(OutlinedButton, '+1s').first;
      await tester.tap(plusOneSecStart);
      await tester.pumpAndSettle();

      expect(
        find.text('00:01.00'),
        findsOneWidget,
      ); // Start marker updated to 1 second
      expect(
        find.text('00:29.00'),
        findsOneWidget,
      ); // Clip duration updated to 29 seconds

      // Test loop toggle
      final loopButton = find.byTooltip('Looping enabled');
      expect(loopButton, findsOneWidget);
      await tester.tap(loopButton);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Looping disabled'), findsOneWidget);

      // Test Save Clip action
      final saveButton = find.widgetWithText(OutlinedButton, 'Save Clip');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pump();
    },
  );
}
