import 'package:coui_web/coui_web.dart'
    show CoreSurfaceRecipe, CoreSurfaceStyleId;
import 'package:test/test.dart';

import '../../src/manifest/surface_style_pruning.dart';

void main() {
  // Fixtures, not a measurement: what this file pins is the RULE — how a
  // reach set and the recipes combine — so the reach set is chosen by hand.
  // `material_reach_test.dart` pins that the measurement itself sees
  // markers.
  const reached = 'card';
  const unreached = 'divider';
  const reach = {reached};

  // Derived from the recipes rather than named, so a sixth preset costs
  // this file nothing (`surface_style_diff_zero_test.dart`'s promise, kept
  // in the tests too).
  final nonDefault = CoreSurfaceStyleId.values.where((id) => id != .defaultId);
  final tokenBending = nonDefault
      .where((id) => CoreSurfaceRecipe.of(id).statesTokenConstraint)
      .toSet();
  final materialOnly = nonDefault
      .where(
        (id) =>
            !kRedundantSurfaceStyles.contains(id) &&
            !CoreSurfaceRecipe.of(id).statesTokenConstraint,
      )
      .toSet();

  group('surfaceStylesFor', () {
    test('defaultStyle is kept for every slug, reached or not', () {
      for (final slug in const [reached, unreached]) {
        expect(
          surfaceStylesFor(slug, materialReach: reach),
          contains(CoreSurfaceStyleId.defaultId),
          reason: slug,
        );
      }
    });

    test('a token-bending preset is kept for an unreached slug', () {
      // The weight floor raises the divider's label whether or not anything
      // in the divider carries a marker — the nightly measured it on 464
      // pruned pairs. Nothing about the component can prune it.
      final kept = surfaceStylesFor(unreached, materialReach: reach).toSet();
      expect(kept, containsAll(tokenBending));
    });

    test('a material-only preset is pruned for an unreached slug', () {
      final kept = surfaceStylesFor(unreached, materialReach: reach).toSet();
      expect(kept.intersection(materialOnly), isEmpty);
    });

    test('a reached slug keeps every non-redundant style', () {
      final kept = surfaceStylesFor(reached, materialReach: reach).toSet();
      expect(
        kept,
        CoreSurfaceStyleId.values.toSet().difference(kRedundantSurfaceStyles),
      );
    });

    test('an empty reach set still keeps every token-bending preset', () {
      // The failure this guards: a measurement that comes back empty (an
      // SSR path that stopped emitting the marker) must not collapse the
      // matrix to defaultStyle-only — only the material half depends on it.
      final kept = surfaceStylesFor(unreached, materialReach: const {});
      expect(kept, containsAll(tokenBending));
      expect(kept, contains(CoreSurfaceStyleId.defaultId));
    });

    test(
      'rule 1 never removes defaultStyle even if its own recipe is silent',
      () {
        // defaultStyle's recipe states nothing by construction (it *is* the
        // baseline) — rule 1 must not treat that as "redundant with itself"
        // and prune it away, or the matrix would have zero rows for the
        // baseline preset.
        expect(
          kRedundantSurfaceStyles,
          isNot(contains(CoreSurfaceStyleId.defaultId)),
        );
      },
    );
  });

  group('prunedSurfaceStylesFor', () {
    test('an unreached slug has exactly the material-only presets pruned', () {
      expect(
        prunedSurfaceStylesFor(unreached, materialReach: reach).toSet(),
        materialOnly.union(kRedundantSurfaceStyles),
      );
    });

    test('a reached slug has only redundant presets pruned', () {
      expect(
        prunedSurfaceStylesFor(reached, materialReach: reach).toSet(),
        kRedundantSurfaceStyles,
      );
    });

    test('defaultStyle is never pruned', () {
      for (final slug in const [reached, unreached]) {
        expect(
          prunedSurfaceStylesFor(slug, materialReach: reach),
          isNot(contains(CoreSurfaceStyleId.defaultId)),
          reason: slug,
        );
      }
    });

    test('kept + pruned reconstructs every style exactly once', () {
      for (final slug in const [reached, unreached]) {
        final kept = surfaceStylesFor(slug, materialReach: reach).toSet();
        final excluded = prunedSurfaceStylesFor(
          slug,
          materialReach: reach,
        ).toSet();
        expect(kept.intersection(excluded), isEmpty, reason: slug);
        expect(
          kept.union(excluded),
          CoreSurfaceStyleId.values.toSet(),
          reason: slug,
        );
      }
    });
  });
}
