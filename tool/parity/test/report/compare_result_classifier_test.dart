import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/baseline/baseline_store.dart';
import '../../src/diff/comparator.dart';
import '../../src/model/property_snapshot.dart';
import '../../src/report/compare_result_classifier.dart';
import '../../src/report/failure_category.dart';

Uint8List _solidPng(int r, int g, int b, {int width = 8, int height = 8}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = r
      ..g = g
      ..b = b
      ..a = 255;
  }
  return Uint8List.fromList(img.encodePng(image));
}

PropertySnapshot _snapshot(String platform, {int fontWeight = 400}) => .new(
  key: 'card-outlined-light-neoBrutalism',
  platform: platform,
  probeRole: 'root',
  fontWeight: fontWeight,
);

void main() {
  group('classifyComparisonResult — property', () {
    test('property mismatch -> parity-property, no allowlist needed', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .property,
        flutterProperty: _snapshot('flutter', fontWeight: 600),
        webProperty: _snapshot('web'),
      );

      final failures = classifyComparisonResult(result);

      expect(failures, hasLength(1));
      expect(failures.single.category, FailureCategory.parityProperty);
      expect(failures.single.summary, contains('fontWeight'));
      expect(failures.single.allowlistHint, isNull);
      expect(
        failures.single.diffArtifactPaths,
        ['k.root.property.diff.json'],
      );
    });

    test('matching properties -> no failures', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .property,
        flutterProperty: _snapshot('flutter'),
        webProperty: _snapshot('web'),
      );

      expect(classifyComparisonResult(result), isEmpty);
    });
  });

  group('classifyComparisonResult — pixel regression (no allowlist)', () {
    test('regression over threshold -> regression, no reclassification', () {
      final current = _solidPng(255, 0, 0);
      final baseline = _solidPng(0, 0, 255); // far enough to exceed 0.1%

      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: current,
        flutterBaselinePng: baseline,
        webPng: current,
        webBaselinePng: baseline,
        pixelModes: {.regression},
      );

      final failures = classifyComparisonResult(result);

      // Both platforms regressed independently.
      expect(failures, hasLength(2));
      expect(
        failures.map((f) => f.category),
        everyElement(FailureCategory.regression),
      );
      expect(
        failures.map((f) => f.summary),
        everyElement(
          anyOf(contains('flutter-regression'), contains('web-regression')),
        ),
      );
    });

    test('no baseline (first capture) -> nothing to classify', () {
      final current = _solidPng(255, 0, 0);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: current,
        webPng: current,
        pixelModes: {.regression},
      );

      expect(classifyComparisonResult(result), isEmpty);
    });
  });

  group('classifyComparisonResult — allowlist reconciliation', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('coui-parity-report-');
    });

    tearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });

    test('approved change (matching fingerprint) is dropped entirely', () {
      final current = _solidPng(255, 0, 0);
      final baseline = _solidPng(0, 0, 255);
      final currentFingerprint = BaselineStore.fingerprintOfBytes(current);

      File(
        '${tempRoot.path}/baseline/k.flutter.png',
      ).createSync(recursive: true);
      File(
        '${tempRoot.path}/baseline/k.flutter.png',
      ).writeAsBytesSync(baseline);

      File('${tempRoot.path}/allowlist.yaml').writeAsStringSync('''
entries:
  - key: k
    signal: pixel
    fingerprint: "$currentFingerprint"
    reason: intentional redesign
    expires: 2999-01-01
''');

      final store = BaselineStore.at(tempRoot.path);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: current,
        flutterBaselinePng: baseline,
        // Web has no committed baseline of its own here — first capture,
        // its regression check is skipped by design so this test can
        // isolate Flutter's reclassification path.
        webPng: current,
        pixelModes: {.regression},
      );

      final failures = classifyComparisonResult(
        result,
        baselineStore: store,
        flutterCapturedPng: current,
        now: DateTime.utc(2026),
      );

      expect(failures, isEmpty);
    });

    test('expired allowlist entry -> allowlist-expired, not regression', () {
      final current = _solidPng(255, 0, 0);
      final baseline = _solidPng(0, 0, 255);
      final currentFingerprint = BaselineStore.fingerprintOfBytes(current);

      File(
        '${tempRoot.path}/baseline/k.flutter.png',
      ).createSync(recursive: true);
      File(
        '${tempRoot.path}/baseline/k.flutter.png',
      ).writeAsBytesSync(baseline);

      File('${tempRoot.path}/allowlist.yaml').writeAsStringSync('''
entries:
  - key: k
    signal: pixel
    fingerprint: "$currentFingerprint"
    reason: intentional redesign
    expires: 2020-01-01
''');

      final store = BaselineStore.at(tempRoot.path);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: current,
        flutterBaselinePng: baseline,
        // Web has no committed baseline of its own here — first capture,
        // its regression check is skipped by design so this test can
        // isolate Flutter's reclassification path.
        webPng: current,
        pixelModes: {.regression},
      );

      final failures = classifyComparisonResult(
        result,
        baselineStore: store,
        flutterCapturedPng: current,
        now: DateTime.utc(2026),
      );

      expect(failures, hasLength(1));
      expect(failures.single.category, FailureCategory.allowlistExpired);
      expect(failures.single.allowlistHint, contains(currentFingerprint));
    });

    test('unapproved change with unrelated allowlist entry -> regression', () {
      final current = _solidPng(255, 0, 0);
      final baseline = _solidPng(0, 0, 255);

      File(
        '${tempRoot.path}/baseline/k.flutter.png',
      ).createSync(recursive: true);
      File(
        '${tempRoot.path}/baseline/k.flutter.png',
      ).writeAsBytesSync(baseline);

      File('${tempRoot.path}/allowlist.yaml').writeAsStringSync('''
entries:
  - key: k
    signal: pixel
    fingerprint: "0000000000000000000000000000000000000000000000000000000000000000"
    reason: unrelated approval
    expires: 2999-01-01
''');

      final store = BaselineStore.at(tempRoot.path);
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: current,
        flutterBaselinePng: baseline,
        // Web has no committed baseline of its own here — first capture,
        // its regression check is skipped by design so this test can
        // isolate Flutter's reclassification path.
        webPng: current,
        pixelModes: {.regression},
      );

      final failures = classifyComparisonResult(
        result,
        baselineStore: store,
        flutterCapturedPng: current,
        now: DateTime.utc(2026),
      );

      expect(failures, hasLength(1));
      expect(failures.single.category, FailureCategory.regression);
    });
  });

  group('classifyComparisonResult — cross-platform parity', () {
    test('pixel-only failure reports the property signal as unmeasured', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: _solidPng(255, 0, 0),
        webPng: _solidPng(0, 0, 255),
        pixelModes: {.parity},
      );

      final failures = classifyComparisonResult(result);

      expect(result.propertyDiff, isNull);
      expect(result.passed, isFalse);
      expect(failures, hasLength(1));
      expect(failures.single.category, FailureCategory.parityPixel);
      expect(failures.single.summary, contains('속성 비교는 실행하지 않았습니다.'));
      expect(failures.single.summary, isNot(contains('통과')));
      expect(failures.single.summary, isNot(contains('완전 일치')));
      expect(failures.single.summary, isNot(contains('래스터라이저')));
    });

    test('different capture dimensions do not imply a rasterizer cause', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: _solidPng(255, 0, 0),
        webPng: _solidPng(255, 0, 0, width: 9),
        pixelModes: {.parity},
      );

      final failures = classifyComparisonResult(result);

      expect(result.passed, isFalse);
      expect(failures, hasLength(1));
      expect(failures.single.category, FailureCategory.parityPixel);
      expect(failures.single.summary, contains('dimension mismatch'));
      expect(failures.single.summary, contains('속성 비교는 실행하지 않았습니다.'));
      expect(failures.single.summary, isNot(contains('완전 일치')));
      expect(failures.single.summary, isNot(contains('래스터라이저')));
    });

    test(
      'property matched + pixel exceeded reports the measured property result',
      () {
        final flutterPng = _solidPng(255, 0, 0);
        final webPng = _solidPng(0, 0, 255);

        final result = compareEntry(
          key: 'command-default-light-neoBrutalism',
          probeRole: 'root',
          signal: .both,
          flutterProperty: _snapshot('flutter'),
          webProperty: _snapshot('web'),
          flutterPng: flutterPng,
          webPng: webPng,
          pixelModes: {.parity},
        );

        final failures = classifyComparisonResult(result);

        expect(failures, hasLength(1));
        expect(failures.single.category, FailureCategory.parityPixel);
        expect(result.propertyDiff!.hasFailures, isFalse);
        expect(failures.single.summary, contains('측정한 속성 비교는 통과했습니다.'));
        expect(failures.single.summary, isNot(contains('완전 일치')));
        expect(failures.single.summary, isNot(contains('래스터라이저')));
      },
    );

    test(
      'property failure skips parity pixels and reports the property failure',
      () {
        final flutterPng = _solidPng(255, 0, 0);
        final webPng = _solidPng(0, 0, 255);

        final result = compareEntry(
          key: 'k',
          probeRole: 'root',
          signal: .both,
          flutterProperty: _snapshot('flutter', fontWeight: 600),
          webProperty: _snapshot('web'),
          flutterPng: flutterPng,
          webPng: webPng,
          pixelModes: {.parity},
        );

        final failures = classifyComparisonResult(result);

        expect(failures, hasLength(1));
        expect(failures.single.category, FailureCategory.parityProperty);
      },
    );
  });
}
