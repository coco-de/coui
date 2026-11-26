// The lens is the dome across the whole face — the term the band cannot
// produce because the band is defined to leave the interior alone. Pinned
// here as the function both renderers evaluate, and as the shipped value.
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('the lens pulls every sample toward the centre', () {
    const request = CoreSurfaceRefraction(bezel: 0.27, lens: 0.1);

    test('by a fraction of its distance, per axis, toward the centre', () {
      expect(request.lensDisplacement(100), closeTo(-10, 1e-9));
      expect(request.lensDisplacement(-100), closeTo(10, 1e-9));
      expect(request.lensDisplacement(0), 0);
    });

    test('and the peak on a box is the corner s share', () {
      // The Web map divides by this, so a peak that fell short of the
      // corner would clip the map at exactly the place the dome is
      // strongest.
      expect(request.lensPeak(cornerPx: 250), closeTo(25, 1e-9));
    });

    test('a request with no lens leaves the face flat', () {
      const flat = CoreSurfaceRefraction(bezel: 0.27);

      expect(flat.lensDisplacement(100), 0);
      expect(flat.lensPeak(cornerPx: 250), 0);
    });

    test('and the band term is untouched by it', () {
      // The two are separate terms on purpose — the band fades to nothing
      // at its inner boundary, the lens does not — so stating a lens must
      // not move the rim.
      const flat = CoreSurfaceRefraction(bezel: 0.27);
      for (var inset = 0.0; inset <= 48; inset += 4) {
        expect(
          request.displacementAt(insetPx: inset, bandPx: 48),
          flat.displacementAt(insetPx: inset, bandPx: 48),
        );
      }
    });

    test('a lens past the fold does not build', () {
      expect(
        () => CoreSurfaceRefraction(
          bezel: 0.27,
          lens: double.parse('0.6'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the lens is a value the axis can carry', () {
    test('it participates in equality, hashing, copying and serialising', () {
      const a = CoreSurfaceRefraction(bezel: 0.27, lens: 0.08);
      const b = CoreSurfaceRefraction(bezel: 0.27);

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
      expect(b.copyWith(lens: 0.08), a);
      expect(a.toJson()['lens'], 0.08);
    });

    test('the panel constructor passes it through unconverted', () {
      // Not a panel dial, so no 0–100 scale: the fraction arrives as it is.
      const viaPanel = CoreSurfaceRefraction.figma(
        refraction: 80,
        depth: 27,
        lens: 0.08,
      );

      expect(viaPanel.lens, 0.08);
    });

    test('and the shipped glass states one', () {
      final shipped = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).refraction!;

      expect(shipped.lens, greaterThan(0));
      expect(shipped.lens, lessThanOrEqualTo(CoreSurfaceRefraction.maxLens));
    });
  });

  group('the dispersion unit is Core s', () {
    test(
      'half the bend, so a full dispersion is a fringe and not three images',
      () {
        expect(CoreSurfaceRefraction.dispersionUnit, 0.5);
      },
    );
  });
}
