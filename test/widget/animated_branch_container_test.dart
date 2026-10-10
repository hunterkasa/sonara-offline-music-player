import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/app/shell/animated_branch_container.dart';

void main() {
  group('AnimatedBranchContainer Widget Tests', () {
    testWidgets(
      'renders active branch and smoothly transitions on tab switch',
      (tester) async {
        int activeIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: AnimatedBranchContainer(
                    currentIndex: activeIndex,
                    duration: const Duration(milliseconds: 200),
                    children: const [
                      Text('Tab 0: Home Content'),
                      Text('Tab 1: Search Content'),
                      Text('Tab 2: Library Content'),
                    ],
                  ),
                  bottomNavigationBar: Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => activeIndex = 0),
                        child: const Text('Go 0'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => activeIndex = 1),
                        child: const Text('Go 1'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => activeIndex = 2),
                        child: const Text('Go 2'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        // Initially Tab 0 is visible and active
        expect(find.text('Tab 0: Home Content'), findsOneWidget);
        expect(find.text('Tab 1: Search Content'), findsNothing); // Offstage
        expect(find.text('Tab 2: Library Content'), findsNothing); // Offstage

        // Switch to Tab 1 (Search)
        await tester.tap(find.text('Go 1'));
        await tester.pump();
        await tester.pump(
          const Duration(milliseconds: 100),
        ); // Halfway through transition

        // During animation, both are rendered on screen (not offstage)
        expect(
          find.text('Tab 0: Home Content', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.text('Tab 1: Search Content', skipOffstage: false),
          findsOneWidget,
        );

        // Finish transition
        await tester.pumpAndSettle();

        // After settling, Tab 1 is visible, Tab 0 is offstage
        expect(find.text('Tab 1: Search Content'), findsOneWidget);
        expect(find.text('Tab 0: Home Content'), findsNothing);
        expect(find.text('Tab 2: Library Content'), findsNothing);

        // Switch to Tab 2 (Library)
        await tester.tap(find.text('Go 2'));
        await tester.pumpAndSettle();

        expect(find.text('Tab 2: Library Content'), findsOneWidget);
        expect(find.text('Tab 1: Search Content'), findsNothing);
        expect(find.text('Tab 0: Home Content'), findsNothing);
      },
    );
  });
}
