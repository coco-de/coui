import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreZIndex primitive tokens', () {
    test('all values match spec', () {
      expect(CoreZIndex.z0, equals(1000));
      expect(CoreZIndex.z10, equals(1010));
      expect(CoreZIndex.z20, equals(1020));
      expect(CoreZIndex.z30, equals(1030));
      expect(CoreZIndex.z40, equals(1040));
      expect(CoreZIndex.z50, equals(1050));
      expect(CoreZIndex.z60, equals(1060));
      expect(CoreZIndex.z70, equals(1070));
      expect(CoreZIndex.z80, equals(1080));
      expect(CoreZIndex.z90, equals(1090));
      expect(CoreZIndex.z100, equals(1100));
    });

    test('zAuto is the literal "auto"', () {
      expect(CoreZIndex.zAuto, equals('auto'));
    });

    test('values are monotonically increasing with 10 step', () {
      const values = [
        CoreZIndex.z0,
        CoreZIndex.z10,
        CoreZIndex.z20,
        CoreZIndex.z30,
        CoreZIndex.z40,
        CoreZIndex.z50,
        CoreZIndex.z60,
        CoreZIndex.z70,
        CoreZIndex.z80,
        CoreZIndex.z90,
        CoreZIndex.z100,
      ];
      for (var i = 1; i < values.length; i++) {
        expect(values[i] - values[i - 1], equals(10));
      }
    });

    test('z0 starts at 1000 (avoids custom z-index conflicts)', () {
      expect(CoreZIndex.z0, greaterThanOrEqualTo(1000));
    });
  });

  group('CoreZIndex scale record', () {
    test('numeric keys', () {
      expect(CoreZIndex.scale.z0, equals('0'));
      expect(CoreZIndex.scale.z50, equals('50'));
      expect(CoreZIndex.scale.z100, equals('100'));
    });

    test('zAuto key', () {
      expect(CoreZIndex.scale.zAuto, equals('auto'));
    });
  });
}
