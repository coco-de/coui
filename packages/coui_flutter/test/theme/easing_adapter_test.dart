import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoreCubicBezierAdapter.toValue', () {
    test('CoreEasing.linear → Cubic(0,0,1,1)', () {
      final curve = CoreEasing.linear.toValue();
      expect(curve, isA<Cubic>());
      final cubic = curve as Cubic;
      expect(cubic.a, equals(0));
      expect(cubic.b, equals(0));
      expect(cubic.c, equals(1));
      expect(cubic.d, equals(1));
    });

    test('CoreEasing.fastOutSlowIn → Cubic with MD coords', () {
      final cubic = CoreEasing.fastOutSlowIn.toValue() as Cubic;
      expect(cubic.a, equals(0.4));
      expect(cubic.b, equals(0));
      expect(cubic.c, equals(0.2));
      expect(cubic.d, equals(1));
    });

    test('overshoot curves preserve negative / over-1 control points', () {
      final inBack = CoreEasing.easeInBack.toValue() as Cubic;
      expect(inBack.b < 0, isTrue);
      final outBack = CoreEasing.easeOutBack.toValue() as Cubic;
      expect(outBack.d > 1, isTrue);
    });
  });

  group('CoreEasingFunctionAdapter.toValue', () {
    test('decelerate → Curves.decelerate', () {
      expect(
        CoreEasingFunction.decelerate.toValue(),
        same(Curves.decelerate),
      );
    });

    test('bounce variants map to Curves.bounce*', () {
      expect(CoreEasingFunction.bounceIn.toValue(), same(Curves.bounceIn));
      expect(CoreEasingFunction.bounceOut.toValue(), same(Curves.bounceOut));
      expect(
        CoreEasingFunction.bounceInOut.toValue(),
        same(Curves.bounceInOut),
      );
    });

    test('elastic variants map to Curves.elastic*', () {
      expect(CoreEasingFunction.elasticIn.toValue(), same(Curves.elasticIn));
      expect(CoreEasingFunction.elasticOut.toValue(), same(Curves.elasticOut));
      expect(
        CoreEasingFunction.elasticInOut.toValue(),
        same(Curves.elasticInOut),
      );
    });

    test('three-point cubic curves map to Flutter ThreePointCubic', () {
      expect(
        CoreEasingFunction.easeInOutCubicEmphasized.toValue(),
        same(Curves.easeInOutCubicEmphasized),
      );
      expect(
        CoreEasingFunction.fastEaseInToSlowEaseOut.toValue(),
        same(Curves.fastEaseInToSlowEaseOut),
      );
    });

    test('all 9 enum values produce a Curve', () {
      for (final fn in CoreEasingFunction.values) {
        expect(fn.toValue(), isA<Curve>());
      }
    });
  });
}
