import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreStrokeWidth spec primitive tokens', () {
    test('all stroke values match spec', () {
      expect(CoreStrokeWidth.stroke0, equals(0));
      expect(CoreStrokeWidth.stroke0_5, equals(0.5));
      expect(CoreStrokeWidth.stroke1, equals(1));
      expect(CoreStrokeWidth.stroke1_5, equals(1.5));
      expect(CoreStrokeWidth.stroke2, equals(2));
      expect(CoreStrokeWidth.stroke3, equals(3));
      expect(CoreStrokeWidth.stroke4, equals(4));
      expect(CoreStrokeWidth.stroke5, equals(5));
      expect(CoreStrokeWidth.stroke6, equals(6));
      expect(CoreStrokeWidth.stroke8, equals(8));
    });

    test('values are monotonically increasing', () {
      const values = [
        CoreStrokeWidth.stroke0,
        CoreStrokeWidth.stroke0_5,
        CoreStrokeWidth.stroke1,
        CoreStrokeWidth.stroke1_5,
        CoreStrokeWidth.stroke2,
        CoreStrokeWidth.stroke3,
        CoreStrokeWidth.stroke4,
        CoreStrokeWidth.stroke5,
        CoreStrokeWidth.stroke6,
        CoreStrokeWidth.stroke8,
      ];
      for (var i = 1; i < values.length; i++) {
        expect(values[i] > values[i - 1], isTrue);
      }
    });
  });

  group('CoreStrokeWidth.hairlineAt', () {
    test('one pixel below a 2x screen, its own half pixel from there up', () {
      expect(CoreStrokeWidth.hairlineAt(1), CoreStrokeWidth.stroke1);
      expect(CoreStrokeWidth.hairlineAt(1.5), CoreStrokeWidth.stroke1);
      expect(CoreStrokeWidth.hairlineAt(2), CoreStrokeWidth.stroke0_5);
      expect(CoreStrokeWidth.hairlineAt(3), CoreStrokeWidth.stroke0_5);
    });
  });

  group('CoreStrokeWidth.activeBoundaryAt', () {
    test('one pixel below a 2x screen, its own 1.5 from there up', () {
      expect(CoreStrokeWidth.activeBoundaryAt(1), CoreStrokeWidth.stroke1);
      expect(CoreStrokeWidth.activeBoundaryAt(1.5), CoreStrokeWidth.stroke1);
      expect(CoreStrokeWidth.activeBoundaryAt(2), CoreStrokeWidth.stroke1_5);
      expect(CoreStrokeWidth.activeBoundaryAt(3), CoreStrokeWidth.stroke1_5);
    });

    // Both half-pixel steps change on the same screens, so a frame and the
    // hairline beside it never disagree about which screen they are on.
    test('turns at the same ratio as the hairline', () {
      for (final ratio in [1.0, 1.5, 1.99, 2.0, 2.5, 3.0]) {
        expect(
          CoreStrokeWidth.activeBoundaryAt(ratio) == CoreStrokeWidth.stroke1,
          CoreStrokeWidth.hairlineAt(ratio) == CoreStrokeWidth.stroke1,
          reason: 'on a ${ratio}x screen',
        );
      }
    });
  });

  group('CoreStrokeWidth scale record', () {
    test('contains all spec primitive keys', () {
      expect(CoreStrokeWidth.scale.stroke0, equals('stroke0'));
      expect(CoreStrokeWidth.scale.stroke0_5, equals('stroke0_5'));
      expect(CoreStrokeWidth.scale.stroke1, equals('stroke1'));
      // A fractional step spells its point `_`, as the hairline does.
      expect(CoreStrokeWidth.scale.stroke1_5, equals('stroke1_5'));
      expect(CoreStrokeWidth.scale.stroke5, equals('stroke5'));
      expect(CoreStrokeWidth.scale.stroke8, equals('stroke8'));
    });
  });
}
