import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/shared/mini_player/mini_player.dart';

void main() {
  testWidgets('MiniPlayer displays track info and responds to tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MiniPlayer(
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    // Initial default state from StubPlaybackController
    expect(find.text('Welcome to Sonara'), findsOneWidget);
    expect(find.text('Ready to play local music'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

    // Tap miniplayer to expand
    await tester.tap(find.byType(MiniPlayer));
    expect(tapped, isTrue);

    // Tap play/pause button
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
  });
}
