import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const List<CoreShadowLayer> _soft = [
  (
    offsetX: 0.0,
    offsetY: 2.0,
    blurRadius: 8.0,
    spreadRadius: 1.0,
    opacity: 0.4,
    inset: false,
  ),
  (
    offsetX: 0.0,
    offsetY: 4.0,
    blurRadius: 16.0,
    spreadRadius: 0.0,
    opacity: 0.2,
    inset: true,
  ),
];

void main() {
  const hard = CoreSurfaceGeometryConstraint(
    shadowBlurScale: 0,
    shadowOffsetScale: 3,
  );
  const identity = CoreSurfaceGeometryConstraint();

  group('a hard cast is a derivation, not a replacement', () {
    test('blur goes to zero', () {
      final bent = hard.shadow(_soft);
      expect(bent.every((l) => l.blurRadius == 0), isTrue);
    });

    test('offset is amplified in the direction the layer already went', () {
      final bent = hard.shadow(_soft);
      expect(bent[0].offsetY, 6);
      expect(bent[1].offsetY, 12);
      expect(bent.every((l) => l.offsetX == 0), isTrue);
    });

    test(
      'the layers, their count and their opacities are the authored ones',
      () {
        // What makes this a derivation: the component still decides how many
        // layers it casts and how strong each is. A style that replaced the
        // stack would be re-authoring every component that has one.
        final bent = hard.shadow(_soft);
        expect(bent, hasLength(_soft.length));
        expect(bent[0].opacity, _soft[0].opacity);
        expect(bent[1].opacity, _soft[1].opacity);
      },
    );

    test('inset layers stay inset', () {
      expect(hard.shadow(_soft)[1].inset, isTrue);
    });

    test('spread is left alone', () {
      // Blur and offset describe how the light falls. Spread changes the
      // size of the shape being cast, so scaling it would make a heavy
      // style quietly grow its components.
      final bent = hard.shadow(_soft);
      expect(bent[0].spreadRadius, _soft[0].spreadRadius);
    });
  });

  group('identity costs nothing', () {
    test('the caller keeps its own list', () {
      expect(identical(identity.shadow(_soft), _soft), isTrue);
    });

    test('a geometry statement about corners alone leaves shadows alone', () {
      const square = CoreSurfaceGeometryConstraint(radiusCap: 0);
      expect(identical(square.shadow(_soft), _soft), isTrue);
    });

    test('an empty stack survives', () {
      expect(hard.shadow(const []), isEmpty);
    });
  });

  group('it is inside identity and equality', () {
    test('a shadow statement makes the constraint non-identity', () {
      // Load-bearing: the Web emitter and the Flutter seat both read this
      // to decide whether the style does anything at all.
      expect(hard.isIdentity, isFalse);
      expect(
        const CoreSurfaceGeometryConstraint(shadowBlurScale: 0).isIdentity,
        isFalse,
      );
      expect(identity.isIdentity, isTrue);
    });

    test('constraints differing only in shadow compare unequal', () {
      expect(hard, isNot(equals(identity)));
      expect(hard.hashCode, isNot(equals(identity.hashCode)));
    });

    test('copyWith carries both scalars', () {
      final both = identity.copyWith(shadowBlurScale: 0, shadowOffsetScale: 2);
      expect(both.shadowBlurScale, 0);
      expect(both.shadowOffsetScale, 2);
    });
  });

  group('the shipped style', () {
    test('neo-brutalism casts a hard shadow', () {
      final geometry = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.neoBrutalism,
      ).geometry;

      expect(geometry.shadowBlurScale, 0);
      // Every authored `CoreShadowLayer`'s `offsetX` is `0` — scaling it
      // stays `0`, which is why the diagonal is stated outright via
      // `shadowOffsetAdd` rather than derived via `shadowOffsetScale`
      // (left at its identity value, `1`).
      expect(geometry.shadowOffsetScale, 1);
      expect(geometry.shadowOffsetAdd, isNotNull);
      expect(geometry.shadowOffsetAdd!.dx, greaterThan(0));
      expect(geometry.shadowOffsetAdd!.dy, greaterThan(0));
      // The nine authored stacks are soft ambient shadows (opacity
      // 0.03–0.12) — a hard edge at that opacity still reads as barely
      // there, so this style states full opacity outright.
      expect(geometry.shadowOpacityOverride, 1);
    });

    test('the soft styles spread their cast instead of sharpening it', () {
      // Clay and neumorphism are the opposite statement from brutalism:
      // more blur, not none. Asserting the direction rather than the exact
      // number keeps this from breaking every time a value is tuned.
      for (final id in <CoreSurfaceStyleId>[
        CoreSurfaceStyleId.claymorphism,
        CoreSurfaceStyleId.neumorphism,
      ]) {
        expect(
          CoreSurfaceRecipe.of(id).geometry.shadowBlurScale,
          greaterThan(1),
          reason: '$id should soften, not sharpen',
        );
      }
    });

    test('the styles that say nothing about shadows leave them alone', () {
      for (final id in <CoreSurfaceStyleId>[
        CoreSurfaceStyleId.defaultStyle,
        CoreSurfaceStyleId.liquidGlass,
      ]) {
        final geometry = CoreSurfaceRecipe.of(id).geometry;
        expect(geometry.shadowBlurScale, 1, reason: '$id');
        expect(geometry.shadowOffsetScale, 1, reason: '$id');
      }
    });
  });
}
