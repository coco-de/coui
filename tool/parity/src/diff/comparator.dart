// #3607 — Comparator orchestration: ties PropertyDiff (1st signal) and
// PixelDiff (2nd signal) together per `.bmad/architecture-*.md` Component
// ⑤'s completion definition — independent `--signal=` selection, the
// property-failure short-circuit, and baseline-aware regression skip. The
// signals' own comparison math lives in `property_diff.dart`/
// `pixel_diff.dart`; this file only decides *which* of them run and *why*.
import 'dart:typed_data';

import '../model/property_field.dart';
import '../model/property_snapshot.dart';
import 'pixel_diff.dart';
import 'property_diff.dart';

/// Which signal(s) a comparison run computes — the CLI's `--signal=`
/// values, `both` being the default.
enum ComparisonSignal {
  property('property'),
  pixel('pixel'),
  both('both');

  const ComparisonSignal(this.wireName);

  final String wireName;

  bool get includesProperty => this != .pixel;
  bool get includesPixel => this != .property;

  /// `null` for an unrecognized value — the CLI decides how to report
  /// that (same convention as `ParitySignal.tryParse`).
  static ComparisonSignal? tryParse(String raw) {
    for (final signal in ComparisonSignal.values) {
      if (signal.wireName == raw) return signal;
    }
    return null;
  }
}

/// All comparison output for one (key, probeRole) — property and however
/// much of pixel actually ran.
class ComparisonResult {
  const ComparisonResult({
    required this.key,
    required this.probeRole,
    this.propertyDiff,
    this.flutterRegression,
    this.webRegression,
    this.crossPlatformParity,
    this.pixelSkippedReason,
    this.paritySkippedReason,
  });

  final String key;
  final String probeRole;

  /// `null` only when [ComparisonSignal.pixel] was requested (property
  /// wasn't computed at all, not "computed and passed").
  final PropertyDiffResult? propertyDiff;

  /// Flutter's this-run PNG vs its own committed baseline. `null` when no
  /// Flutter baseline exists yet (first capture — regression skipped by
  /// design, not a comparison that happened to pass) or pixel wasn't run.
  final PixelDiffResult? flutterRegression;

  /// Same as [flutterRegression], for Web.
  final PixelDiffResult? webRegression;

  /// This run's Flutter PNG vs this run's Web PNG. `null` when pixel
  /// wasn't run at all ([pixelSkippedReason]), when `--mode=` excluded
  /// parity, or when a property failure short-circuited it
  /// ([paritySkippedReason]).
  final PixelDiffResult? crossPlatformParity;

  /// Non-null (and every pixel field above `null`) when pixel comparison
  /// was skipped entirely because [ComparisonSignal.property] excluded it.
  final String? pixelSkippedReason;

  /// Non-null when the cross-platform parity pixel check specifically was
  /// short-circuited by a property failure — the "속성 실패 시 픽셀 비교
  /// 스킵" optimization, scoped to parity only. A cross-platform property
  /// mismatch already identifies why the two platforms' pixels differ, so
  /// re-measuring that as a parity diff adds cost without information.
  /// The same reasoning does **not** transfer to the own-baseline
  /// regression checks — "두 플랫폼이 서로 다른가" 와 "이 플랫폼이 자기
  /// baseline 과 다른가" 는 독립된 질문이라, regression 은 property 가
  /// 실패해도 계속 돈다 (그렇지 않으면 property 실패가 있는 컴포넌트는
  /// 시각 회귀 커버리지를 조용히 잃는다).
  final String? paritySkippedReason;

  /// The overall verdict — every signal that *did* run must have passed.
  /// A skipped signal contributes no failure of its own.
  bool get passed {
    if (propertyDiff != null && propertyDiff!.hasFailures) return false;
    if (flutterRegression != null && !flutterRegression!.passed) return false;
    if (webRegression != null && !webRegression!.passed) return false;
    if (crossPlatformParity != null && !crossPlatformParity!.passed) {
      return false;
    }
    return true;
  }
}

/// Every [PixelDiffMode] — the default when a caller doesn't need to
/// restrict which pixel comparisons run (the CLI's `--mode=both`).
const Set<PixelDiffMode> kAllPixelModes = {
  PixelDiffMode.regression,
  PixelDiffMode.parity,
};

