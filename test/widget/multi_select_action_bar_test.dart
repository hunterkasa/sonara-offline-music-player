import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/shared/selection/multi_select_action_bar.dart';

void main() {
  group('MultiSelectActionBar Widget Tests', () {
    testWidgets('renders selection count and action buttons', (tester) async {
      var clearCalled = false;
      var selectAllCalled = false;
      var playCalled = false;
      var queueCalled = false;
      var playlistCalled = false;
      var favoriteCalled = false;
      var deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectActionBar(
              selectedCount: 3,
              totalCount: 10,
              onClear: () => clearCalled = true,
              onSelectAll: () => selectAllCalled = true,
              onPlay: () => playCalled = true,
              onAddToQueue: () => queueCalled = true,
              onAddToPlaylist: () => playlistCalled = true,
              onFavorite: () => favoriteCalled = true,
              onDelete: () => deleteCalled = true,
              deleteLabel: 'Delete',
            ),
          ),
        ),
      );

      expect(find.text('3 selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Playlist'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(playCalled, isTrue);

      await tester.tap(find.text('Queue'));
      await tester.pump();
      expect(queueCalled, isTrue);

      await tester.tap(find.text('Playlist'));
      await tester.pump();
      expect(playlistCalled, isTrue);

      await tester.tap(find.text('Favorite'));
      await tester.pump();
      expect(favoriteCalled, isTrue);

      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(deleteCalled, isTrue);

      await tester.tap(find.text('Select All'));
      await tester.pump();
      expect(selectAllCalled, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(clearCalled, isTrue);
    });

    testWidgets('shows Deselect All when all items are selected', (
      tester,
    ) async {
      var clearCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectActionBar(
              selectedCount: 5,
              totalCount: 5,
              onClear: () => clearCalled = true,
              onSelectAll: () {},
              onPlay: () {},
              onAddToQueue: () {},
              onAddToPlaylist: () {},
            ),
          ),
        ),
      );

      expect(find.text('5 selected'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);

      await tester.tap(find.text('Deselect All'));
      await tester.pump();
      expect(clearCalled, isTrue);
    });
  });
}
