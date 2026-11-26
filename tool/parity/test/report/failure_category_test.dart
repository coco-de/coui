import 'package:test/test.dart';

import '../../src/report/failure_category.dart';

void main() {
  group('FailureCategory', () {
    test('exactly six categories, matching the issue body wire names', () {
      expect(FailureCategory.values, hasLength(6));
      expect(
        FailureCategory.values.map((c) => c.wireName).toSet(),
        {
          'regression',
          'parity-property',
          'parity-pixel',
          'motion-missing',
          'motion-timing',
          'allowlist-expired',
        },
      );
    });

    test('tryParse round-trips every wire name', () {
      for (final category in FailureCategory.values) {
        expect(FailureCategory.tryParse(category.wireName), category);
      }
    });

    test('tryParse returns null for an unknown value', () {
      expect(FailureCategory.tryParse('nope'), isNull);
    });
  });
}
