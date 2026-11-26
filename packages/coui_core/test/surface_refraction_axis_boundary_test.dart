@TestOn('vm')
library;

import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// Where refraction may and may not be stated.
///
/// This file used to keep refraction off the axis entirely, on the argument
/// that an axis slot would force each surface to measure itself. That
/// argument was overturned by measurement, and the record of why is the
/// point of this comment:
///
/// * The surfaces **already** measure themselves. The Web runtime reads
///   `getBoundingClientRect` and rebuilds on a `ResizeObserver`, keyed by
///   geometry; Flutter derives its displacement from the same rectangle.
///   Putting the request on the axis moved none of that work — it was
///   already there for the caller-stated path.
/// * What travels is the *request*, not the map: a bezel fraction and a
///   fallback blur, two size-independent scalars exactly like the blur
///   radius beside them.
/// * The cost of the boundary was measured and it was total. Nothing in
///   the kit passed `refraction` to anything, on either platform, so the
///   shipped glass preset had translucency, blur, chroma and an edge band
///   and **zero refraction** — the dominant term of the material it is
///   named after, implemented on both platforms and switched on nowhere.
///
/// What the boundary still protects, and what this file now pins, is the
/// half that was always the real point: **components do not read it.** The
/// recipe states it and the surface primitive consumes it; a component
/// naming `CoreSurfaceRefraction` is a component growing its own material,
/// which is the thing "components do not read the axis" exists to prevent.
/// Where the repo already says what a theme-level axis carrier is.
const _kGuardPath =
    '../../scripts/guards/structure/check_axis_field_consumed.sh';

/// The carriers, read off the guard rather than restated here.
///
/// A hand-kept copy of this list was the first version, and it named four of
/// the ten. A refraction slot added to any of the other six — most plausibly
/// the *geometry* constraint, since refraction is geometry — passed it
/// without a word. The list was not wrong when written; it went stale the
/// moment the guard grew, and nothing said so.
List<String> _axisCarrierPaths() {
  final guard = File(_kGuardPath).readAsStringSync();
  final block = RegExp(
    r'CARRIERS=\((.*?)\n\)',
    dotAll: true,
  ).firstMatch(guard);

  return [
    for (final line in RegExp(
      '"([^"]+)"',
    ).allMatches(block?.group(1) ?? '').map((m) => m.group(1)!))
      if (line.startsWith('packages/coui_core/'))
        line.substring('packages/coui_core/'.length),
  ];
}

void main() {
  group('refraction is stated once, and not by a component', () {
    test('the carrier list was actually derived', () {
      // Without this the loop below is the very defect it is written to
      // catch: a parser that matched nothing would iterate zero carriers and
      // report a clean bill of health for a file it never opened.
      final carriers = _axisCarrierPaths();

      expect(carriers, isNotEmpty);
      expect(
        carriers,
        containsAll([
          'lib/src/surface/surface_token.dart',
          'lib/src/surface/surface_recipe.dart',
          'lib/src/surface/surface_tuning.dart',
          'lib/src/surface/surface_geometry_constraint.dart',
          'lib/src/theme/core_theme_data.dart',
        ]),
        reason:
            'the guard still declares these; a parse that lost them is '
            'broken rather than the guard having shrunk',
      );
      for (final path in carriers) {
        expect(File(path).existsSync(), isTrue, reason: '$path is not there');
      }
    });

    test('the recipe states it, and only the recipe', () {
      // Read from source rather than from the type, because the failure
      // this catches is a *field being added* — and a test written against
      // the fields that exist today cannot see one that does not yet.
      //
      // One carrier holds it: the recipe, which is what one style *is*.
      // The others describe how a style bends the palette, the geometry or
      // the type, and a slot on any of them would be a second place to say
      // the same thing.
      const stating = 'lib/src/surface/surface_recipe.dart';
      var found = 0;
      for (final path in _axisCarrierPaths()) {
        final source = File(path).readAsStringSync();
        final holds = source.contains('CoreSurfaceRefraction');
        if (path == stating) {
          found++;
          expect(holds, isTrue, reason: 'the recipe stopped stating it');
          continue;
        }
        expect(
          holds,
          isFalse,
          reason:
              '$path is a theme-level carrier and not the one that states '
              'this. Two places to say it is two places to disagree.',
        );
      }

      expect(found, 1, reason: 'the stating carrier was never visited');
    });

    test('and the shipped glass preset actually asks for it', () {
      // The assertion that fails if the wiring is declared but inert —
      // which is the state this file was rewritten out of. Every other
      // test here passes with a field that no preset fills.
      expect(
        CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass).refraction,
        isNotNull,
        reason: 'glass without refraction is a blurred pane',
      );
      for (final id in CoreSurfaceStyleId.values) {
        if (id == CoreSurfaceStyleId.liquidGlass) continue;

        expect(
          CoreSurfaceRecipe.of(id).refraction,
          isNull,
          reason: '$id started bending its backdrop',
        );
      }
    });
  });

  group('the request compares by value', () {
    test('every field is in the comparison', () {
      // Sharper than the usual reason. On the Web side this value keys a
      // cache of generated displacement maps: a field outside `==` makes
      // two different requests look the same, the cache answers with the
      // map it already had, and the surface bends by the wrong amount with
      // nothing in the output to say why.
      const base = CoreSurfaceRefraction(bezel: 0.2);

      for (final other in const [
        CoreSurfaceRefraction(bezel: 0.3),
        CoreSurfaceRefraction(bezel: 0.2, fallbackBlurAdd: 4),
      ]) {
        expect(base, isNot(other));
        expect(base.hashCode, isNot(other.hashCode));
      }
    });

    test('and two equal requests built apart compare equal', () {
      const one = CoreSurfaceRefraction(bezel: 0.2, fallbackBlurAdd: 4);
      const other = CoreSurfaceRefraction(bezel: 0.2, fallbackBlurAdd: 4);

      expect(one, other);
      expect(one.hashCode, other.hashCode);
    });

    test('copyWith and toJson carry every field', () {
      // Every field, checked by name rather than by count. A knob added to
      // the optics and left out of one of these is the failure that reads
      // as "the two platforms disagree": the Web map's cache key is built
      // from these values, so one missing makes two different requests
      // look identical and the cache answers with the wrong map.
      const base = CoreSurfaceRefraction(
        bezel: 0.2,
        strength: 0.5,
        refractiveIndex: 1.4,
        dispersion: 0.2,
        lens: 0.08,
        fallbackBlurAdd: 4,
      );

      final moved = base.copyWith(bezel: 0.3);
      expect(moved.bezel, 0.3);
      expect(moved.strength, 0.5);
      expect(moved.refractiveIndex, 1.4);
      expect(moved.dispersion, 0.2);
      expect(moved.lens, 0.08);
      expect(moved.fallbackBlurAdd, 4);

      expect(base.toJson(), {
        'bezel': 0.2,
        'strength': 0.5,
        'refractiveIndex': 1.4,
        'dispersion': 0.2,
        'lens': 0.08,
        'fallbackBlurAdd': 4.0,
      });
    });
  });

  group('a request that cannot mean anything does not build', () {
    test('a bezel with no band in it', () {
      expect(
        () => CoreSurfaceRefraction(bezel: double.parse('0')),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a bezel past the point where the two sides meet', () {
      expect(
        () => CoreSurfaceRefraction(bezel: double.parse('0.6')),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a correction that subtracts', () {
      expect(
        () => CoreSurfaceRefraction(
          bezel: 0.2,
          fallbackBlurAdd: double.parse('-1'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
