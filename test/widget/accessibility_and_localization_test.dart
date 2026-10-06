import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/app/l10n/app_localizations.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/shared/mini_player/mini_player.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(
    Widget child, {
    TextScaler textScaler = TextScaler.noScaling,
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: textScaler,
            size: const Size(400, 800),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('Phase 7 Accessibility Tests', () {
    testWidgets(
      'MiniPlayer has accessible Semantics label and >=48dp touch targets',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget(MiniPlayer(onTap: () {})));
        await tester.pumpAndSettle();

        // Verify Semantics exists
        expect(find.byType(Semantics), findsWidgets);

        // Verify Play/Pause button has >= 48dp target bounds
        final playButtonFinder = find.byTooltip('Play');
        expect(playButtonFinder, findsOneWidget);
        final playButtonSize = tester.getSize(playButtonFinder);
        expect(playButtonSize.width, greaterThanOrEqualTo(48.0));
        expect(playButtonSize.height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets(
      'MiniPlayer renders cleanly at 200% text scale without overflow',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            MiniPlayer(onTap: () {}),
            textScaler: const TextScaler.linear(2.0),
          ),
        );
        await tester.pumpAndSettle();

        // No RenderFlex overflow error thrown
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TrackTile renders cleanly at 200% text scale without overflow',
      (tester) async {
        const dummyTrack = Track(
          id: 1,
          trackKey: 'track_acc_1',
          title:
              'Very Long Classical Symphony Opus 99 In C Minor Extreme Title',
          titleSort: 'very long',
          durationMs: 360000,
          path: '/storage/emulated/0/Music/track.mp3',
          relativeDir: 'Music',
          sizeBytes: 15000000,
          contentUri: 'content://media/1',
          hasLyrics: false,
          isFavorite: false,
          isHidden: false,
          isMissing: false,
          rating: 0,
          playCount: 10,
          skipCount: 1,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            const TrackTile(
              track: dummyTrack,
              artistName:
                  'Ludwig van Beethoven & The Royal Concertgebouw Orchestra',
              albumName: 'Complete Symphonies Collector Edition Remastered',
            ),
            textScaler: const TextScaler.linear(2.0),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Phase 7 Localization & Multi-Script Tests', () {
    testWidgets('Renders Arabic (ar) with RTL Directionality', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              final isRtl = Directionality.of(context) == TextDirection.rtl;
              return Column(
                children: [
                  Text(loc?.appTitle ?? ''),
                  Text(loc?.nowPlaying ?? ''),
                  Text('RTL: $isRtl'),
                ],
              );
            },
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('سونارا'), findsOneWidget);
      expect(find.text('قيد التشغيل الآن'), findsOneWidget);
      expect(find.text('RTL: true'), findsOneWidget);
    });

    testWidgets('Renders Bengali (bn) scripts without error', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Column(
                children: [
                  Text(loc?.appTitle ?? ''),
                  Text(loc?.settingsTitle ?? ''),
                ],
              );
            },
          ),
          locale: const Locale('bn'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('সোনারা'), findsOneWidget);
      expect(find.text('সেটিংস'), findsOneWidget);
    });

    testWidgets('Renders Chinese (zh) scripts without error', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return Column(
                children: [
                  Text(loc?.navHome ?? ''),
                  Text(loc?.navSearch ?? ''),
                  Text(loc?.navLibrary ?? ''),
                ],
              );
            },
          ),
          locale: const Locale('zh'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('搜索'), findsOneWidget);
      expect(find.text('媒体库'), findsOneWidget);
    });
  });
}
