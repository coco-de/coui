// #3617 — reclassifies one `ComparisonResult` (compare.dart/#3607's
// per-entry output) into zero or more [ClassifiedFailure]s.
//
// Why allowlist reconciliation happens here and not in `comparator.dart`:
// `compareEntry` (comparator.dart, #3607) compares raw pixel bytes against
// whatever baseline file exists — it has no allowlist awareness, so an
// approved-but-still-different pixel capture is still `!passed` there.
// Rewiring `BaselineStore.evaluate()` into that comparison would change
// `compare.dart`'s own exit code semantics, which is out of this issue's
// scope and carries regression risk to an already-merged, already-tested
// module. Reporter instead re-adjudicates *failing* regression results
// through the allowlist purely for its own classification/PR-comment
// output — `compare.dart`'s exit code is unchanged by this file.
import 'dart:typed_data';

import '../baseline/baseline_store.dart';
import '../baseline/parity_platform.dart';
import '../baseline/parity_signal.dart';
import '../diff/comparator.dart';
import '../diff/pixel_diff.dart';
import 'classified_failure.dart';
import 'failure_category.dart';

/// Classifies [result] into zero or more [ClassifiedFailure]s.
///
/// A single [ComparisonResult] can fail more than one independent check at
/// once (e.g. Web's own regression AND the cross-platform parity check can
/// both be over threshold) — each failing check becomes its own
/// [ClassifiedFailure] so the PR comment lists every distinct cause rather
/// than collapsing them into one.
///
/// [baselineStore]/[now]/the captured PNG bytes are supplied only to
/// re-check pixel-*regression* failures against the allowlist
/// (`allowlist-expired` vs plain `regression`, or dropped entirely when
/// the allowlist has an [BaselineOutcome.approvedChange] for exactly this
/// capture). Omit them (leave `baselineStore` `null`) to classify without
/// that reconciliation — every regression failure is then reported as
/// plain `regression`.
List<ClassifiedFailure> classifyComparisonResult(
  ComparisonResult result, {
  BaselineStore? baselineStore,
  Uint8List? flutterCapturedPng,
  Uint8List? webCapturedPng,
  DateTime? now,
}) {
  final failures = <ClassifiedFailure>[];

  final propertyDiff = result.propertyDiff;
  final propertyHasFailures = propertyDiff != null && propertyDiff.hasFailures;
  if (propertyHasFailures) {
    failures.add(
      ClassifiedFailure(
        category: .parityProperty,
        key: result.key,
        probeRole: result.probeRole,
        summary: propertyDiff.describeFailures(),
        diffArtifactPaths: [
          '${result.key}.${result.probeRole}.property.diff.json',
        ],
      ),
    );
  }

  ClassifiedFailure? classifyRegression({
    required PixelDiffResult? diff,
    required ParityPlatform platform,
    required Uint8List? capturedBytes,
    required String label,
  }) {
    if (diff == null || diff.passed) return null;

    var category = FailureCategory.regression;
    // 첫 줄은 한 줄 요약(`$diff` — ratio·threshold·verdict), 그 아래
    // describe() 의 리포트-형식 블록(해상도 · 픽셀 diff 통계 · 주요 변화).
    // `ParityReport.consoleSummary()` 가 summary 의 **첫 줄만** 출력하므로,
    // 첫 줄이 라벨뿐이면 콘솔 요약이 무정보가 된다.
    var summary = '$label: $diff\n${diff.describe()}';
    String? allowlistHint;

    if (baselineStore != null && capturedBytes != null) {
      final fingerprint = BaselineStore.fingerprintOfBytes(capturedBytes);
      final verdict = baselineStore.evaluate(
        key: result.key,
        platform: platform,
        signal: .pixel,
        capturedFingerprint: fingerprint,
        now: now ?? DateTime.now(),
      );
      if (verdict.outcome == BaselineOutcome.approvedChange) {
        // 승인된 의도적 변경 — 실패로 보고하지 않는다.
        return null;
      }
      if (verdict.outcome == BaselineOutcome.allowlistExpired) {
        category = .allowlistExpired;
      }
      summary = '$label: $diff\n${diff.describe()}\n${verdict.reason}';
      allowlistHint = _allowlistHint(
        key: result.key,
        signal: .pixel,
        fingerprint: fingerprint,
      );
    }

    return ClassifiedFailure(
      category: category,
      key: result.key,
      probeRole: result.probeRole,
      summary: summary,
      diffArtifactPaths: diff.diffImageBytes != null
          ? ['${result.key}.${result.probeRole}.$label.diff.png']
          : const [],
      allowlistHint: allowlistHint,
      platform: platform,
    );
  }

  final flutterRegressionFailure = classifyRegression(
    diff: result.flutterRegression,
    platform: .flutter,
    capturedBytes: flutterCapturedPng,
    label: 'flutter-regression',
  );
  if (flutterRegressionFailure != null) failures.add(flutterRegressionFailure);

  final webRegressionFailure = classifyRegression(
    diff: result.webRegression,
    platform: .web,
    capturedBytes: webCapturedPng,
    label: 'web-regression',
  );
  if (webRegressionFailure != null) failures.add(webRegressionFailure);

  final crossPlatformParity = result.crossPlatformParity;
  if (crossPlatformParity != null && !crossPlatformParity.passed) {
    var summary = 'parity: $crossPlatformParity';
    if (propertyDiff == null) {
      summary += '\n속성 비교는 실행하지 않았습니다.';
    } else if (!propertyHasFailures) {
      // A measured property pass does not identify the pixel difference's
      // cause; geometry and paint still need their own inspection.
      summary += '\n측정한 속성 비교는 통과했습니다. 픽셀 차이의 원인은 별도로 확인해야 합니다.';
    }
    failures.add(
      ClassifiedFailure(
        category: .parityPixel,
        key: result.key,
        probeRole: result.probeRole,
        summary: summary,
        diffArtifactPaths: crossPlatformParity.diffImageBytes != null
            ? ['${result.key}.${result.probeRole}.parity.diff.png']
            : const [],
      ),
    );
  }

  return failures;
}

String _allowlistHint({
  required String key,
  required ParitySignal signal,
  required String fingerprint,
}) =>
    '- key: $key\n'
    '  signal: ${signal.wireName}\n'
    '  fingerprint: $fingerprint\n'
    '  reason: <왜 이 변경을 승인하는지>\n'
    '  expires: <YYYY-MM-DD>';
