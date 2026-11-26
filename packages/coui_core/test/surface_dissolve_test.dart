// How a glass surface's material gives way while the surface fades — the
// curve of the backdrop terms against the progress, and which terms follow it.
//
// An opacity cannot fade a backdrop pass (the filter reads only what was
// painted into the layer the opacity saved), so the surface fades its own
// terms instead. What Core owns is the statement of how: that nothing is
// drawn at nothing, that the stated material is drawn exactly at rest, that
// the material is continuous in between and is nearly gone by the time the
// fill is — the property a pass that waited for the alpha to reach zero would
// fail — and which of a material's terms ride the curve.
//
// The numbers a surface is checked against are the shared table
// (`surface_dissolve_vectors.json`): the Flutter test replays the same cases
// through the shipped surface, and a row that is wrong fails both.

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String _kVectorsPath = 'test/fixtures/surface_dissolve_vectors.json';

Map<String, Object?> _vectors() =>
    jsonDecode(File(_kVectorsPath).readAsStringSync()) as Map<String, Object?>;

double _num(Object? value) => (value! as num).toDouble();

/// The smallest progress at which an 8-bit opacity layer still paints
/// anything: one level of 255. Below it the fill is gone, so the material has
/// to be gone with it.
const double _kLastVisibleProgress = 1 / 255;

