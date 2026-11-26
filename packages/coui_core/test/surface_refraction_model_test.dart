// The rim band bends light by one of two laws. Both read the same band, dial
// and index, and the choice moves the shape of the bend — so the table both
// platforms read, an independent computation of each law, is what pins them.

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String _kVectorsPath = 'test/fixtures/refraction_model_vectors.json';

Map<String, Object?> _vectors() =>
    jsonDecode(File(_kVectorsPath).readAsStringSync()) as Map<String, Object?>;

CoreRefractionModel _model(String name) =>
    CoreRefractionModel.values.byName(name);

double _num(Object? value) => (value! as num).toDouble();

List<Map<String, Object?>> _travelCases() =>
    ((_vectors()['travel']! as Map<String, Object?>)['cases']! as List<Object?>)
        .cast<Map<String, Object?>>();

CoreSurfaceRefraction _request({
  required double strength,
  required double index,
  CoreRefractionModel model = CoreRefractionModel.snell,
  double bezel = 0.27,
}) => CoreSurfaceRefraction(
  bezel: bezel,
  strength: strength,
  refractiveIndex: index,
  model: model,
);

void main() {
  group('each law gives the travel the shared table states', () {
    test('at every inset of every case', () {
      final cases = _travelCases();
      // A table that lost its rows would pass every loop below.
      expect(cases.length, greaterThanOrEqualTo(10));

      for (final each in cases) {
        final request = _request(
          strength: _num(each['strength']),
          index: _num(each['refractiveIndex']),
          model: _model(each['model']! as String),
        );
        final band = _num(each['bandPx']);

        for (final row
            in (each['rows']! as List<Object?>).cast<Map<String, Object?>>()) {
          expect(
            request.displacementAt(
              insetPx: _num(row['insetPx']),
              bandPx: band,
            ),
            closeTo(_num(row['travelPx']), 1e-9),
            reason:
                '${each['name']} / ${each['model']} at ${row['insetPx']} px',
          );
        }
      }
    });

    test("and the peak over the band is the rim's travel", () {
      for (final each in _travelCases()) {
        final request = _request(
          strength: _num(each['strength']),
          index: _num(each['refractiveIndex']),
          model: _model(each['model']! as String),
        );

        expect(
          request.peakDisplacement(bandPx: _num(each['bandPx'])),
          closeTo(_num(each['peakPx']), 1e-9),
          reason: '${each['name']} / ${each['model']}',
        );
      }
    });
  });

  group('the laws differ where they are meant to', () {
    test('a request that states no law is the law the band was drawn with', () {
      const stated = CoreSurfaceRefraction(
        bezel: 0.27,
        strength: 0.8,
      );

      expect(stated.model, CoreRefractionModel.snell);
      expect(
        stated.displacementAt(insetPx: 3, bandPx: 15),
        stated
            .copyWith(model: CoreRefractionModel.snell)
            .displacementAt(insetPx: 3, bandPx: 15),
      );
    });

    test('the shipped glass states the default law', () {
      expect(
        CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass).refraction!.model,
        CoreRefractionModel.snell,
        reason: "a look decision is the app's to opt into",
      );
    });

    test('paraxial bends nothing at an index of one, snell does', () {
      final paraxial = _request(
        strength: 1,
        index: 1,
        model: CoreRefractionModel.paraxial,
      );
      final snell = _request(strength: 1, index: 1);

      for (var inset = 0.0; inset <= 48; inset += 4) {
        expect(
          paraxial.displacementAt(insetPx: inset, bandPx: 48),
          0,
          reason: 'inset $inset',
        );
      }
      // The table records this rather than hiding it: the snell law has
      // always moved the sample at index 1, and is left as it is.
      expect(snell.displacementAt(insetPx: 0, bandPx: 48), lessThan(0));
    });

    test('both pull inward, are strongest at the rim and end at the band', () {
      for (final model in CoreRefractionModel.values) {
        final request = _request(strength: 1, index: 1.5, model: model);
        var previous = double.infinity;
        for (var step = 0; step <= 32; step++) {
          final at = request.displacementAt(
            insetPx: 48 * step / 32,
            bandPx: 48,
          );
          expect(at, lessThanOrEqualTo(0), reason: '$model must pull inward');
          expect(
            at.abs(),
            lessThanOrEqualTo(previous),
            reason: '$model must not grow from the rim inward',
          );
          previous = at.abs();
        }
        expect(request.displacementAt(insetPx: 48, bandPx: 48), 0);
        expect(request.displacementAt(insetPx: 96, bandPx: 48), 0);
        expect(request.displacementAt(insetPx: 4, bandPx: 0), 0);
      }
    });

    test('paraxial is a parabola in the inset', () {
      // Quarter, half and three quarters of the way in: 1 - h², scaled.
      final request = _request(
        strength: 1,
        index: 1.5,
        model: CoreRefractionModel.paraxial,
      );
      final rim = request.displacementAt(insetPx: 0, bandPx: 48);

      expect(
        request.displacementAt(insetPx: 12, bandPx: 48),
        closeTo(rim * (1 - 0.25 * 0.25), 1e-12),
      );
      expect(
        request.displacementAt(insetPx: 24, bandPx: 48),
        closeTo(rim * 0.75, 1e-12),
      );
      expect(
        request.displacementAt(insetPx: 36, bandPx: 48),
        closeTo(rim * (1 - 0.75 * 0.75), 1e-12),
      );
    });

    test('and the dome across the face does not follow the law', () {
      const snell = CoreSurfaceRefraction(bezel: 0.27, lens: 0.08);
      final paraxial = snell.copyWith(model: CoreRefractionModel.paraxial);

      for (final from in [-120.0, -30.0, 0.0, 30.0, 120.0]) {
        expect(
          paraxial.lensDisplacement(from),
          snell.lensDisplacement(from),
        );
      }
      expect(
        paraxial.lensPeak(cornerPx: 250),
        snell.lensPeak(cornerPx: 250),
      );
    });
  });

  group('the displacement map the Web filter reads', () {
    final map = _vectors()['map']! as Map<String, Object?>;

    List<int> redAlongMiddleRow(CoreRefractionModel model) {
      final width = (map['width']! as num).toInt();
      final height = (map['height']! as num).toInt();
      final pixels = surfaceRefractionDisplacementMap(
        width: width,
        height: height,
        radius: _num(map['radius']),
        refraction: CoreSurfaceRefraction(
          bezel: _num(map['bezel']),
          strength: _num(map['strength']),
          refractiveIndex: _num(map['refractiveIndex']),
          model: model,
        ),
      );
      final row = (map['row']! as num).toInt();

      return [
        for (var x = 0; x < 24; x++) pixels[((row * width) + x) * 4],
      ];
    }

    test('is the one the shared table states, under both laws', () {
      for (final each
          in (map['cases']! as List<Object?>).cast<Map<String, Object?>>()) {
        final model = _model(each['model']! as String);
        final expected = (each['redAlongMiddleRow']! as List<Object?>)
            .cast<num>()
            .map((value) => value.toInt())
            .toList();
        final got = redAlongMiddleRow(model);

        for (var x = 0; x < expected.length; x++) {
          expect(
            got[x],
            closeTo(expected[x], 1),
            reason: '${model.name} at x=$x',
          );
        }
      }
    });

    test('differs between the laws, and stays neutral past the band', () {
      final snell = redAlongMiddleRow(CoreRefractionModel.snell);
      final paraxial = redAlongMiddleRow(CoreRefractionModel.paraxial);

      expect(paraxial, isNot(snell));
      // The band is 16 px: the interior pixel reads 'do not move' under
      // either law, or the flat middle of the panel would slide.
      expect(snell.last, 128);
      expect(paraxial.last, 128);
    });
  });

  group('the model is a value the axis can carry', () {
    test('it takes part in equality, hashing, copying and serialising', () {
      const snell = CoreSurfaceRefraction(bezel: 0.27);
      final paraxial = snell.copyWith(model: CoreRefractionModel.paraxial);

      expect(paraxial, isNot(snell));
      expect(paraxial.hashCode, isNot(snell.hashCode));
      expect(paraxial.copyWith(model: CoreRefractionModel.snell), snell);
      expect(paraxial.copyWith(), paraxial);
    });

    test('a request that states the default serialises as it always did', () {
      const snell = CoreSurfaceRefraction(bezel: 0.27);

      expect(snell.toJson().containsKey('model'), isFalse);
      expect(
        snell.copyWith(model: CoreRefractionModel.paraxial).toJson()['model'],
        'paraxial',
      );
    });

    test('the panel constructor passes it through', () {
      const viaPanel = CoreSurfaceRefraction.figma(
        refraction: 80,
        depth: 27,
        model: CoreRefractionModel.paraxial,
      );

      expect(viaPanel.model, CoreRefractionModel.paraxial);
    });

    test(
      'the displacement map is cached under the law, not under the dial',
      () {
        const snell = CoreSurfaceRefraction(bezel: 0.27);
        final paraxial = snell.copyWith(model: CoreRefractionModel.paraxial);

        String key(CoreSurfaceRefraction request) => refractionMapKey(
          width: 240,
          height: 140,
          radius: 16,
          refraction: request,
        );

        expect(key(paraxial), isNot(key(snell)));
        expect(key(snell), key(snell.copyWith(dispersion: 0.4)));
      },
    );

    test('the declaration order is the order the shader is told', () {
      // The Flutter seat encodes the law as a number for the fragment
      // program, and GLSL reads 0 as the default. A member inserted before
      // `snell` would renumber it.
      expect(CoreRefractionModel.snell.index, 0);
      expect(CoreRefractionModel.paraxial.index, 1);
    });
  });
}
