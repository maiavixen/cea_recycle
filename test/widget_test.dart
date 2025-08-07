// Flutter widget tests for Recycling App

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_application/main.dart';
import 'package:test_application/recycling_data.dart';

void main() {
  group('Recycling App Widget Tests', () {
    testWidgets('App launches with correct tab structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(CupertinoTabScaffold), findsOneWidget);
      expect(find.text('Districts'), findsOneWidget);
      expect(find.text('Materials'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Sensors'), findsOneWidget);
    });

    testWidgets('District screen displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(DistrictListScreen), findsOneWidget);
      expect(find.text('Districts'), findsOneWidget);

      expect(find.byIcon(CupertinoIcons.search), findsOneWidget);
    });

    testWidgets('District search functionality works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byIcon(CupertinoIcons.search));
      await tester.pump();

      expect(find.byType(CupertinoSearchTextField), findsOneWidget);
      expect(find.text('Search for a district...'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.clear));
      await tester.pump();

      expect(find.byType(CupertinoSearchTextField), findsNothing);
    });

    testWidgets('Materials tab navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Materials'));
      await tester.pump();

      expect(find.byType(MaterialListScreen), findsOneWidget);
    });

    testWidgets('Photo tab navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Photo'));
      await tester.pump();

      expect(find.byType(PhotoCaptureScreen), findsOneWidget);
      expect(find.text('Photo Query'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
    });
    testWidgets('Sensor screen displays sensor data sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Sensors'));
      await tester.pump();

      expect(find.text('Device Sensors'), findsOneWidget);
      expect(find.text('Location Services'), findsOneWidget);
      expect(find.text('Gesture Recognition'), findsOneWidget);
      expect(find.text('Instructions'), findsOneWidget);

      expect(find.text('Accelerometer X'), findsOneWidget);
      expect(find.text('Gyroscope X'), findsOneWidget);
      expect(find.text('Last Gesture'), findsOneWidget);
    });

    testWidgets('Gesture detection UI elements exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Sensors'));
      await tester.pump();

      expect(find.text('Tap Count'), findsOneWidget);
      expect(find.text('Long Press Count'), findsOneWidget);
      expect(find.text('Swipe Count'), findsOneWidget);
      expect(find.text('Reset Gesture Counters'), findsOneWidget);
    });

    testWidgets('Photo screen has correct UI elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Photo'));
      await tester.pump();

      expect(
        find.text('Take a photo of an item to query its recycling potential'),
        findsOneWidget,
      );
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.camera), findsAtLeastNWidgets(1));
    });

    testWidgets('Material screen search functionality', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.text('Materials'));
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.search), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.search));
      await tester.pump();

      expect(find.text('Search for a material...'), findsOneWidget);
    });
  });

  group('Recycling Data Tests', () {
    test('Recycling data is not empty', () {
      expect(recyclingData, isNotEmpty);
      expect(recyclingData.length, greaterThan(0));
    });

    test('District data has required fields', () {
      for (final district in recyclingData) {
        expect(district.district, isNotEmpty);
        expect(district.district, isA<String>());

        expect(district.glass, isA<bool>());
        expect(district.metal, isA<bool>());
        expect(district.paperCardboard, isA<bool>());
        expect(district.plasticPETE, isA<bool>());
      }
    });

    test('At least one district supports each material type', () {
      bool hasGlass = recyclingData.any((d) => d.glass);
      bool hasMetal = recyclingData.any((d) => d.metal);
      bool hasPaper = recyclingData.any((d) => d.paperCardboard);
      bool hasPlastic = recyclingData.any((d) => d.plasticPETE);

      expect(
        hasGlass,
        isTrue,
        reason: 'At least one district should support glass recycling',
      );
      expect(
        hasMetal,
        isTrue,
        reason: 'At least one district should support metal recycling',
      );
      expect(
        hasPaper,
        isTrue,
        reason: 'At least one district should support paper recycling',
      );
      expect(
        hasPlastic,
        isTrue,
        reason: 'At least one district should support plastic recycling',
      );
    });
  });

  group('Material Info Tests', () {
    test('Material list generation works correctly', () {
      final materials = getAllMaterials();
      expect(materials, isNotEmpty);

      for (final material in materials) {
        expect(material.name, isNotEmpty);
        expect(material.districts, isNotEmpty);
        expect(material.districtCount, equals(material.districts.length));
        expect(material.districtCount, greaterThan(0));
      }
    });

    test('Material names are unique', () {
      final materials = getAllMaterials();
      final names = materials.map((m) => m.name).toList();
      final uniqueNames = names.toSet();

      expect(names.length, equals(uniqueNames.length));
    });
  });
}

List<MaterialInfo> getAllMaterials() {
  final materials = <String, MaterialInfo>{};
  final materialDefinitions = {
    'Glass': CupertinoIcons.square,
    'Metal': CupertinoIcons.cube,
    'Paper & Cardboard': CupertinoIcons.square,
    'Plastic PETE': CupertinoIcons.drop,
    'Small Electrics': CupertinoIcons.bolt,
    'Garden Waste': CupertinoIcons.leaf_arrow_circlepath,
  };

  for (final district in recyclingData) {
    final availableMaterials = <String>[];
    if (district.glass) availableMaterials.add('Glass');
    if (district.metal) availableMaterials.add('Metal');
    if (district.paperCardboard) availableMaterials.add('Paper & Cardboard');
    if (district.plasticPETE) availableMaterials.add('Plastic PETE');
    if (district.smallElectrics) availableMaterials.add('Small Electrics');
    if (district.gardenWaste) availableMaterials.add('Garden Waste');

    for (final material in availableMaterials) {
      if (materials.containsKey(material)) {
        materials[material]!.districts.add(district.district);
      } else {
        materials[material] = MaterialInfo(
          name: material,
          icon: materialDefinitions[material] ?? CupertinoIcons.circle,
          districts: [district.district],
          districtCount: 1,
        );
      }
    }
  }

  for (final material in materials.values) {
    materials[material.name] = MaterialInfo(
      name: material.name,
      icon: material.icon,
      districts: material.districts,
      districtCount: material.districts.length,
    );
  }

  return materials.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}
