import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreBorderRadius', () {
    test('only stores corners verbatim', () {
      const v = CoreBorderRadius.only(
        topLeft: 1,
        topRight: 2,
        bottomLeft: 3,
        bottomRight: 4,
      );
      expect(v.topLeft, 1);
      expect(v.topRight, 2);
      expect(v.bottomLeft, 3);
      expect(v.bottomRight, 4);
    });

    test('all / circular set every corner equally', () {
      const a = CoreBorderRadius.all(8);
      const b = CoreBorderRadius.circular(8);
      for (final v in [a, b]) {
        expect(v.topLeft, 8);
        expect(v.topRight, 8);
        expect(v.bottomLeft, 8);
        expect(v.bottomRight, 8);
      }
      expect(a, equals(b));
    });

    test('vertical sets top / bottom pairs', () {
      const v = CoreBorderRadius.vertical(top: 4, bottom: 8);
      expect(v.topLeft, 4);
      expect(v.topRight, 4);
      expect(v.bottomLeft, 8);
      expect(v.bottomRight, 8);
    });

    test('horizontal sets left / right pairs', () {
      const v = CoreBorderRadius.horizontal(left: 4, right: 8);
      expect(v.topLeft, 4);
      expect(v.bottomLeft, 4);
      expect(v.topRight, 8);
      expect(v.bottomRight, 8);
    });

    test('zero is all-zero', () {
      const v = CoreBorderRadius.zero;
      expect(v.topLeft, 0);
      expect(v.topRight, 0);
      expect(v.bottomLeft, 0);
      expect(v.bottomRight, 0);
    });

    test('equality + hashCode', () {
      const a = CoreBorderRadius.all(8);
      const b = CoreBorderRadius.only(
        topLeft: 8,
        topRight: 8,
        bottomLeft: 8,
        bottomRight: 8,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