/// Runs whichever of PropertyDiff/PixelDiff [signal] calls for on one
/// (key, probeRole), applying the property-failure short-circuit and
/// baseline-aware regression skip.
///
/// [propertyFields] declares which normalized fields this role expects. It is
/// validated only when the property signal runs; pixel-only declarations may
/// be empty. Existing direct callers compare all fields by default.
///
/// [pixelModes] further restricts *which* pixel comparisons run within
/// [signal] (the CLI's `--mode=regression|parity|both`, independent of
/// `--signal=`) — [PixelDiffMode.regression] excluded from [pixelModes]
/// suppresses both platforms' regression checks regardless of whether a
/// baseline exists; [PixelDiffMode.parity] excluded suppresses the
/// cross-platform check. It has no effect on PropertyDiff, which has no
/// regression/parity distinction of its own.
///
/// [flutterBaselinePng]/[webBaselinePng] being `null` means "no baseline
/// committed for this platform yet" (`BaselineStore.hasBaseline` says
/// `firstCapture`) — regression is skipped for that platform specifically,
/// not for the whole comparison; the other platform's regression and the
/// cross-platform parity check still run independently.
ComparisonResult compareEntry({
  required String key,
  required String probeRole,
  required ComparisonSignal signal,
  PropertySnapshot? flutterProperty,
  PropertySnapshot? webProperty,
  PropertySnapshot? expectedProperty,
  Set<PropertyField> propertyFields = PropertyField.all,
  Uint8List? flutterPng,
  Uint8List? flutterBaselinePng,
  Uint8List? webPng,
  Uint8List? webBaselinePng,
  Set<PixelDiffMode> pixelModes = kAllPixelModes,
}) {
  PropertyDiffResult? propertyDiff;
  if (signal.includesProperty) {
    if (flutterProperty == null || webProperty == null) {
      throw ArgumentError(
        '$key/$probeRole: signal이 property를 포함하는데 '
        'flutterProperty/webProperty 중 하나가 없다.',
      );
    }
    propertyDiff = comparePropertySnapshots(
      flutter: flutterProperty,
      web: webProperty,
      expected: expectedProperty,
      requestedFields: propertyFields,
    );
  }

  if (!signal.includesPixel) {
    return ComparisonResult(
      key: key,
      probeRole: probeRole,
      propertyDiff: propertyDiff,
      pixelSkippedReason: 'signal=${signal.wireName} — pixel 제외.',
    );
  }

  if (flutterPng == null || webPng == null) {
    throw ArgumentError(
      '$key/$probeRole: signal이 pixel을 포함하는데 flutterPng/webPng 중 '
      '하나가 없다.',
    );
  }

  final propertyFailed = propertyDiff != null && propertyDiff.hasFailures;
  final runRegression = pixelModes.contains(PixelDiffMode.regression);
  // 속성 실패 short-circuit 은 **parity 픽셀에만** 적용된다 — 교차 플랫폼
  // 속성 불일치는 "왜 두 플랫폼 픽셀이 다른가" 를 이미 특정하므로 parity
  // 재측정은 정보가 없다. own-baseline regression 은 별개 질문(이 플랫폼
  // 렌더가 자기 baseline 과 같은가)이라 property 실패와 무관하게 돈다 —
  // 여기까지 스킵하면 property 실패가 있는 컴포넌트가 시각 회귀
  // 커버리지를 조용히 잃는다 ([ComparisonResult.paritySkippedReason]).
  final runParity =
      pixelModes.contains(PixelDiffMode.parity) && !propertyFailed;

  return ComparisonResult(
    key: key,
    probeRole: probeRole,
    propertyDiff: propertyDiff,
    // 인자 순서 = (baseline, 이번 캡처) — ColorTransition 이 "전 → 후" 로
    // 읽히게 하기 위해서다. 반대로 넘기면 "주요 변화: #신색 → #옛색" 이
    // 되어 리포트가 변화 방향을 거꾸로 말한다. diff ratio 자체는 대칭이라
    // 합격/불합격 판정에는 영향이 없다.
    flutterRegression: runRegression && flutterBaselinePng != null
        ? comparePixels(flutterBaselinePng, flutterPng, mode: .regression)
        : null,
    webRegression: runRegression && webBaselinePng != null
        ? comparePixels(webBaselinePng, webPng, mode: .regression)
        : null,
    crossPlatformParity: runParity
        ? comparePixels(flutterPng, webPng, mode: .parity)
        : null,
    paritySkippedReason:
        propertyFailed && pixelModes.contains(PixelDiffMode.parity)
        ? 'PropertyDiff 가 이미 실패 — 원인이 특정됐으므로 parity 픽셀 '
              '비교를 생략한다 (${propertyDiff.failures.length}개 필드 실패). '
              'own-baseline regression 은 별개 질문이라 계속 실행됨.'
        : null,
  );
}
