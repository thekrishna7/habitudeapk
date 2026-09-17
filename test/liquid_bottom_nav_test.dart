import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/core/widgets/liquid_bottom_nav.dart';

void main() {
  group('LiquidBottomNav Widget Tests', () {
    testWidgets('Renders all 4 navigation items without overflow on small screens (320px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Content')),
            bottomNavigationBar: LiquidBottomNav(
              currentIndex: selectedIndex,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Verify all tab labels are rendered
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify no overflow exception occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping on a tab invokes onTap callback with correct index',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: LiquidBottomNav(
              currentIndex: 1,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on 'Progress' tab (index 2)
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 2);

      // Tap on 'Profile' tab (index 3)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 3);
    });
  });
}
