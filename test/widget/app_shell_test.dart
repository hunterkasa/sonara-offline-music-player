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

    // 2. Navigate to Search tab
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Browse All'), findsOneWidget);
    expect(find.byType(SearchBar), findsOneWidget);

    // 3. Navigate to Library tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Your Library'), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);

    // 4. Tap MiniPlayer to expand Now Playing sheet
    await tester.tap(find.byType(MiniPlayer));
    await tester.pumpAndSettle();

    expect(find.text('NOW PLAYING'), findsOneWidget);

    // 5. Collapse Now Playing sheet
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.text('NOW PLAYING'), findsNothing);
    expect(find.text('Your Library'), findsOneWidget);

    await inMemoryDb.close();
  });
}
