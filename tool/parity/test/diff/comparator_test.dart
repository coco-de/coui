// Synthetic snapshots/PNGs only — no capture, no browser.
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/diff/comparator.dart';
import '../../src/model/property_snapshot.dart';

PropertySnapshot _snapshot(String platform, {int fontWeight = 400}) => .new(
  key: 'k',
  platform: platform,
  probeRole: 'root',
  fontWeight: fontWeight,
);

Uint8List _solidPng(int r, int g, int b) {
  final image = img.Image(width: 4, height: 4, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = r
      ..g = g
      ..b = b
      ..a = 255;
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('ComparisonSignal', () {
    test('parses the three wire values', () {
      expect(ComparisonSignal.tryParse('property'), ComparisonSignal.property);
      expect(ComparisonSignal.tryParse('pixel'), ComparisonSignal.pixel);
      expect(ComparisonSignal.tryParse('both'), ComparisonSignal.both);
    });

    test('an unrecognized value parses to null', () {
      expect(ComparisonSignal.tryParse('motion'), isNull);
    });

    test('includesProperty/includesPixel per signal', () {
      expect(ComparisonSignal.property.includesProperty, isTrue);
      expect(ComparisonSignal.property.includesPixel, isFalse);
      expect(ComparisonSignal.pixel.includesProperty, isFalse);
      expect(ComparisonSignal.pixel.includesPixel, isTrue);
      expect(ComparisonSignal.both.includesProperty, isTrue);
      expect(ComparisonSignal.both.includesPixel, isTrue);
    });
  });

  group('compareEntry — signal selection', () {
    test('signal=property never computes a pixel diff', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .property,
        flutterProperty: _snapshot('flutter'),
        webProperty: _snapshot('web'),
      );
      expect(result.propertyDiff, isNotNull);
      expect(result.crossPlatformParity, isNull);
      expect(result.flutterRegression, isNull);
      expect(result.webRegression, isNull);
      expect(result.pixelSkippedReason, contains('signal=property'));
    });

    test('signal=pixel never computes a property diff', () {
      final png = _solidPng(1, 2, 3);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: png,
        webPng: png,
      );
      expect(result.propertyDiff, isNull);
      expect(result.crossPlatformParity, isNotNull);
    });

    test('signal=both computes both when property passes', () {
      final png = _solidPng(1, 2, 3);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .both,
        flutterProperty: _snapshot('flutter'),
        webProperty: _snapshot('web'),
        flutterPng: png,
        webPng: png,
      );
      expect(result.propertyDiff!.hasFailures, isFalse);
      expect(result.crossPlatformParity, isNotNull);
      expect(result.pixelSkippedReason, isNull);
    });
  });

  group('compareEntry — property-failure short-circuit (parity only)', () {
    test(
      'signal=both: a property failure skips the cross-platform parity '
      'pixel check but the own-baseline regression still runs',
      () {
        final captured = _solidPng(0, 0, 0);
        final baseline = _solidPng(255, 255, 255);
        final result = compareEntry(
          key: 'k',
          probeRole: 'root',
          signal: .both,
          flutterProperty: _snapshot('flutter', fontWeight: 600),
          webProperty: _snapshot('web'),
          flutterPng: captured,
          flutterBaselinePng: baseline,
          webPng: captured,
          webBaselinePng: baseline,
        );
        expect(result.propertyDiff!.hasFailures, isTrue);
        // parity 만 short-circuit — 교차 플랫폼 불일치의 원인은 이미
        // property 가 특정했다.
        expect(result.crossPlatformParity, isNull);
        expect(
          result.paritySkippedReason,
          contains('PropertyDiff 가 이미 실패'),
        );
        expect(result.pixelSkippedReason, isNull);
        // own-baseline regression 은 별개 질문이라 계속 돈다 — 여기서도
        // 스킵하면 property 실패가 있는 컴포넌트는 시각 회귀 커버리지를
        // 조용히 잃는다.
        expect(result.flutterRegression, isNotNull);
        expect(result.flutterRegression!.passed, isFalse);
        expect(result.webRegression, isNotNull);
        expect(result.passed, isFalse);
      },
    );

    test(
      'property failure with no baselines: parity skipped, regression '
      'skipped only for lack of a baseline',
      () {
        final png = _solidPng(0, 0, 0);
        final result = compareEntry(
          key: 'k',
          probeRole: 'root',
          signal: .both,
          flutterProperty: _snapshot('flutter', fontWeight: 600),
          webProperty: _snapshot('web'),
          flutterPng: png,
          webPng: png,
        );
        expect(result.crossPlatformParity, isNull);
        expect(result.paritySkippedReason, isNotNull);
        expect(result.flutterRegression, isNull);
        expect(result.webRegression, isNull);
      },
    );
  });

  group('compareEntry — baseline-aware regression skip', () {
    test(
      'no baseline for either platform: only cross-platform parity runs',
      () {
        final png = _solidPng(10, 20, 30);
        final result = compareEntry(
          key: 'k',
          probeRole: 'root',
          signal: .pixel,
          flutterPng: png,
          webPng: png,
        );
        expect(result.flutterRegression, isNull);
        expect(result.webRegression, isNull);
        expect(result.crossPlatformParity, isNotNull);
      },
    );

    test(
      "a baseline for one platform only runs that platform's regression, "
      'not the other',
      () {
        // Same render on both platforms — this test is about *which*
        // baselines fire, not whether they'd pass or fail.
        final renderedPng = _solidPng(10, 20, 30);
        final result = compareEntry(
          key: 'k',
          probeRole: 'root',
          signal: .pixel,
          flutterPng: renderedPng,
          flutterBaselinePng: renderedPng,
          webPng: renderedPng,
          // No web baseline — first capture for Web.
        );
        expect(result.flutterRegression, isNotNull);
        expect(result.webRegression, isNull);
      },
    );

    test('a baseline for both platforms runs both regressions', () {
      final renderedPng = _solidPng(10, 20, 30);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: renderedPng,
        flutterBaselinePng: renderedPng,
        webPng: renderedPng,
        webBaselinePng: renderedPng,
      );
      expect(result.flutterRegression, isNotNull);
      expect(result.webRegression, isNotNull);
    });
  });

  group('ComparisonResult.passed', () {
    test('a skipped signal never contributes a failure on its own', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .property,
        flutterProperty: _snapshot('flutter'),
        webProperty: _snapshot('web'),
      );
      expect(result.passed, isTrue);
    });

    test('a failing regression fails the whole result', () {
      final flutterPng = _solidPng(0, 0, 0);
      final flutterBaseline = _solidPng(255, 255, 255);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: flutterPng,
        flutterBaselinePng: flutterBaseline,
        webPng: flutterPng,
      );
      expect(result.flutterRegression!.passed, isFalse);
      expect(result.passed, isFalse);
    });
  });

  group('compareEntry — regression color-transition direction', () {
    test('transitions read baseline → captured, not the reverse', () {
      // baseline 은 민트(#2eb8a1), 이번 캡처는 어두운 청록(#207e6f) —
      // 리포트의 "주요 변화" 는 반드시 "전(민트) → 후(청록)" 로 읽혀야
      // 한다. 인자 순서가 뒤집히면 변화 방향이 거꾸로 보고된다.
      final baseline = _solidPng(0x2e, 0xb8, 0xa1);
      final captured = _solidPng(0x20, 0x7e, 0x6f);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: captured,
        flutterBaselinePng: baseline,
        webPng: captured,
        webBaselinePng: baseline,
      );
      for (final regression in [
        result.flutterRegression!,
        result.webRegression!,
      ]) {
        final transition = regression.topColorTransitions.first;
        expect(transition.fromHex, '#2eb8a1');
        expect(transition.toHex, '#207e6f');
      }
    });
  });
}
