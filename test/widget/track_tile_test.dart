import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

void main() {
  testWidgets('TrackTile renders metadata and handles tap', (tester) async {
    const track = Track(
      id: 1,
      trackKey: 'key_123',
      contentUri: 'content://test/1',
      path: '/path/test.mp3',
      relativeDir: '/path',
      title: 'Bohemian Rhapsody',
      titleSort: 'Bohemian Rhapsody',
      durationMs: 354000, // 5:54
      sizeBytes: 8000000,
      hasLyrics: false,
      playCount: 0,
      skipCount: 0,
      isFavorite: false,
      isHidden: false,
      isMissing: false,
      rating: 0,
    );

    var tapped = false;
    var moreTapped = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TrackTile(
              track: track,
              artistName: 'Queen',
              albumName: 'A Night at the Opera',
              trackNumber: 11,
              onTap: () => tapped = true,
              onMore: () => moreTapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bohemian Rhapsody'), findsOneWidget);
    expect(find.text('Queen • A Night at the Opera'), findsOneWidget);
    expect(find.text('5:54'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);

    await tester.tap(find.text('Bohemian Rhapsody'));
    expect(tapped, isTrue);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    expect(moreTapped, isTrue);
  });
}
