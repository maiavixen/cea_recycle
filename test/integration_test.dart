// Integration tests for Recycling App

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_application/main.dart';

void main() {
  group('Integration Tests', () {
    testWidgets('Complete app navigation flow', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(DistrictListScreen), findsOneWidget);

      await tester.tap(find.text('Materials'));
      await tester.pump();
      expect(find.byType(MaterialListScreen), findsOneWidget);

      await tester.tap(find.text('Photo'));
      await tester.pump();
      expect(find.byType(PhotoCaptureScreen), findsOneWidget);

      await tester.tap(find.text('Districts'));
      await tester.pump();
      expect(find.byType(DistrictListScreen), findsOneWidget);
    });

    testWidgets('Search functionality across screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byIcon(CupertinoIcons.search));
      await tester.pump();
      expect(find.byType(CupertinoSearchTextField), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.clear));
      await tester.pump();

      await tester.tap(find.text('Materials'));
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.search));
      await tester.pump();
      expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    });

    testWidgets('Sensor screen gesture interaction simulation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Sensors'));
      await tester.pump();
      await tester.pumpAndSettle();

      final gestureDetector = find.byType(GestureDetector);
      expect(gestureDetector, findsOneWidget);

      await tester.tap(gestureDetector);
      await tester.pump();

      expect(find.text('Tap Count'), findsOneWidget);

      await tester.longPress(gestureDetector);
      await tester.pump();

      expect(find.text('Long Press Count'), findsOneWidget);

      await tester.tap(find.text('Reset Gesture Counters'));
      await tester.pump();

      expect(find.text('Gesture Recognition'), findsOneWidget);
    });

    testWidgets('Sensor screen location services button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Sensors'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Refresh Location'), findsOneWidget);

      await tester.tap(find.text('Refresh Location'));
      await tester.pump();

      expect(find.text('Refresh Location'), findsOneWidget);
    });

    testWidgets('Photo screen interaction', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Photo'));
      await tester.pump();

      expect(
        find.text('Take a photo of an item to query its recycling potential'),
        findsOneWidget,
      );
      expect(find.text('Take Photo'), findsOneWidget);

      await tester.tap(find.text('Take Photo'));
      await tester.pump();

      expect(find.text('Take Photo'), findsOneWidget);
    });

    testWidgets('App handles rapid tab switching', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Materials'));
        await tester.pump();

        await tester.tap(find.text('Photo'));
        await tester.pump();

        await tester.tap(find.text('Sensors'));
        await tester.pump();

        await tester.tap(find.text('Districts'));
        await tester.pump();
      }

      expect(find.byType(DistrictListScreen), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('App handles missing data gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Materials'));
      await tester.pump();

      await tester.tap(find.text('Districts'));
      await tester.pump();

      expect(find.byType(CupertinoTabScaffold), findsOneWidget);
    });

    testWidgets('Search handles empty queries', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byIcon(CupertinoIcons.search));
      await tester.pump();

      final searchField = find.byType(CupertinoSearchTextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, '');
      await tester.pump();

      expect(find.byType(DistrictListScreen), findsOneWidget);
    });
  });
}
