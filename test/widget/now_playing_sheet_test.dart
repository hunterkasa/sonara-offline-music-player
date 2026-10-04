import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/features/now_playing/now_playing_sheet.dart';

void main() {
  testWidgets('NowPlayingSheet renders controls and invokes onCollapse', (
    WidgetTester tester,
  ) async {
    var collapsed = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: NowPlayingSheet(
            onCollapse: () {
              collapsed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

    // Tap collapse button
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    expect(collapsed, isTrue);
  });
}
