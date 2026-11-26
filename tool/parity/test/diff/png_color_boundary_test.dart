import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/diff/pixel_diff.dart';
import '../../src/diff/png_color_space.dart';
import 'png_color_boundary_fixtures.dart';
import 'png_color_profile_fixtures.dart';

void main() {
  group('legacy unmanaged', () {
    for (final bits in [1, 2, 4]) {
      test('$bits-bit grayscale retains raw sample arithmetic', () {
        final black = samplePng(bits: bits, colorType: 0, channels: [0]);
        final white = samplePng(
          bits: bits,
          colorType: 0,
          channels: [(1 << bits) - 1],
        );
        expect(img.decodePng(white), isNotNull);
        final self = comparePixels(white, white, mode: .regression);
        expect(self.diffPixelCount, 0);
        final result = comparePixels(black, white, mode: .parity);
        expect(result.maxChannelDelta, (1 << bits) - 1);
        expect(result.passed, isTrue); // Original raw-unit contract.
      });
      test('$bits-bit palette keeps decoded palette colours', () {
        final black = samplePng(bits: bits, colorType: 3, channels: [0]);
        final red = samplePng(bits: bits, colorType: 3, channels: [1]);
        expect(img.decodePng(red), isNotNull);
        expect(comparePixels(red, red, mode: .regression).diffPixelCount, 0);
        final result = comparePixels(black, red, mode: .parity);
        expect(result.maxChannelDelta, 200);
        expect(result.passed, isFalse);
      });
    }
    test('16-bit RGB identity and >32 use original channel units', () {
      final first = samplePng(
        bits: 16,
        colorType: 2,
        channels: [1000, 2000, 3000],
      );
      expect(img.decodePng(first), isNotNull);
      expect(comparePixels(first, first, mode: .regression).maxChannelDelta, 0);
      for (final delta in [32, 33]) {
        final second = samplePng(
          bits: 16,
          colorType: 2,
          channels: [1000 + delta, 2000, 3000],
        );
        final result = comparePixels(first, second, mode: .parity);
        expect(result.maxChannelDelta, delta);
        expect(result.passed, delta == 32);
      }
    });
    test('16-bit alpha stays in original channel units', () {
      final first = samplePng(
        bits: 16,
        colorType: 6,
        channels: [1000, 2000, 3000, 4000],
      );
      final second = samplePng(
        bits: 16,
        colorType: 6,
        channels: [1000, 2000, 3000, 4033],
      );
      final result = comparePixels(first, second, mode: .parity);
      expect(result.maxChannelDelta, 33);
      expect(result.passed, isFalse);
    });
  });

  test('float difference32.1817 remains beyond unchanged threshold32', () {
    // Existing LCMS2.17 floating PCS reference for P3(159,0,0):
    // extended sRGB(174.258336,-32.181732,-19.619749), without gamut clamp.
    final result = comparePixels(
      profilePng([159, 0, 0, 255], srgb: true),
      profilePng([159, 0, 0, 255], profile: p3Profile()),
      mode: .parity,
    );
    expect(kChannelDeltaThreshold, 32);
    expect(result.diffRatio, 1);
    expect(result.passed, isFalse);
    expect(result.maxChannelDelta, 33);
  });
  for (final oracle in curveOracle) {
    test('generic ${oracle['name']} agrees with independent float CMS', () {
      final profile = curveProfile(oracle['curveHex'] as String);
      for (final raw in oracle['vectors'] as List) {
        final vector = raw as Map;
        final rgb = (vector['rgb'] as List).cast<int>();
        // This one intentionally exceeds the ICC source curve range;
        // LCMS's unbounded floating pipeline and the mandated ICC clip are
        // different contracts. Its normative clip is checked separately.
        if (oracle['name'] == 'para4' && rgb.every((v) => v == 255)) continue;
        final space = PngColorSpace.fromPng(
          profilePng([...rgb, 255], profile: profile),
        );
        final actual = space.rgb(rgb[0], rgb[1], rgb[2]);
        final expected = (vector['expected'] as List).cast<num>();
        if (oracle['name'] == 'table5') {
          // LCMS's sampled curve interpolation retains16-bit quantization.
          // Compare independent floating PCS within2 table units, before
          // the high near-black sensitivity of the target transfer curve.
          final pcs = _xyzD50(actual);
          final pcsReference = (vector['xyz'] as List).cast<num>();
          for (var i = 0; i < 3; i++) {
            expect(pcs[i], closeTo(pcsReference[i], 2 / 65535));
          }
          continue;
        }
        for (var i = 0; i < 3; i++) {
          expect(actual[i], closeTo(expected[i], .001));
        }
      }
    });
  }
  test(
    'ICC para4 clips its source curve range without clipping target gamut',
    () {
      final oracle = curveOracle.firstWhere((v) => v['name'] == 'para4');
      final profile = curveProfile(oracle['curveHex'] as String);
      final actual = PngColorSpace.fromPng(
        profilePng([255, 255, 255, 255], profile: profile),
      ).rgb(255, 255, 255);
      // ICC.1:2022 §10.18/Table68: y=1.009994... is clipped to1 at
      // the SOURCE TRC. The identity profile shares the same matrix and
      // independently measured LCMS white; output values may exceed255.
      final white =
          ((curveOracle.first['vectors'] as List).last as Map)['expected']
              as List;
      for (var i = 0; i < 3; i++) {
        expect(actual[i], closeTo(white[i] as num, .001));
      }
      expect(actual[2], greaterThan(255));
    },
  );
  test('independent sRGB matrix profile agrees with float CMS', () {
    for (final vector in srgbOracle) {
      final rgb = (vector['rgb'] as List).cast<int>();
      final space = PngColorSpace.fromPng(
        profilePng([...rgb, 255], profile: srgbProfile()),
      );
      final actual = space.rgb(rgb[0], rgb[1], rgb[2]);
      final expected = (vector['expected'] as List).cast<num>();
      for (var i = 0; i < 3; i++) {
        expect(actual[i], closeTo(expected[i], .001));
      }
    }
  });
  test('indexed RGB ICC uses palette8-bit values at low index depths', () {
    final raw = samplePng(
      bits: 1,
      colorType: 3,
      channels: [1],
      profile: p3Profile(),
    );
    final actual = PngColorSpace.fromPng(raw).rgb(200, 40, 60);
    final expected = PngColorSpace.fromPng(
      profilePng([200, 40, 60, 255], profile: p3Profile()),
    ).rgb(200, 40, 60);
    expect(actual, expected);
  });
  test(
    'ICC16 and mixed ICC8/unmanaged16 fail explicitly, not unit guessing',
    () {
      final raw = samplePng(bits: 16, colorType: 2, channels: [159, 0, 0]);
      final managed = profilePng([159, 0, 0, 255], profile: p3Profile());
      expect(
        () => comparePixels(raw, managed, mode: .parity),
        throwsFormatException,
      );
      final tagged16 = samplePng(
        bits: 16,
        colorType: 2,
        channels: [159, 0, 0],
        profile: p3Profile(),
      );
      expect(img.decodePng(tagged16), isNotNull);
      expect(() => PngColorSpace.fromPng(tagged16), throwsFormatException);
    },
  );
  test('higher-priority ICC LUT is rejected instead of matrix fallback', () {
    // Repurpose the existing description entry as a declared A2B0 transform.
    final profile = p3Profile()..setRange(132, 136, 'A2B0'.codeUnits);
    final png = profilePng([100, 90, 80, 255], profile: profile);
    expect(() => PngColorSpace.fromPng(png), throwsFormatException);
  });
  test(
    'bad colour-chunk checksum and compressed profile are explicit errors',
    () {
      final valid = profilePng([100, 90, 80, 255], srgb: true);
      final invalidCrc = Uint8List.fromList(valid)..[41] ^= 1;
      expect(() => PngColorSpace.fromPng(invalidCrc), throwsFormatException);
      final invalidZlib = withChunk(
        profilePng([100, 90, 80, 255]),
        'iCCP',
        Uint8List.fromList([120, 0, 0, 1, 2, 3]),
      );
      expect(() => PngColorSpace.fromPng(invalidZlib), throwsFormatException);
    },
  );
}

// Normative CSS Color4 inverse of the extended-sRGB output coordinates.
// It lets a sampled16-bit CMS curve be checked in independent linear PCS
// units instead of loosening the pixel channel threshold or clamping RGB.
List<double> _xyzD50(List<double> rgb) {
  final linear = rgb.map((channel) {
    final v = channel / 255;
    return v.abs() <= .04045
        ? v / 12.92
        : v.sign * math.pow((v.abs() + .055) / 1.055, 2.4);
  }).toList();
  List<double> multiply(List<List<double>> matrix, List<num> vector) => matrix
      .map(
        (row) =>
            List.generate(3, (i) => row[i] * vector[i]).reduce((a, b) => a + b),
      )
      .toList();
  final d65 = multiply([
    [506752 / 1228815, 87881 / 245763, 12673 / 70218],
    [87098 / 409605, 175762 / 245763, 12673 / 175545],
    [7918 / 409605, 87881 / 737289, 1001167 / 1053270],
  ], linear);
  return multiply([
    [1.0479297925449969, .022946870601609652, -.05019226628920524],
    [.02962780877005599, .9904344267538799, -.017073799063418826],
    [-.009243040646204504, .015055191490298152, .7518742814281371],
  ], d65);
}
