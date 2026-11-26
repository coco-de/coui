// Synthetic in-memory PNGs only — no capture, no browser, no dev server
// (completion definition: "셀프테스트... 브라우저·dev server 없이 통과").
// Fixture pixel counts/coordinates are meaningful (they're what makes a
// fixture "10% different" vs "0.05% different"), not noise.
// `avoid-missing-image-alt` is a Flutter-widget lint misfiring on
// package:image's unrelated `Image` class, which this whole file
// constructs directly and repeatedly.
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/diff/pixel_diff.dart';

const int _kSize = 10;

Uint8List _solidPng(int r, int g, int b) {
  final image = img.Image(width: _kSize, height: _kSize, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = r
      ..g = g
      ..b = b
      ..a = 255;
  }
  return Uint8List.fromList(img.encodePng(image));
}

/// A solid [r]/[g]/[b] image with the top-left [differingPixelCount]
/// pixels (row-major) painted white instead — a controlled, countable
/// diff region.
Uint8List _solidPngWithDiffRegion(
  int r,
  int g,
  int b, {
  required int differingPixelCount,
}) {
  final image = img.Image(width: _kSize, height: _kSize, numChannels: 4);
  var index = 0;
  for (final pixel in image) {
    if (index < differingPixelCount) {
      pixel
        ..r = 255
        ..g = 255
        ..b = 255
        ..a = 255;
    } else {
      pixel
        ..r = r
        ..g = g
        ..b = b
        ..a = 255;
    }
    index++;
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('comparePixels — identical images', () {
    test('an image compared to itself passes both modes', () {
      final png = _solidPng(10, 20, 30);
      for (final mode in PixelDiffMode.values) {
        final result = comparePixels(png, png, mode: mode);
        expect(result.passed, isTrue, reason: mode.name);
        expect(result.diffPixelCount, 0);
        expect(result.diffImageBytes, isNull);
      }
    });
  });

  group('comparePixels — dimension mismatch', () {
    test('reports a dimension mismatch instead of a diff ratio', () {
      final a = Uint8List.fromList(
        img.encodePng(img.Image(width: 10, height: 10)),
      );
      final b = Uint8List.fromList(
        img.encodePng(img.Image(width: 20, height: 10)),
      );
      final result = comparePixels(a, b, mode: .parity);
      expect(result.dimensionMismatch, '10x10 vs 20x10');
      expect(result.passed, isFalse);
      expect(result.diffImageBytes, isNull);
    });
  });

  group('comparePixels — regression mode (strict)', () {
    test('a tiny diff ratio at exactly the threshold still passes', () {
      final totalPixels = _kSize * _kSize;
      final diffCount = (totalPixels * kRegressionThreshold).floor();
      final a = _solidPng(0, 0, 0);
      final b = _solidPngWithDiffRegion(
        0,
        0,
        0,
        differingPixelCount: diffCount,
      );
      final result = comparePixels(a, b, mode: .regression);
      expect(result.passed, isTrue);
    });

    test(
      'a diff ratio a browser-vs-browser regression pipeline would '
      'accept (0.3%) fails under this much stricter same-renderer '
      'threshold',
      () {
        final totalPixels = _kSize * _kSize;
        // 0.3% — comfortably inside the *old* docs_site scaffolding's
        // 0.5% regression threshold, deliberately exceeding this
        // pipeline's much stricter same-renderer expectation.
        final diffCount = (totalPixels * 0.003).ceil().clamp(1, totalPixels);
        final a = _solidPng(0, 0, 0);
        final b = _solidPngWithDiffRegion(
          0,
          0,
          0,
          differingPixelCount: diffCount,
        );
        final result = comparePixels(a, b, mode: .regression);
        expect(result.passed, isFalse);
        expect(result.diffImageBytes, isNotNull);
      },
    );
  });

  group('comparePixels — parity mode (lenient)', () {
    test(
      'a diff ratio well beyond regression tolerance still passes parity '
      "mode's looser cross-rasterizer threshold",
      () {
        final totalPixels = _kSize * _kSize;
        final diffCount = (totalPixels * 0.02).floor(); // 2%
        final a = _solidPng(200, 200, 200);
        final b = _solidPngWithDiffRegion(
          200,
          200,
          200,
          differingPixelCount: diffCount,
        );
        final result = comparePixels(a, b, mode: .parity);
        expect(result.passed, isTrue);
      },
    );

    test('a diff ratio beyond even the parity threshold fails', () {
      final totalPixels = _kSize * _kSize;
      final diffCount = totalPixels; // 100% different
      final a = _solidPng(0, 0, 0);
      final b = _solidPng(255, 255, 255);
      final result = comparePixels(a, b, mode: .parity);
      expect(result.passed, isFalse);
      expect(result.diffPixelCount, diffCount);
      expect(result.diffImageBytes, isNotNull);
    });
  });

  group('comparePixels — diff image output', () {
    test('the emitted diff image decodes and matches input dimensions', () {
      final a = _solidPng(0, 0, 0);
      final b = _solidPng(255, 255, 255);
      final result = comparePixels(a, b, mode: .regression);
      final diffImage = img.decodePng(result.diffImageBytes!);
      expect(diffImage, isNotNull);
      expect(diffImage!.width, _kSize);
      expect(diffImage.height, _kSize);
    });
  });

  group('thresholdFor', () {
    test('regression is stricter than parity', () {
      expect(
        thresholdFor(.regression),
        lessThan(thresholdFor(.parity)),
      );
    });
  });

  group('comparePixels — diff statistics (VRT report figures)', () {
    test('records image dimensions and the max observed channel delta', () {
      final a = _solidPng(0, 0, 0);
      final b = _solidPng(74, 0, 0);
      final result = comparePixels(a, b, mode: .regression);
      expect(result.width, _kSize);
      expect(result.height, _kSize);
      expect(result.maxChannelDelta, 74);
    });

    test(
      'a passing comparison still reports sub-threshold noise as '
      'maxChannelDelta',
      () {
        final a = _solidPng(0, 0, 0);
        final b = _solidPng(10, 0, 0); // ≤ kChannelDeltaThreshold — no diff
        final result = comparePixels(a, b, mode: .regression);
        expect(result.passed, isTrue);
        expect(result.diffPixelCount, 0);
        expect(result.maxChannelDelta, 10);
        expect(result.topColorTransitions, isEmpty);
      },
    );

    test('captures the dominant color transition with exact hex pairs', () {
      // #2eb8a1 → #207e6f — the mint→teal shift the report format's
      // "주요 변화" block was designed around.
      final a = _solidPng(0x2e, 0xb8, 0xa1);
      final b = _solidPng(0x20, 0x7e, 0x6f);
      final result = comparePixels(a, b, mode: .regression);
      expect(result.topColorTransitions, hasLength(1));
      final transition = result.topColorTransitions.first;
      expect(transition.fromHex, '#2eb8a1');
      expect(transition.toHex, '#207e6f');
      expect(transition.count, _kSize * _kSize);
    });

    test('orders transitions by pixel count, largest bucket first', () {
      final a = _solidPng(0x2e, 0xb8, 0xa1);
      // 30 px shift to white, the remaining 70 px shift to dark teal —
      // two distinct buckets with a known size order.
      final b = _solidPngWithDiffRegion(
        0x20,
        0x7e,
        0x6f,
        differingPixelCount: 30,
      );
      final result = comparePixels(a, b, mode: .regression);
      expect(result.topColorTransitions, hasLength(2));
      expect(result.topColorTransitions[0].toHex, '#207e6f');
      expect(result.topColorTransitions[0].count, 70);
      expect(result.topColorTransitions[1].toHex, '#ffffff');
      expect(result.topColorTransitions[1].count, 30);
    });
  });

  group('PixelDiffResult.describe — the report-format block', () {
    test('renders resolution, pixel stats, and dominant color shifts', () {
      final a = _solidPng(0x2e, 0xb8, 0xa1);
      final b = _solidPng(0x20, 0x7e, 0x6f);
      final described = comparePixels(a, b, mode: .regression).describe();
      expect(described, contains('해상도: 10×10 (동일)'));
      // ratio 와 임계는 같은 정밀도(3자리) — ratio 를 더 굵게 반올림하면
      // 경계 FAIL 이 자기 임계 이하 수치로 표시될 수 있다.
      expect(described, contains('픽셀 diff: 100 / 100 px (100.000%)'));
      expect(described, contains('최대 채널차 58'));
      expect(described, contains('주요 변화:'));
      expect(described, contains('#2eb8a1 → #207e6f   (100 px)'));
    });

    test('a dimension mismatch is its own sentence, no pixel stats', () {
      final a = Uint8List.fromList(
        img.encodePng(img.Image(width: 10, height: 10)),
      );
      final b = Uint8List.fromList(
        img.encodePng(img.Image(width: 20, height: 10)),
      );
      final described = comparePixels(a, b, mode: .regression).describe();
      expect(described, contains('해상도 불일치: 10x10 vs 20x10'));
      expect(described, isNot(contains('픽셀 diff:')));
    });
  });

  group('formatThousands', () {
    test('groups digits in threes', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(100), '100');
      expect(formatThousands(1000), '1,000');
      expect(formatThousands(20622), '20,622');
      expect(formatThousands(836964), '836,964');
      expect(formatThousands(1234567), '1,234,567');
    });
  });
}
