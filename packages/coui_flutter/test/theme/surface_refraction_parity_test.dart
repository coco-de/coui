// The two renderers draw the same bend, or this fails.
//
// They did not, for the whole time refraction existed. Each platform owned
// its own copy of the optics and they disagreed on every term that decides
// what the rim looks like:
//
//   direction  Flutter sampled inward, Web outward — one magnified the rim,
//              the other compressed it. Opposite pictures from one recipe.
//   magnitude  Flutter scaled the travel with the band; Web used a constant.
//              Widening the band moved one platform and left the other.
//   geometry   Flutter used a per-axis box distance with no corners at all;
//              Web used the rounded-rect field. They disagreed most exactly
//              where a rounded pane is most obviously round.
//
// Nothing caught it because neither suite had anything to compare against:
// each asserted its own arithmetic against itself. So the arithmetic now
// lives in one place (`CoreSurfaceRefraction.displacementAt`), the Web map
// calls it, and the shader spells it out in GLSL because it runs on a GPU
// and cannot call Dart.
//
// This file is the net under that last sentence. It re-implements the
// shader's `displacementAt` from the GLSL source *as read*, and compares it
// to Core's across the band. A change to one and not the other fails here
// rather than on someone's screen.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shader source, so the test is anchored to the file that ships.
String _shaderSource() {
  final file = File('shaders/surface_refraction.frag');
  expect(file.existsSync(), isTrue, reason: 'the shader is gone');

  return file.readAsStringSync();
}

/// The body of a GLSL function, with whitespace flattened.
///
/// Text, because there is nothing here that can run the shader: a widget
/// test has no GPU and `ImageFilter.shader` is a hard throw on this
/// platform. What can be checked is that the file still says what the
/// transcription below claims it says.
String _functionBody(String source, String name) {
  var at = source.indexOf('float $name(');
  if (at < 0) at = source.indexOf('vec2 $name(');
  if (at < 0) at = source.indexOf('vec4 $name(');
  if (at < 0) at = source.indexOf('void $name(');
  expect(at, greaterThan(-1), reason: '$name is gone from the shader');

  final open = source.indexOf('{', at);
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') {
      depth--;
      if (depth == 0) {
        return source
            .substring(open + 1, i)
            .split('\n')
            .map((line) => line.split('//').first.trim())
            .where((line) => line.isNotEmpty)
            .join(' ')
            .replaceAll(RegExp(r'\s+'), ' ');
      }
    }
  }

  fail('$name has no closing brace');
}

/// The shader's `displacementAt`, transcribed from the GLSL.
///
/// Transcribed rather than parsed on purpose: a parser would agree with
/// whatever the file says, which is exactly the thing under test. Someone
/// editing the shader has to edit this too, and that is the point — the
/// duplication is the risk, so it is made visible instead of hidden.
///
/// A first version stopped here, and it was worthless: flipping the sign in
/// the shader left every assertion green, because nothing in the test ever
/// read the file. The textual pin below is what makes this transcription
/// mean anything.
/// The shader's `lensTravel`, transcribed from the GLSL — one axis of it,
/// since the GLSL applies the same line to both.
double _shaderLens({required double centred, required double lens}) =>
    -lens * centred;

double _shaderDisplacement({
  required double insetPx,
  required double bandPx,
  required double strength,
  required double refractiveIndex,
}) {
  if (bandPx <= 0) return 0;

  final h = (insetPx / bandPx).clamp(0.0, 1.0);
  final bulge = math.sqrt(math.max(0, 1 - (h * h)));
  final normalLength = math.sqrt((bulge * bulge) + (h * h));
  if (normalLength == 0) return 0;

  final nx = bulge / normalLength;
  final nz = h / normalLength;

  final eta = 1.0 / math.max(refractiveIndex, 1.0);
  final k = 1 - (eta * eta * (1 - (nz * nz)));
  if (k < 0) return 0;

  final tangential = -eta * nx;
  final zone = 1 - (insetPx / bandPx).clamp(0.0, 1.0);

  return tangential * bandPx * strength * 5.0 * zone;
}

