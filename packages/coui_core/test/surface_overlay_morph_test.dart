// The morph as a statement one surface style makes.
//
// Everything here guards the same failure in a different place: an axis
// field that is authored, copied, tuned — and never changes anything,
// because one of the four sites it has to appear in was missed. The CI
// guard catches only total absence and says so; these catch the partial
// case.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('the axis carries a morph', () {
    test('and two recipes differing only in it are not equal', () {
      // The failure this pins is the loudest kind of quiet: the value is
      // computed correctly, `copyWith` works, every test that reads the
      // field passes — and the screen never changes, because the framework
      // decides whether to rebuild by comparing values.
      const base = CoreSurfaceRecipe(id: .defaultStyle, a11y: .defaultSurface);
      final withMorph = base.copyWith(
        overlayMorph: const CoreMorphSpring(speed: CoreMorphSpeed.fast),
      );

      expect(withMorph, isNot(base));
      expect(withMorph.hashCode, isNot(base.hashCode));
    });

    test('and exactly one shipped style states one', () {
      // A four-way negative, not a one-way. It records the scope decision
      // in code, and fails the day a second style copies the line without
      // anyone deciding that it should.
      for (final id in CoreSurfaceStyleId.values) {
        final morph = CoreSurfaceRecipe.of(id).overlayMorph;
        if (id == CoreSurfaceStyleId.liquidGlass) {
          expect(morph, isNotNull, reason: 'liquid glass lost its morph');
        } else {
          expect(morph, isNull, reason: '$id started morphing its overlays');
        }
      }
    });

    test('and it is not part of "this style states nothing"', () {
      // Both consumers of that predicate are about static output — a dead
      // CSS rule, a redundant screenshot row — and a morph emits no CSS and
      // makes no still-frame difference. The trap runs both ways, so the
      // decision is pinned rather than left to a reading.
      const morphOnly = CoreSurfaceRecipe(
        id: .defaultStyle,
        a11y: .defaultSurface,
        overlayMorph: CoreMorphSpring(),
      );

      expect(morphOnly.statesNothing, isTrue);
    });
  });

  group('tuning carries what it does not name', () {
    test('a tuned liquid glass keeps its morph', () {
      // `applyTo` ends in `recipe.copyWith(...)`, so an unnamed field rides
      // through — but only while `copyWith` is complete. That is a silent
      // dependency, and it has already failed once on this carrier: the
      // tuned token dropped `drawsOwnEdge` until a test caught it.
      final base = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);
      final tuned = const CoreSurfaceTuning(
        surfaceOpacity: 0.5,
      ).applyTo(base);

      expect(tuned.overlayMorph, isNotNull);
      expect(tuned.overlayMorph, base.overlayMorph);
    });
  });
}
