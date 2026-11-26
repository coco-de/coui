import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreEdgeInsets', () {
    test('fromLTRB stores sides verbatim', () {
      const v = CoreEdgeInsets.fromLTRB(1, 2, 3, 4);
      expect(v.left, 1);
      expect(v.top, 2);
      expect(v.right, 3);
      expect(v.bottom, 4);
    });

    test('all sets every side to the same value', () {
      const v = CoreEdgeInsets.all(8);
      expect(v.left, 8);
      expect(v.top, 8);
      expect(v.right, 8);
      expect(v.bottom, 8);
    });

    test('symmetric sets horizontal / vertical pairs', () {
      const v = CoreEdgeInsets.symmetric(horizontal: 12, vertical: 4);
      expect(v.left, 12);
      expect(v.right, 12);
      expect(v.top, 4);
      expect(v.bottom, 4);
    });

    test('only sets supplied sides', () {
      const v = CoreEdgeInsets.only(left: 1, bottom: 2);
      expect(v.left, 1);
      expect(v.top, 0);
      expect(v.right, 0);
      expect(v.bottom, 2);
    });

    test('zero is all-zero', () {
      const v = CoreEdgeInsets.zero;
      expect(v.left, 0);
      expect(v.top, 0);
      expect(v.right, 0);
      expect(v.bottom, 0);
    });

    test('equality + hashCode', () {
      const a = CoreEdgeInsets.all(8);
      const b = CoreEdgeInsets.fromLTRB(8, 8, 8, 8);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      const c = CoreEdgeInsets.all(9);
      expect(a, isNot(equals(c)));
    });
  });
}
