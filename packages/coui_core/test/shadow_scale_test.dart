import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreShadow tokens', () {
    test('none is empty', () {
      expect(CoreShadow.none, isEmpty);
    });

    test('the attached lifts have 2 layers (Sharp + Diffuse)', () {
      expect(CoreShadow.xs, hasLength(2));
      expect(CoreShadow.sm, hasLength(2));
    });

    test('the floating rungs from md up have one layer and no spread', () {
      for (final token in [
        CoreShadow.md,
        CoreShadow.lg,
        CoreShadow.xl,
        CoreShadow.xl2,
        CoreShadow.xl3,
      ]) {
        expect(token, hasLength(1));
        expect(token.single.spreadRadius, 0);
        expect(token.single.offsetX, 0);
      }
    });

    test('inset has 1 layer with inset=true', () {
      expect(CoreShadow.inset, hasLength(1));
      expect(CoreShadow.inset.first.inset, isTrue);
    });

    test('elevated layers have inset=false', () {
      for (final token in [
        CoreShadow.xs,
        CoreShadow.sm,
        CoreShadow.md,
        CoreShadow.lg,
        CoreShadow.xl,
        CoreShadow.xl2,
        CoreShadow.xl3,
      ]) {
        for (final layer in token) {
          expect(layer.inset, isFalse);
        }
      }
    });
  });

  group('CoreShadow spec values', () {
    test('xs Layer 1: offsetY=1, blur=2, spread=0, opacity=0.04', () {
      final l1 = CoreShadow.xs[0];
      expect(l1.offsetX, equals(0));
      expect(l1.offsetY, equals(1));
      expect(l1.blurRadius, equals(2));
      expect(l1.spreadRadius, equals(0));
      expect(l1.opacity, equals(0.04));
    });

    // The light alphas are the v2 dark ones ÷ CoreShadow.darkStrength, so
    // a dark theme draws exactly the v2 values (md 0.40, lg · xl 0.50).
    test('md: 0/8/24/0 at 0.10', () {
      final l = CoreShadow.md.single;
      expect(
        (l.offsetY, l.blurRadius, l.spreadRadius, l.opacity),
        (8, 24, 0, 0.10),
      );
    });

    test('lg: 0/16/40/0 at 0.125', () {
      final l = CoreShadow.lg.single;
      expect(
        (l.offsetY, l.blurRadius, l.spreadRadius, l.opacity),
        (16, 40, 0, 0.125),
      );
    });

    test('xl: 0/24/64/0 at 0.125', () {
      final l = CoreShadow.xl.single;
      expect(
        (l.offsetY, l.blurRadius, l.spreadRadius, l.opacity),
        (24, 64, 0, 0.125),
      );
    });

    test('2xl · 3xl stay above xl: 0/32/80/0 at 0.14, 0/40/96/0 at 0.15', () {
      final l2 = CoreShadow.xl2.single;
      final l3 = CoreShadow.xl3.single;
      expect(
        (l2.offsetY, l2.blurRadius, l2.spreadRadius, l2.opacity),
        (32, 80, 0, 0.14),
      );
      expect(
        (l3.offsetY, l3.blurRadius, l3.spreadRadius, l3.opacity),
        (40, 96, 0, 0.15),
      );
    });

    test('dark strength is 4 — v2 dark md 0.40, lg · xl 0.50', () {
      expect(CoreShadow.darkStrength, 4);
      expect(CoreShadow.md.single.opacity * CoreShadow.darkStrength, 0.40);
      expect(CoreShadow.lg.single.opacity * CoreShadow.darkStrength, 0.50);
      expect(CoreShadow.xl.single.opacity * CoreShadow.darkStrength, 0.50);
    });

    test('inset: offsetY=2, blur=4, opacity=0.06', () {
      final l = CoreShadow.inset.first;
      expect(l.offsetY, equals(2));
      expect(l.blurRadius, equals(4));
      expect(l.spreadRadius, equals(0));
      expect(l.opacity, equals(0.06));
    });
  });

  group('CoreShadow elevation progression', () {
    test('blur grows with every rung', () {
      final blurs = [
        for (final token in [
          CoreShadow.xs,
          CoreShadow.sm,
          CoreShadow.md,
          CoreShadow.lg,
          CoreShadow.xl,
          CoreShadow.xl2,
          CoreShadow.xl3,
        ])
          token.first.blurRadius,
      ];
      for (var i = 1; i < blurs.length; i++) {
        expect(blurs[i], greaterThan(blurs[i - 1]), reason: 'rung $i');
      }
    });

    test('Layer 1 offset-y is monotonically increasing', () {
      const offsets = [
        1, // xs
        2, // sm
        8, // md
        16, // lg
        24, // xl
        32, // xl2
        40, // xl3
      ];
      final actual = [
        CoreShadow.xs[0].offsetY.toInt(),
        CoreShadow.sm[0].offsetY.toInt(),
        CoreShadow.md[0].offsetY.toInt(),
        CoreShadow.lg[0].offsetY.toInt(),
        CoreShadow.xl[0].offsetY.toInt(),
        CoreShadow.xl2[0].offsetY.toInt(),
        CoreShadow.xl3[0].offsetY.toInt(),
      ];
      expect(actual, equals(offsets));
    });
  });

  group('CoreShadow scale record (CSS keys)', () {
    test('CSS key mapping uses 2xl/3xl', () {
      expect(CoreShadow.scale.none, equals('none'));
      expect(CoreShadow.scale.xs, equals('xs'));
      expect(CoreShadow.scale.md, equals('md'));
      expect(CoreShadow.scale.xl, equals('xl'));
      expect(CoreShadow.scale.xl2, equals('2xl'));
      expect(CoreShadow.scale.xl3, equals('3xl'));
      expect(CoreShadow.scale.inset, equals('inset'));
    });
  });
}
