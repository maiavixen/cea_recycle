// Unit tests for data models and business logic

import 'package:flutter_test/flutter_test.dart';
import 'package:test_application/recycling_data.dart';

void main() {
  group('DistrictRecycling Model Tests', () {
    test('DistrictRecycling constructor creates valid object', () {
      final district = DistrictRecycling(
        district: 'Test District',
        glass: true,
        metal: false,
        paperCardboard: true,
        plasticPETE: false,
        plasticPVC: true,
        plasticHDPE: false,
        plasticPP: true,
        smallElectrics: false,
        gardenWaste: true,
      );

      expect(district.district, equals('Test District'));
      expect(district.glass, isTrue);
      expect(district.metal, isFalse);
      expect(district.paperCardboard, isTrue);
      expect(district.plasticPETE, isFalse);
      expect(district.plasticPVC, isTrue);
      expect(district.plasticHDPE, isFalse);
      expect(district.plasticPP, isTrue);
      expect(district.smallElectrics, isFalse);
      expect(district.gardenWaste, isTrue);
    });

    test('All districts have valid names', () {
      for (final district in recyclingData) {
        expect(district.district, isNotNull);
        expect(district.district, isNotEmpty);
        expect(district.district.trim(), equals(district.district));
      }
    });

    test('Districts have at least one recycling option', () {
      for (final district in recyclingData) {
        final hasAnyRecycling =
            district.glass ||
            district.metal ||
            district.paperCardboard ||
            district.plasticPETE ||
            district.plasticPVC ||
            district.plasticHDPE ||
            district.plasticPP ||
            district.smallElectrics ||
            district.gardenWaste;

        expect(
          hasAnyRecycling,
          isTrue,
          reason:
              'District ${district.district} should have at least one recycling option',
        );
      }
    });

    test('District names are unique', () {
      final names = recyclingData.map((d) => d.district).toList();
      final uniqueNames = names.toSet();

      expect(
        names.length,
        equals(uniqueNames.length),
        reason: 'All district names should be unique',
      );
    });
  });

  group('Recycling Data Validation', () {
    test('Recycling data contains expected number of districts', () {
      expect(recyclingData.length, greaterThan(0));
      expect(recyclingData.length, lessThan(1000)); // Reasonable upper bound
    });

    test('Each material type is supported by at least one district', () {
      final materialSupport = {
        'glass': false,
        'metal': false,
        'paperCardboard': false,
        'plasticPETE': false,
        'plasticHDPE': false,
        'plasticPP': false,
        'smallElectrics': false,
        'gardenWaste': false,
      };

      for (final district in recyclingData) {
        if (district.glass) materialSupport['glass'] = true;
        if (district.metal) materialSupport['metal'] = true;
        if (district.paperCardboard) materialSupport['paperCardboard'] = true;
        if (district.plasticPETE) materialSupport['plasticPETE'] = true;
        if (district.plasticHDPE) materialSupport['plasticHDPE'] = true;
        if (district.plasticPP) materialSupport['plasticPP'] = true;
        if (district.smallElectrics) materialSupport['smallElectrics'] = true;
        if (district.gardenWaste) materialSupport['gardenWaste'] = true;
      }

      materialSupport.forEach((material, isSupported) {
        expect(
          isSupported,
          isTrue,
          reason: 'At least one district should support $material recycling',
        );
      });
    });

    test('Data consistency - plastic types distribution', () {
      int peteCount = 0;
      int hdpeCount = 0;
      int ppCount = 0;

      for (final district in recyclingData) {
        if (district.plasticPETE) peteCount++;
        if (district.plasticHDPE) hdpeCount++;
        if (district.plasticPP) ppCount++;
      }

      expect(
        peteCount,
        greaterThan(0),
        reason: 'Some districts should support PETE plastic',
      );
      expect(
        hdpeCount,
        greaterThan(0),
        reason: 'Some districts should support HDPE plastic',
      );
      expect(
        ppCount,
        greaterThan(0),
        reason: 'Some districts should support PP plastic',
      );
    });
  });

  group('Data Analysis Tests', () {
    test('Calculate recycling coverage statistics', () {
      final totalDistricts = recyclingData.length;

      final glassDistricts = recyclingData.where((d) => d.glass).length;
      final metalDistricts = recyclingData.where((d) => d.metal).length;
      final paperDistricts =
          recyclingData.where((d) => d.paperCardboard).length;

      final glassPercentage = (glassDistricts / totalDistricts) * 100;
      final metalPercentage = (metalDistricts / totalDistricts) * 100;
      final paperPercentage = (paperDistricts / totalDistricts) * 100;

      expect(glassPercentage, greaterThanOrEqualTo(10.0));
      expect(metalPercentage, greaterThanOrEqualTo(10.0));
      expect(paperPercentage, greaterThanOrEqualTo(10.0));
    });

    test('Find districts with comprehensive recycling support', () {
      final comprehensiveDistricts =
          recyclingData.where((district) {
            int supportedTypes = 0;
            if (district.glass) supportedTypes++;
            if (district.metal) supportedTypes++;
            if (district.paperCardboard) supportedTypes++;
            if (district.plasticPETE) supportedTypes++;
            if (district.smallElectrics) supportedTypes++;
            if (district.gardenWaste) supportedTypes++;

            return supportedTypes >= 4;
          }).toList();

      expect(
        comprehensiveDistricts,
        isNotEmpty,
        reason:
            'At least some districts should support multiple recycling types',
      );
    });

    test('Verify data sorting and filtering capabilities', () {
      final sortedDistricts = [...recyclingData];
      sortedDistricts.sort((a, b) => a.district.compareTo(b.district));

      expect(sortedDistricts.length, equals(recyclingData.length));

      // Verify first item is alphabetically first
      expect(
        sortedDistricts.first.district.compareTo(sortedDistricts.last.district),
        lessThanOrEqualTo(0),
      );

      // Test filtering by material type
      final glassDistricts = recyclingData.where((d) => d.glass).toList();
      final metalDistricts = recyclingData.where((d) => d.metal).toList();

      expect(glassDistricts.every((d) => d.glass), isTrue);
      expect(metalDistricts.every((d) => d.metal), isTrue);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('Handle empty district name edge case', () {
      // Verify no district has empty or whitespace-only name
      for (final district in recyclingData) {
        expect(district.district.trim(), isNotEmpty);
        expect(district.district, isNot(matches(r'^\s*$')));
      }
    });

    test('Verify boolean field consistency', () {
      for (final district in recyclingData) {
        // Verify all boolean fields are actually booleans
        expect(district.glass, isA<bool>());
        expect(district.metal, isA<bool>());
        expect(district.paperCardboard, isA<bool>());
        expect(district.plasticPETE, isA<bool>());
        expect(district.plasticPVC, isA<bool>());
        expect(district.plasticHDPE, isA<bool>());
        expect(district.plasticPP, isA<bool>());
        expect(district.smallElectrics, isA<bool>());
        expect(district.gardenWaste, isA<bool>());
      }
    });
  });
}
