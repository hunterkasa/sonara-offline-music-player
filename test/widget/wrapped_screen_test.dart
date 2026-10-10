import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/models/wrapped_data.dart';
import 'package:sonara/domain/services/wrapped_service.dart';
import 'package:sonara/features/wrapped/wrapped_screen.dart';

class FakeWrappedService extends WrappedService {
  FakeWrappedService(this.data, AppDatabase db) : super(db);

  final WrappedData data;

  @override
  Future<WrappedData> generateWrapped({
    DateTime? startDate,
    DateTime? endDate,
    String? periodLabel,
  }) async {
    return data;
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('WrappedScreen Widget Tests', () {
    testWidgets('renders empty state when no data exists', (tester) async {
      const emptyData = WrappedData(
        periodLabel: '2026',
        totalListeningMinutes: 0,
        totalTracksPlayed: 0,
        totalPlaysCount: 0,
        topTracks: [],
        topArtists: [],
        topGenres: [],
        mostSkippedTracks: [],
        peakHour: 20,
        peakHourLabel: '8 PM',
        listeningStreakDays: 0,
        personalityTitle: 'The Casual Listener',
        personalityDescription: 'Just dipping your toes.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wrappedServiceProvider.overrideWithValue(
              FakeWrappedService(emptyData, db),
            ),
          ],
          child: const MaterialApp(home: WrappedScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Listening History Yet'), findsOneWidget);
      expect(
        find.textContaining(
          'Play some tunes in Sonara to generate your 100% offline Wrapped recap!',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders story cards with top stats and export button when data exists',
      (tester) async {
        const sampleData = WrappedData(
          periodLabel: '2026',
          totalListeningMinutes: 1420,
          totalTracksPlayed: 85,
          totalPlaysCount: 320,
          topTracks: [
            WrappedTrack(
              trackKey: 'track_1',
              title: 'Electric Dreams',
              artist: 'Synthwave Odyssey',
              playCount: 42,
              durationMs: 220000,
            ),
            WrappedTrack(
              trackKey: 'track_2',
              title: 'Midnight Drive',
              artist: 'Neon Rider',
              playCount: 30,
              durationMs: 190000,
            ),
          ],
          topArtists: [
            WrappedArtist(
              name: 'Synthwave Odyssey',
              playCount: 110,
              totalMinutes: 450,
            ),
          ],
          topGenres: [
            WrappedGenre(name: 'Electronic', trackCount: 50, percentage: 65.0),
          ],
          mostSkippedTracks: [],
          peakHour: 22,
          peakHourLabel: '10 PM',
          listeningStreakDays: 14,
          personalityTitle: 'The Night Owl Audiophile',
          personalityDescription:
              'You thrive when the rest of the world is asleep.',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              wrappedServiceProvider.overrideWithValue(
                FakeWrappedService(sampleData, db),
              ),
            ],
            child: const MaterialApp(home: WrappedScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Card 0: Welcome overview card
        expect(find.text('Your Year in Sound.'), findsOneWidget);
        expect(find.text('1420 Minutes'), findsOneWidget); // Total minutes
        expect(find.textContaining('85 unique local tracks'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        // Tap on the right side to advance to card 1 (Top Tracks)
        await tester.tapAt(const Offset(700, 300));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Card 1: Top Tracks
        expect(find.text('Electric Dreams'), findsOneWidget);
        expect(find.text('Synthwave Odyssey'), findsWidgets);
      },
    );
  });
}