/// The shader's `paraxialDisplacementAt`, transcribed from the GLSL.
///
/// Transcribed for the reason [_shaderDisplacement] is, and pinned to the
/// file by the textual test below for the same one.
double _shaderParaxial({
  required double insetPx,
  required double bandPx,
  required double strength,
  required double refractiveIndex,
}) {
  if (bandPx <= 0) return 0;

  final h = (insetPx / bandPx).clamp(0.0, 1.0);
  final slope = 1.0 - h * h;
  final deviation = math.max(refractiveIndex, 1) - 1.0;

  return -deviation * slope * bandPx * strength * 5.0;
}

/// The shader's `rimDisplacement`: the law the uniform names.
double _shaderRim({
  required double model,
  required double insetPx,
  required double bandPx,
  required double strength,
  required double refractiveIndex,
}) => model > 0.5
    ? _shaderParaxial(
        insetPx: insetPx,
        bandPx: bandPx,
        strength: strength,
        refractiveIndex: refractiveIndex,
      )
    : _shaderDisplacement(
        insetPx: insetPx,
        bandPx: bandPx,
        strength: strength,
        refractiveIndex: refractiveIndex,
      );

/// The table Core, the Flutter shader and the Web map all read.
List<Map<String, Object?>> _vectorCases() {
  final file = File('../coui_core/test/fixtures/refraction_model_vectors.json');
  expect(file.existsSync(), isTrue, reason: 'the shared table is gone');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

  return ((decoded['travel']! as Map<String, Object?>)['cases']!
          as List<Object?>)
      .cast<Map<String, Object?>>();
}

