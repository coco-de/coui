import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/diff/pixel_diff.dart';
import 'png_color_profile_fixtures.dart';

void main() {
  group('declared PNG colour spaces', () {
    // The P3 triplets are independent LCMS2.17 results. The floating green
    // roundtrip differs by2.076 sRGB units; its integer diagnostic rounds up
    // to3. The threshold remains32.
    for (final (name, srgb, p3) in [
      ('green', [0, 127, 51], [55, 125, 60]),
      ('blue', [0, 110, 209], [46, 108, 202]),
      ('orange', [233, 169, 28], [223, 172, 65]),
      ('gray', [128, 128, 128], [128, 128, 128]),
    ]) {
      test('same $name encoded as sRGB and ICC RGB agrees', () {
        final result = comparePixels(
          profilePng([...srgb, 255], srgb: true),
          profilePng([...p3, 255], profile: p3Profile()),
          mode: .parity,
        );
        expect(result.passed, isTrue);
        expect(result.diffPixelCount, 0);
        expect(result.maxChannelDelta, lessThanOrEqualTo(3));
      });
    }
    test('same colour retains its independent alpha128', () {
      final result = comparePixels(
        profilePng([0, 127, 51, 128], srgb: true),
        profilePng([55, 125, 60, 128], profile: p3Profile()),
        mode: .parity,
      );
      expect(result.passed, isTrue);
      expect(result.maxChannelDelta, lessThanOrEqualTo(3));
    });
    for (final rgb in [
      [255, 0, 0],
      [0, 255, 0],
    ]) {
      for (final alpha in [255, 128]) {
        test('equal numbers $rgb/$alpha keep different wide-gamut colours', () {
          final result = comparePixels(
            profilePng([...rgb, alpha], srgb: true),
            profilePng([...rgb, alpha], profile: p3Profile()),
            mode: .parity,
          );
          expect(result.passed, isFalse);
          expect(result.diffRatio, 1);
          expect(result.maxChannelDelta, greaterThan(kChannelDeltaThreshold));
        });
      }
    }
    test('truly different colour and alpha still fail', () {
      final source = profilePng([0, 127, 51, 255], srgb: true);
      for (final second in [
        profilePng([197, 53, 46, 255], profile: p3Profile()),
        profilePng([55, 125, 60, 128], profile: p3Profile()),
      ]) {
        expect(comparePixels(source, second, mode: .parity).passed, isFalse);
      }
    });
    test('explicit sRGB and legacy untagged numeric identity remain exact', () {
      final untagged = profilePng([8, 49, 101, 199]);
      final srgb = profilePng([8, 49, 101, 199], srgb: true);
      for (final mode in PixelDiffMode.values) {
        final result = comparePixels(untagged, srgb, mode: mode);
        expect(result.diffPixelCount, 0);
        expect(result.maxChannelDelta, 0);
        expect(result.passed, isTrue);
      }
    });
    test('unsupported ICC curve never silently compares raw samples', () {
      final source = profilePng([100, 90, 80, 255]);
      final unsupported = profilePng(
        [100, 90, 80, 255],
        profile: unsupportedCurveProfile(),
      );
      // A valid PNG whose profile format is outside the supported decoder;
      // this is not a PNG framing/CRC failure posing as the expected failure.
      expect(img.decodePng(unsupported), isNotNull);
      expect(
        () => comparePixels(source, unsupported, mode: .parity),
        throwsFormatException,
      );
    });
    test('higher-precedence unsupported cICP is not hidden by ICC or sRGB', () {
      final source = profilePng([100, 90, 80, 255]);
      final encoded = withChunk(
        profilePng([100, 90, 80, 255], profile: p3Profile(), srgb: true),
        'cICP',
        Uint8List.fromList([9, 16, 0, 1]),
      );
      expect(img.decodePng(encoded), isNotNull);
      expect(
        () => comparePixels(source, encoded, mode: .parity),
        throwsFormatException,
      );
    });
    test('gAMA-only source is explicit unsupported, not untagged identity', () {
      final source = profilePng([100, 90, 80, 255]);
      final gamma = Uint8List(4);
      ByteData.sublistView(gamma).setUint32(0, 100000);
      final encoded = withChunk(source, 'gAMA', gamma);
      expect(img.decodePng(encoded), isNotNull);
      expect(
        () => comparePixels(source, encoded, mode: .parity),
        throwsFormatException,
      );
    });
    test('sRGB authority takes precedence over gAMA sample interpretation', () {
      final source = profilePng([100, 90, 80, 255], srgb: true);
      final gamma = Uint8List(4);
      ByteData.sublistView(gamma).setUint32(0, 100000);
      final result = comparePixels(
        source,
        withChunk(source, 'gAMA', gamma),
        mode: .parity,
      );
      expect(result.diffPixelCount, 0);
      expect(result.maxChannelDelta, 0);
    });
  });
}
