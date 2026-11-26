// The rim on Web is two halves: a size-independent ring the stylesheet
// draws, and a per-element sweep the runtime writes. The first is pinned
// here as emitted CSS; the second as the pure adapter the runtime calls,
// because a document is what the runtime needs and this suite has none.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/theme_config.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:test/test.dart';

String _ring(CoreSurfaceStyleId id, CoreSurfaceRole role) {
  final css = ThemeConfig.defaults().surfaceStyleTreatmentBlock(
    id,
    CoreSurfaceRecipe.of(id).surfaceFor(role),
    role: role,
  );
  final roleClass = switch (role) {
    CoreSurfaceRole.content => kWebSurfaceRoleContent,
    CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
  };
  final at = css.indexOf('.$kWebSurfaceMarker.$roleClass::before{');
  if (at < 0) return '';

  return css.substring(at, css.indexOf('}', at) + 1);
}

void main() {
  group('the stylesheet draws the ring', () {
    for (final role in CoreSurfaceRole.values) {
      test('on the ${role.name} role under liquid glass', () {
        final ring = _ring(CoreSurfaceStyleId.liquidGlass, role);

        expect(ring, isNotEmpty, reason: 'no ring rule for ${role.name}');
        // The gradient is the element's, read through the variable, and
        // absent rather than guessed when nothing wrote it.
        expect(ring, contains('background:var($kWebSurfaceRimSweepVar,none)'));
        // A ring, not a fill: masked to its own padding, both spellings.
        expect(ring, contains('mask-composite:exclude'));
        expect(ring, contains('-webkit-mask-composite:xor'));
        expect(ring, contains('padding:var(--coui-stroke-width-2)'));
        expect(ring, contains('border-radius:inherit'));
        expect(ring, contains('pointer-events:none'));
      });
    }

    test('and not for a style whose wall states no rim', () {
      for (final id in CoreSurfaceStyleId.values) {
        if (id == CoreSurfaceStyleId.liquidGlass) continue;
        for (final role in CoreSurfaceRole.values) {
          expect(
            _ring(id, role),
            isEmpty,
            reason: '${id.name}/${role.name} draws a ring it does not state',
          );
        }
      }
    });
  });

  group('the sweep is Core s stops, spelled as a conic gradient', () {
    const profile = CoreSurfaceEdgeBevel(
      thickness: 2,
      lightAngle: -45,
      lightIntensity: 0.8,
      rimWidth: 1,
      rimIntensity: 0.9,
    );

    test('starts at the top and runs clockwise, as the stops are stated', () {
      final css = surfaceEdgeRimSweepCss(
        profile,
        width: 200,
        height: 60,
        radius: 12,
      );

      expect(css, startsWith('conic-gradient(from 0deg at 50% 50%,'));
      expect(css, endsWith(' 360.00deg)'));
      expect(css, contains('rgb(var(--coui-surface-highlight) / '));
    });

    test('carries every stop Core sampled, in order', () {
      final stops = profile.rimSweep(width: 200, height: 60, radius: 12);
      final css = surfaceEdgeRimSweepCss(
        profile,
        width: 200,
        height: 60,
        radius: 12,
      );

      var cursor = 0;
      for (final stop in stops) {
        final at = css.indexOf('${stop.angle.toStringAsFixed(2)}deg', cursor);
        expect(
          at,
          greaterThanOrEqualTo(cursor),
          reason: 'stop ${stop.angle} missing or out of order',
        );
        cursor = at;
      }
    });

    test('and the peak is the brightest stop in the string', () {
      final css = surfaceEdgeRimSweepCss(
        profile,
        width: 200,
        height: 60,
        radius: 12,
      );

      expect(css, contains('/ 90.0%)'));
      expect(css, isNot(contains('/ 100.0%)')));
    });

    test('a profile with no rim is none, never an empty gradient', () {
      expect(
        surfaceEdgeRimSweepCss(
          profile.copyWith(rimWidth: 0),
          width: 200,
          height: 60,
          radius: 12,
        ),
        'none',
      );
    });
  });
}