void main() {
  group('the table states the curve the surface ships', () {
    test('at the exponent the constant carries', () {
      expect(
        _num(_vectors()['exponent']),
        CoreSurfaceDissolve.materialExponent,
        reason:
            'the exponent is a designer-judgement value; changing it moves '
            'every row, so the table has to be restated with it',
      );
    });

    test("share is the table's share at each progress", () {
      final rows = (_vectors()['share']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(
          CoreSurfaceDissolve.share(_num(row['progress'])),
          closeTo(_num(row['share']), 1e-12),
          reason: 'progress ${row['progress']}',
        );
      }
    });
  });

  group('the curve', () {
    test(
      'draws nothing at nothing and exactly the stated material at rest',
      () {
        expect(CoreSurfaceDissolve.share(0), 0);
        expect(CoreSurfaceDissolve.share(1), 1);
        // Outside the range it holds the end it is nearest to: a spring that
        // overshoots must not draw more than the material states.
        expect(CoreSurfaceDissolve.share(-0.2), 0);
        expect(CoreSurfaceDissolve.share(1.4), 1);
      },
    );

    test('is continuous and increasing between the two', () {
      var previous = CoreSurfaceDissolve.share(0);
      for (var i = 1; i <= 1000; i++) {
        final share = CoreSurfaceDissolve.share(i / 1000);
        expect(share, greaterThan(previous), reason: 'progress ${i / 1000}');
        // No step of a thousandth of the progress moves the material by more
        // than a few percent of it: it dissolves rather than jumps.
        expect(
          share - previous,
          lessThan(0.05),
          reason: 'progress ${i / 1000}',
        );
        previous = share;
      }
    });

    test('has given the material up by the time the fill is gone', () {
      // A pass that stayed fully blurred until the alpha reached zero would
      // pop from blurred to sharp in the last frame. The last progress at
      // which the fill still paints a single level is one level of 255; the
      // material at that progress must already be a sliver of itself.
      expect(
        CoreSurfaceDissolve.share(_kLastVisibleProgress),
        lessThan(0.01),
        reason:
            'a material that keeps a hundredth of itself when the fill is '
            'one level from gone pops in the next frame',
      );
    });

    test('returns its input itself at rest', () {
      // Identity, not merely equal: a surface at rest must compare equal to
      // the surface that states the value, so nothing downstream rebuilds a
      // filter for a value that did not move.
      const blur = 4.0;
      expect(identical(CoreSurfaceDissolve.scaled(blur, 1), blur), isTrue);
      expect(CoreSurfaceDissolve.scaled(blur, 1), blur);
      expect(CoreSurfaceDissolve.towardIdentity(1.6, 1), 1.6);
      expect(CoreSurfaceDissolve.scaled(blur, 1.5), blur);
    });
  });

  group('the terms of a glass material', () {
    final stated =
        (_vectors()['material']! as Map<String, Object?>)['stated']!
            as Map<String, Object?>;
    final cases =
        ((_vectors()['material']! as Map<String, Object?>)['cases']!
                as List<Object?>)
            .cast<Map<String, Object?>>();

    final frost = stated['frost']! as Map<String, Object?>;
    final refraction = stated['refraction']! as Map<String, Object?>;
    final request = CoreSurfaceRefraction(
      bezel: _num(refraction['bezel']),
      strength: _num(refraction['strength']),
      refractiveIndex: _num(refraction['refractiveIndex']),
      dispersion: _num(refraction['dispersion']),
      lens: _num(refraction['lens']),
      fallbackBlurAdd: 4,
      model: CoreRefractionModel.paraxial,
    );
    final cloud = CoreSurfaceFrost(
      sigma: _num(frost['sigma']),
      opacity: _num(frost['opacity']),
      opacityInDarkMode: 0.5,
    );
    final shade = CoreSurfaceBodyShade(
      strength: _num(stated['bodyShade']),
      strengthInDarkMode: 0.4,
    );

    final pass = CoreSurfaceBackdropPass(
      blur: _num(stated['blur']),
      saturation: _num(stated['saturation']),
      brightness: _num(stated['brightness']),
      frost: cloud,
      refraction: request,
      bodyShade: _num(stated['bodyShade']),
    );

    test('each ride the curve to the number the table states', () {
      for (final row in cases) {
        final progress = _num(row['progress']);
        final reason = 'progress $progress';
        final drawn = pass.dissolvedAt(progress);

        expect(drawn.blur, closeTo(_num(row['blur']), 1e-12), reason: reason);
        expect(
          drawn.saturation,
          closeTo(_num(row['saturation']), 1e-12),
          reason: 'chroma lift at $reason',
        );
        expect(
          drawn.brightness,
          closeTo(_num(row['brightness']), 1e-12),
          reason: 'dimming at $reason',
        );

        final frostOpacity = row['frostOpacity'];
        if (frostOpacity == null) {
          expect(drawn.frost, isNull, reason: 'frost at $reason');
        } else {
          expect(
            drawn.frost!.opacity,
            closeTo(_num(frostOpacity), 1e-12),
            reason: 'frost share at $reason',
          );
          expect(drawn.frost!.sigma, cloud.sigma, reason: 'cloud sigma');
        }

        expect(
          drawn.refraction!.strength,
          closeTo(_num(row['strength']), 1e-12),
          reason: 'bend strength at $reason',
        );
        expect(
          drawn.refraction!.lens,
          closeTo(_num(row['lens']), 1e-12),
          reason: 'lens at $reason',
        );
        expect(
          drawn.bodyShade,
          closeTo(_num(row['bodyShade']), 1e-12),
          reason: 'body shade at $reason',
        );
      }
    });

    test('a pass states only the terms it has, at every progress', () {
      const bare = CoreSurfaceBackdropPass(blur: 4);
      for (final progress in [0.0, 0.25, 0.5, 0.99]) {
        final drawn = bare.dissolvedAt(progress);
        expect(drawn.saturation, isNull, reason: 'progress $progress');
        expect(drawn.brightness, isNull, reason: 'progress $progress');
        expect(drawn.frost, isNull, reason: 'progress $progress');
        expect(drawn.refraction, isNull, reason: 'progress $progress');
        expect(drawn.bodyShade, 0, reason: 'progress $progress');
      }
    });

    test('the dissolved pass is a value, equal to the same pass', () {
      expect(pass.dissolvedAt(0.5), pass.dissolvedAt(0.5));
      expect(pass.dissolvedAt(0.5).hashCode, pass.dissolvedAt(0.5).hashCode);
      expect(pass.dissolvedAt(0.5), isNot(pass.dissolvedAt(0.6)));
    });

    test('nothing in the pass is left at the progress where nothing is', () {
      final gone = pass.dissolvedAt(0);
      expect(gone.blur, 0);
      expect(gone.bodyShade, 0);
      expect(gone.frost, isNull);
      expect(gone.refraction!.strength, 0);
      expect(gone.refraction!.lens, 0);
      expect(gone.saturation, 1);
      expect(gone.brightness, 1);
    });

    test('the bend keeps where and at what angle, and loses only how far', () {
      final half = request.dissolvedAt(0.5);
      expect(half.bezel, request.bezel);
      expect(half.refractiveIndex, request.refractiveIndex);
      expect(half.model, request.model);
      expect(half.dispersion, request.dispersion);
      expect(half.fallbackBlurAdd, request.fallbackBlurAdd);
      expect(half.strength, lessThan(request.strength));
      expect(half.lens, lessThan(request.lens));
    });

    test('the lens goes with the rim, not after it', () {
      // The dome is independent of the band: a request that dissolved only
      // its strength would still pull every sample of the face toward the
      // centre by the whole lens at a progress of one in a hundred.
      final nearly = request.dissolvedAt(0.01);
      expect(nearly.lens, lessThan(request.lens * 0.05));
      expect(nearly.strength, lessThan(request.strength * 0.05));
    });

    test('the dark statements dissolve with the light ones', () {
      expect(
        cloud.dissolvedAt(0.5)!.opacityInDarkMode,
        closeTo(0.25, 1e-12),
      );
      expect(shade.dissolvedAt(0.5).strengthInDarkMode, closeTo(0.2, 1e-12));
      expect(
        shade.dissolvedAt(0.5).strengthFor(CoreBrightness.dark),
        closeTo(0.2, 1e-12),
      );
    });

    test('a surface at rest is handed back the very value it stated', () {
      expect(identical(request.dissolvedAt(1), request), isTrue);
      expect(identical(cloud.dissolvedAt(1), cloud), isTrue);
      expect(identical(shade.dissolvedAt(1), shade), isTrue);
      expect(identical(pass.dissolvedAt(1), pass), isTrue);
    });
  });
}
