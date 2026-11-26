import 'package:test/test.dart';

import '../../src/manifest/material_reach.dart';
import '../../src/manifest/surface_marker_registry.dart';

/// The measurement the matrix prunes on. Two things have to stay true for
/// it to mean anything: the detector reads a whole class token (not a
/// substring), and the real render actually lights it up — a measurement
/// that silently returned empty would prune every material preset for
/// every component and report nothing.
void main() {
  group('htmlCarriesSurfaceMarker', () {
    test('a whole-token match counts', () {
      expect(
        htmlCarriesSurfaceMarker('<div class="p-2 coui-surface rounded">'),
        isTrue,
      );
    });

    test('the role class and the rim variable do not count', () {
      // Both contain the marker as a substring and neither is the marker.
      // A `contains` here would report a surface on an element that has
      // none, and prune nothing for anyone.
      expect(
        htmlCarriesSurfaceMarker('<div class="coui-surface-content">'),
        isFalse,
      );
      expect(
        htmlCarriesSurfaceMarker(
          '<div style="--coui-surface-rim: none" class="x">',
        ),
        isFalse,
      );
    });

    test('an empty document carries nothing', () {
      expect(htmlCarriesSurfaceMarker(''), isFalse);
    });
  });

  group('measureMaterialReachedSlugs (real SSR)', () {
    late final Set<String> reached;

    setUpAll(() async {
      reached = await measureMaterialReachedSlugs();
    });

    test('a component that marks its own root is reached', () {
      // `button` marks unconditionally — if this is missing the SSR path
      // no longer emits the marker and every measurement below is void.
      expect(reached, contains('button'));
    });

    test('a component that only composes a marker is reached', () {
      // `gap`'s example is two `Button`s. This is the case a declared
      // "composes a marker" list named two of, and the nightly found
      // forty-four of.
      expect(reached, contains('gap'));
    });

    test('most own-marker components show the marker in their example', () {
      // Not all: a component that marks conditionally (`accordion` marks
      // only when a fill is stated) renders no marker in its default
      // example, and that is correct — nothing reaches it there. But if
      // fewer than most do, the detector is not seeing what the stylesheet
      // keys off, and the matrix is pruning on a blind measurement.
      final seen = reached.intersection(kSurfaceMarkerComponentSlugs);
      expect(
        seen.length,
        greaterThan(kSurfaceMarkerComponentSlugs.length ~/ 2),
        reason:
            'only ${seen.length} of ${kSurfaceMarkerComponentSlugs.length} '
            'own-marker components render the marker — the detector or the '
            'SSR path changed.',
      );
    });

    test('the measurement is a set of real catalog slugs', () {
      // Cheap sanity on the shape — every reached slug has to be something
      // the matrix can expand.
      expect(reached, isNotEmpty);
      for (final slug in reached) {
        expect(slug, matches(RegExp(r'^[a-z][a-z0-9-]*$')), reason: slug);
      }
    });
  });
}