void main() {
  group('the two renderers compute the same displacement', () {
    const band = 48.0;

    test('across the whole band, for every shipped knob combination', () {
      // Swept rather than spot-checked. A single sample would pass on two
      // curves that cross once, and the falloff is the term the two
      // implementations disagreed about most.
      for (final strength in const [0.25, 0.5, 1.0]) {
        for (final index in const [1.0, 1.5, 2.0]) {
          final request = CoreSurfaceRefraction(
            bezel: 0.32,
            strength: strength,
            refractiveIndex: index,
          );

          for (var step = 0; step <= 64; step++) {
            final inset = band * step / 64;

            expect(
              request.displacementAt(insetPx: inset, bandPx: band),
              closeTo(
                _shaderDisplacement(
                  insetPx: inset,
                  bandPx: band,
                  strength: strength,
                  refractiveIndex: index,
                ),
                1e-9,
              ),
              reason:
                  'inset $inset, strength $strength, index $index — the '
                  'shader and Core disagree',
            );
          }
        }
      }
    });

    test('and they pull the same way', () {
      // The failure that reads as two different materials rather than as a
      // tuning difference: one platform magnifying the rim while the other
      // compresses it. Sign, not magnitude.
      const request = CoreSurfaceRefraction(bezel: 0.32);

      expect(
        request.displacementAt(insetPx: 0, bandPx: band),
        lessThan(0),
        reason: 'the bend must pull inward, along the negative outward normal',
      );
    });

    test('and the interior is left flat', () {
      // Both ends, because a model that bends everywhere is a smear and one
      // that bends nowhere is a plain blur — and the band's inner boundary
      // is where the difference is decided.
      const request = CoreSurfaceRefraction(bezel: 0.32);

      expect(request.displacementAt(insetPx: band, bandPx: band), 0);
      expect(request.displacementAt(insetPx: band * 2, bandPx: band), 0);
      expect(
        request.displacementAt(insetPx: 0, bandPx: band).abs(),
        greaterThan(0),
      );
    });
  });

  group('the two renderers compute the same lens', () {
    test('per axis, toward the centre, by the stated fraction', () {
      // The transcription of `lensTravel` is one line; what is worth
      // sweeping is that Core and the shader agree on sign and unit across
      // the face, for the shipped value and for none.
      for (final lens in const [0.0, 0.04, 0.08, 0.2]) {
        final request = CoreSurfaceRefraction(bezel: 0.27, lens: lens);
        for (final centred in const [-150.0, -30.0, 0.0, 30.0, 150.0]) {
          expect(
            request.lensDisplacement(centred),
            closeTo(_shaderLens(centred: centred, lens: lens), 1e-9),
          );
        }
      }
    });

    test('and no lens leaves every read where it started', () {
      const request = CoreSurfaceRefraction(bezel: 0.27);

      expect(request.lensDisplacement(150), 0);
      expect(request.lensPeak(cornerPx: 200), 0);
    });
  });

  group('the two renderers compute the same paraxial displacement', () {
    test('every row of the shared table, through the shader and Core', () {
      final cases = _vectorCases();
      expect(cases.length, greaterThanOrEqualTo(10));

      for (final each in cases) {
        final model = CoreRefractionModel.values.byName(
          each['model']! as String,
        );
        final strength = (each['strength']! as num).toDouble();
        final index = (each['refractiveIndex']! as num).toDouble();
        final band = (each['bandPx']! as num).toDouble();
        final request = CoreSurfaceRefraction(
          bezel: 0.27,
          strength: strength,
          refractiveIndex: index,
          model: model,
        );

        for (final row
            in (each['rows']! as List<Object?>).cast<Map<String, Object?>>()) {
          final inset = (row['insetPx']! as num).toDouble();
          final expected = (row['travelPx']! as num).toDouble();
          final reason = '${each['name']} / ${model.name} at $inset px';

          expect(
            _shaderRim(
              model: surfaceRefractionModelUniform(model),
              insetPx: inset,
              bandPx: band,
              strength: strength,
              refractiveIndex: index,
            ),
            closeTo(expected, 1e-9),
            reason: 'the shader: $reason',
          );
          expect(
            request.displacementAt(insetPx: inset, bandPx: band),
            closeTo(expected, 1e-9),
            reason: 'Core: $reason',
          );
        }
      }
    });

    test('the uniform names the law Core names, and only those', () {
      expect(surfaceRefractionModelUniform(CoreRefractionModel.snell), 0);
      expect(surfaceRefractionModelUniform(CoreRefractionModel.paraxial), 1);
      // The shader reads anything above one half as the second law, so the
      // encoding has to agree with the declaration order Core pins.
      for (final model in CoreRefractionModel.values) {
        expect(
          surfaceRefractionModelUniform(model),
          model.index.toDouble(),
        );
      }
    });
  });

  group('the shader still says what the transcription claims', () {
    test('its lensTravel is the expected arithmetic', () {
      expect(
        _functionBody(_shaderSource(), 'lensTravel'),
        'return -uLens * centred;',
      );
    });

    test('and the reads go rim first, lens second, like the Web filter', () {
      // The composition order is the parity claim: the Web filter's lens
      // stage runs on the source and its rim passes read from the lensed
      // result, so the shader evaluates the lens at the rim-shifted point.
      expect(
        _functionBody(_shaderSource(), 'readAt'),
        'vec2 lensed = shifted + lensTravel(shifted - uOrigin - half_); '
        'return clamp(lensed / uSize, 0.0, 1.0);',
      );
    });

    test('its displacementAt is the expected arithmetic, line for line', () {
      // The pin that makes the sweep above worth running. Without it the
      // sweep compares a hand-written Dart function to Core and never opens
      // the shader at all — measured: flipping the sign in the GLSL left
      // every assertion green.
      //
      // Exact text rather than a property, because the properties worth
      // checking are the ones a GPU would have to evaluate. Any edit here
      // fails until someone updates this string *and* the transcription
      // above together, which is the pairing this whole file exists to
      // force.
      expect(
        _functionBody(_shaderSource(), 'displacementAt'),
        'if (bandPx <= 0.0) return 0.0; '
        'float h = clamp(insetPx / bandPx, 0.0, 1.0); '
        'float bulge = sqrt(max(0.0, 1.0 - h * h)); '
        'float normalLength = sqrt(bulge * bulge + h * h); '
        'if (normalLength == 0.0) return 0.0; '
        'float nx = bulge / normalLength; '
        'float nz = h / normalLength; '
        'float eta = 1.0 / max(uRefractiveIndex, 1.0); '
        'float k = 1.0 - eta * eta * (1.0 - nz * nz); '
        'if (k < 0.0) return 0.0; '
        'float tangential = -eta * nx; '
        'float zone = 1.0 - clamp(insetPx / bandPx, 0.0, 1.0); '
        'return tangential * bandPx * uStrength * kTravelPerBand * zone;',
      );
    });
  });

  group("the shader's second law is the text the transcription reads", () {
    test('its paraxialDisplacementAt is the expected arithmetic', () {
      expect(
        _functionBody(_shaderSource(), 'paraxialDisplacementAt'),
        'if (bandPx <= 0.0) return 0.0; '
        'float h = clamp(insetPx / bandPx, 0.0, 1.0); '
        'float slope = 1.0 - h * h; '
        'float deviation = max(uRefractiveIndex, 1.0) - 1.0; '
        'return -deviation * slope * bandPx * uStrength * kTravelPerBand;',
      );
    });

    test('and the law is chosen by the uniform, snell on anything else', () {
      expect(
        _functionBody(_shaderSource(), 'rimDisplacement'),
        'return uRefractionModel > 0.5 '
        '? paraxialDisplacementAt(insetPx, bandPx) '
        ': displacementAt(insetPx, bandPx);',
      );
    });

    test('and the rim is bent by the chosen law, not by snell directly', () {
      // The failure this names: the dispatcher exists, the uniform is
      // written, and the one line that reads the rim's travel still calls
      // the first law — the whole feature declared and inert.
      final main = _functionBody(_shaderSource(), 'main');

      expect(main, contains('normal * rimDisplacement(inset, band)'));
      expect(main, isNot(contains('normal * displacementAt(')));
    });
  });

  group('the shader declares what the Dart side writes', () {
    test('the uniforms are in the order the caller sets them', () {
      // `setFloat` addresses uniforms by index, and nothing checks the
      // mapping — a pair swapped in either file compiles, runs, and bends
      // by an index it read as a radius. This pins the sequence to the one
      // `_materialFilter` writes.
      final source = _shaderSource();
      final declared = RegExp(
        r'uniform\s+(?:vec2|float)\s+(\w+)\s*;',
      ).allMatches(source).map((m) => m.group(1)).toList();

      expect(declared, [
        'uSize',
        'uBezel',
        'uRadius',
        'uStrength',
        'uRefractiveIndex',
        'uDispersion',
        'uOrigin',
        'uExtent',
        'uLens',
        'uRefractionModel',
        'uBodyShade',
      ]);
      // And the indices the render object writes: a vec2 counts as two
      // floats, so the two rectangle uniforms sit at 7–8 and 9–10, the
      // lens — declared after them so those did not move — at 11, and the
      // law at 12 and the body shade, declared last so none of those moved,
      // at 13.
      expect(kSurfaceRefractionOriginIndex, 7);
      expect(kSurfaceRefractionExtentIndex, 9);
      expect(kSurfaceRefractionLensIndex, 11);
      expect(kSurfaceRefractionModelIndex, 12);
      expect(kSurfaceBodyShadeIndex, 13);
    });

    test('and it still declares a sampler, which the engine requires', () {
      // `ImageFilter.shader` reads what the program *declares* and rejects
      // one with no sampler outright — the surface would then lose its
      // whole material rather than just the bend.
      expect(_shaderSource(), contains('uniform sampler2D'));
    });

    test('and the dispersion unit matches the one Core states', () {
      // The Web filter scales its channel passes by this; the shader used
      // to spread by the whole dispersion and fringed twice as far for the
      // same stated value — a divergence nothing measured until the two
      // constants were put in one place.
      expect(
        _shaderSource(),
        contains(
          'kDispersionUnit = '
          '${CoreSurfaceRefraction.dispersionUnit.toStringAsFixed(1)}',
        ),
      );
    });

    test('and the travel constant matches the one Core states', () {
      // The magnitude term. Core names it; the shader has to spell it out
      // as a literal because GLSL cannot read Dart, so the two can drift
      // apart silently by exactly the amount someone retunes.
      expect(
        _shaderSource(),
        contains(
          'kTravelPerBand = '
          '${CoreSurfaceRefraction.travelPerBand.toStringAsFixed(1)}',
        ),
      );
    });
  });

  group('the body shade is the one Core states', () {
    const vectorsPath =
        '../coui_core/test/fixtures/surface_finish_vectors.json';

    /// The shader's `bodyShaded`, transcribed from the GLSL on a
    /// premultiplied pixel — the same discipline as the transcription of
    /// `displacementAt` above: the duplication is the risk, so it is made
    /// visible.
    ({double r, double g, double b, double a}) shaded({
      required double strength,
      required double r,
      required double g,
      required double b,
      required double a,
    }) {
      if (strength <= 0 || a <= 0) return (r: r, g: g, b: b, a: a);
      final luma = (r / a) * 0.213 + (g / a) * 0.715 + (b / a) * 0.072;
      final factor = 1 - strength * luma * luma;

      return (r: r * factor, g: g * factor, b: b * factor, a: a);
    }

    test('the weights the shader spells are the ones Core names', () {
      final body = _functionBody(_shaderSource(), 'bodyShaded');

      expect(
        body,
        contains(
          'vec3(${CoreSurfaceBodyShade.lumaRed}, '
          '${CoreSurfaceBodyShade.lumaGreen}, '
          '${CoreSurfaceBodyShade.lumaBlue})',
        ),
      );
    });

    test('and the shader says the formula Core states', () {
      expect(
        _functionBody(_shaderSource(), 'bodyShaded'),
        'if (uBodyShade <= 0.0 || colour.a <= 0.0) return colour; '
        'vec3 straight = colour.rgb / colour.a; '
        'float luma = dot(straight, vec3(0.213, 0.715, 0.072)); '
        'return vec4(colour.rgb * (1.0 - uBodyShade * luma * luma), '
        'colour.a);',
      );
    });

    test('and the rim reads each sample through it', () {
      // The failure this names: the function exists, the uniform is written,
      // and the line that returns the colour still returns the raw sample —
      // the whole term declared and inert. Each sample, not the composite:
      // the Web filter shades the backdrop and then displaces it.
      final main = _functionBody(_shaderSource(), 'main');

      // The middle sample is the whole answer where nothing disperses, and
      // the dispersion replaces only the two outer channels, each taken from
      // its own shaded sample. `fragColor` is written once, from that colour.
      expect(
        main,
        contains('vec4 middle = bodyShaded(texture(uTexture, uv));'),
      );
      expect(main, contains('vec4 colour = middle;'));
      expect(main, contains('bodyShaded(texture(uTexture, red)).r'));
      expect(main, contains('bodyShaded(texture(uTexture, blue)).b'));
      expect(main, contains('fragColor = colour;'));
      expect(main, isNot(contains('fragColor = texture(')));
    });

    test('and main leaves through one exit', () {
      // The program samples a texture, and the shader compiler of Flutter
      // 3.50 warns when such a program has a `return` in `main()` besides the
      // last statement; a package that made the same change reports HLSL
      // compile failures for that shape on Windows Direct3D and Chrome ANGLE.
      // `check_shader_single_exit.sh` runs the compiler itself in CI; this is
      // the same fact beside the lines it constrains.
      expect(_functionBody(_shaderSource(), 'main'), isNot(contains('return')));
    });

    test('and the transcription agrees with the table on every case', () {
      final decoded =
          jsonDecode(File(vectorsPath).readAsStringSync())
              as Map<String, Object?>;
      final cases =
          ((decoded['bodyShade']! as Map<String, Object?>)['cases']!
                  as List<Object?>)
              .cast<Map<String, Object?>>();
      expect(cases.length, greaterThan(10));

      for (final each in cases) {
        final strength = (each['strength']! as num).toDouble();
        final rgb = (each['rgb']! as List<Object?>)
            .map((v) => (v! as num).toDouble() / 255)
            .toList();
        final want = (each['expected']! as List<Object?>)
            .map((v) => (v! as num).toInt())
            .toList();

        final got = shaded(
          strength: strength,
          r: rgb[0],
          g: rgb[1],
          b: rgb[2],
          a: 1,
        );
        final core = CoreSurfaceBodyShade.shade(
          strength: strength,
          red: rgb[0],
          green: rgb[1],
          blue: rgb[2],
        );

        // The shader and Core are the same arithmetic.
        expect(got.r, closeTo(core.red, 1e-12), reason: '${each['name']}');
        expect(got.g, closeTo(core.green, 1e-12), reason: '${each['name']}');
        expect(got.b, closeTo(core.blue, 1e-12), reason: '${each['name']}');
        // And both are the table, to the nearest level.
        expect((got.r * 255).round(), want[0], reason: '${each['name']}');
        expect((got.g * 255).round(), want[1], reason: '${each['name']}');
        expect((got.b * 255).round(), want[2], reason: '${each['name']}');
      }
    });

    test('and a translucent pixel is shaded by what it looks like', () {
      // Premultiplied in, premultiplied out: half-covered white is shaded
      // as white, and keeps its alpha.
      final got = shaded(strength: 0.5, r: 0.5, g: 0.5, b: 0.5, a: 0.5);

      expect(got.a, 0.5);
      expect(got.r, closeTo(0.5 * (1 - 0.5 * 1), 1e-12));
    });
  });
}
