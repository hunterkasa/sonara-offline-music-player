import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/main.dart';
import 'package:sonara/shared/mini_player/mini_player.dart';

void main() {
  testWidgets('Sonara App Shell golden path navigation & player test', (
    WidgetTester tester,
  ) async {
    final inMemoryDb = AppDatabase.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
        child: const SonaraApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial screen: Home tab
    expect(find.text('Liked Songs'), findsOneWidget);
    expect(find.text('Shuffle All'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(MiniPlayer), findsOneWidget);

    // Verify AppBar greeting, brand logo, and theme toggle button
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Good morning' ||
                w.data == 'Good afternoon' ||
                w.data == 'Good evening'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Tooltip && (w.message?.startsWith('Theme:') ?? false),
      ),
      findsOneWidget,
    );

    // 2. Navigate to Search tab
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Browse All'), findsOneWidget);
    expect(find.byType(SearchBar), findsOneWidget);

    // 3. Navigate to Library tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Your Library'), findsOneWidget);
    expect(find.text('No songs found in your library'), findsOneWidget);

    // 4. Tap MiniPlayer to expand Now Playing sheet
    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.text('NOW PLAYING'), findsOneWidget);

    // 5. Collapse Now Playing sheet
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.text('NOW PLAYING'), findsNothing);
    expect(find.text('Your Library'), findsOneWidget);

    // 6. Tap MiniPlayer to expand Now Playing, then tap Home button in bottom nav
    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.text('NOW PLAYING'), findsOneWidget);

    // Tapping Home button should minimize the player window and navigate to Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('NOW PLAYING'), findsNothing);
    expect(find.text('Liked Songs'), findsOneWidget);

    await inMemoryDb.close();
  });
}
