import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The three radii that carry almost all of the authored ladder —
/// `radius4` (41 sites), `radius8` (33) and `radius16` (32).
const _ladder = [CoreRadius.radius4, CoreRadius.radius8, CoreRadius.radius16];

CoreSurfaceGeometryConstraint _geometryOf(CoreSurfaceStyleId id) =>
    CoreSurfaceRecipe.of(id).geometry;

void main() {
  group('a stated range redistributes rather than clamps', () {
    test('the authored ladder survives as distinct values', () {
      // The reason this is a redistribution and not a clamp. A floor of
      // 16 applied as `max(px, 16)` maps all three of these to 16, and a
      // chip, a card and a dialog come out equally round — the ladder
      // 106 authored sites wrote would be gone.
      final geometry = _geometryOf(.claymorphism);
      final moved = _ladder.map(geometry.radius).toList();

      expect(
        moved.toSet(),
        hasLength(_ladder.length),
        reason: 'the ladder collapsed to ${moved.toSet()}',
      );
    });

    test('and stays in the same order', () {
      final geometry = _geometryOf(.claymorphism);
      final moved = _ladder.map(geometry.radius).toList();

      expect(moved[0], lessThan(moved[1]));
      expect(moved[1], lessThan(moved[2]));
    });

    test('a range that says rounder produces rounder', () {
      final geometry = _geometryOf(.claymorphism);

      for (final px in _ladder) {
        expect(
          geometry.radius(px),
          greaterThan(px),
          reason: '$px did not move up',
        );
      }
    });
  });

  group('every result lands on the ladder', () {
    test('across each style and the whole authored scale', () {
      // Not tidiness. On Web only ladder values resolve through the
      // `--coui-radius-*` variables; anything else is emitted as a
      // literal, which drops that component out of every preset without
      // any other symptom.
      for (final id in CoreSurfaceStyleId.values) {
        final geometry = _geometryOf(id);

        for (final px in CoreRadius.steps) {
          final moved = geometry.radius(px);

          expect(
            CoreRadius.steps.contains(moved) || moved == 0,
            isTrue,
            reason: '${id.name} moved $px off the ladder, to $moved',
          );
        }
      }
    });
  });

  group('the two sentinels are fixed points', () {
    test('a deliberately square corner stays square', () {
      // Dividers and full-bleed images say 0 on purpose. A style that
      // rounded them would be redrawing a decision it was not asked
      // about — the same rule `stroke` already applies to a zero width.
      for (final id in CoreSurfaceStyleId.values) {
        expect(_geometryOf(id).radius(0), 0, reason: id.name);
      }
    });

    test('a range leaves a pill alone', () {
      // `radius9999` means "fully rounded", not "a large number". 28
      // sites use it, and a range that pulled it down would turn every
      // one of them into a rounded rectangle.
      for (final id in CoreSurfaceStyleId.values) {
        if (_geometryOf(id).radiusCap == 0) continue;
        expect(
          _geometryOf(id).radius(CoreRadius.radius9999),
          CoreRadius.radius9999,
          reason: id.name,
        );
      }
    });

    test('but squaring takes the pill with it', () {
      // Squaring is absolute, not a position on the ladder — a
      // hard-edged material has no rounded ends. Exercised directly
      // against a cap of 0: neo-brutalism no longer ships one (see
      // "neo-brutalism caps corners small" below — the reference
      // implementations it is drawn from keep a slight round rather
      // than a true 0), but the algorithm's absolute-zero behaviour is
      // still real and still needs a test.
      const geometry = CoreSurfaceGeometryConstraint(radiusCap: 0);
      expect(geometry.radius(CoreRadius.radius9999), 0);
    });
  });

  group('neo-brutalism caps corners small', () {
    test('nothing on the ladder exceeds the cap', () {
      // Capped at 6, not squared to 0 — a true 0 reads as raw/unstyled
      // rather than the recognisable "neo-brutalism" look the reference
      // implementations this style is drawn from settle on.
      final geometry = _geometryOf(.neoBrutalism);

      for (final px in _ladder) {
        expect(
          geometry.radius(px),
          lessThanOrEqualTo(CoreRadius.radius6),
          reason: '$px',
        );
      }
    });

    test('a style that states no range changes nothing', () {
      for (final id in [
        CoreSurfaceStyleId.defaultId,
        CoreSurfaceStyleId.liquidGlass,
        CoreSurfaceStyleId.neumorphism,
      ]) {
        final geometry = _geometryOf(id);

        for (final px in _ladder) {
          expect(geometry.radius(px), px, reason: '${id.name} moved $px');
        }
      }
    });
  });

  group('the range is part of the value', () {
    test('two constraints differing only in floor are not equal', () {
      // A theme axis swaps one constraint for another, and the framework
      // decides whether to rebuild by comparing them. A field left out
      // of equality makes the axis compute correctly and change nothing
      // on screen.
      const a = CoreSurfaceGeometryConstraint(radiusFloor: 8, radiusCap: 32);
      const b = CoreSurfaceGeometryConstraint(radiusFloor: 16, radiusCap: 32);

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('copyWith carries the floor', () {
      const base = CoreSurfaceGeometryConstraint(radiusFloor: 8, radiusCap: 32);

      expect(base.copyWith(shadowBlurScale: 2).radiusFloor, 8);
    });

    test('a range makes the constraint non-identity', () {
      const ranged = CoreSurfaceGeometryConstraint(
        radiusFloor: 16,
        radiusCap: 32,
      );

      expect(ranged.isIdentity, isFalse);
      expect(const CoreSurfaceGeometryConstraint().isIdentity, isTrue);
    });
  });
}
