// #3617 — shared captured-artifact loader for one (entry, probeRole).
//
// Extracted out of `compare.dart` (#3607) unchanged (same file naming
// convention, same normalization calls) so `report.dart` (#3617) can load
// exactly what `compare.dart` loads without a second copy of the
// convention drifting from the first. `compare.dart` now calls this same
// function — there is exactly one place that knows the captured-artifact
// file-naming convention.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../baseline/baseline_store.dart';
import '../diff/comparator.dart';
import '../diff/pixel_diff.dart';
import '../model/capture_body.dart';
import '../model/matrix_entry.dart';
import '../model/property_snapshot.dart';
import '../normalize/web_property_normalizer.dart';

/// Thrown when a required captured artifact is missing — an infra failure
/// (`ParityExitCode.infraFailed`), not a comparison failure. A missing
/// artifact is not the same fact as "the artifact differs", and NFR-002's
/// false-positive tracking needs the two kept apart.
class InfraFailure implements Exception {
  const InfraFailure(this.message);

  final String message;

  @override
  String toString() => 'InfraFailure: $message';
}

/// Flutter 캡처의 구조적 root-생략 마커 값 — 캡처가 `rootOmitted` 필드에
/// 이 리터럴을 쓰면 "root 스냅샷이 *설계된 형태* 때문에 비었다"(multi-slot
/// root 라 chrome walk 이 형제 간 추측을 거부(#3904)했고 root 소유 텍스트도
/// 없음)는 뜻이다. `flutter_capture_matrix_test.dart` 가 쓰는 리터럴과
/// 같아야 한다.
const String kRootOmittedNoChrome = 'no-root-chrome';

/// Whatever [ComparisonSignal] needs for one (entry, probeRole), loaded
/// from disk.
class EntryLoadResult {
  const EntryLoadResult({
    this.flutterProperty,
    this.webProperty,
    this.flutterPng,
    this.flutterBaselinePng,
    this.webPng,
    this.webBaselinePng,
    this.propertyStructuralSkipReason,
  });

  final PropertySnapshot? flutterProperty;
  final PropertySnapshot? webProperty;
  final Uint8List? flutterPng;
  final Uint8List? flutterBaselinePng;
  final Uint8List? webPng;
  final Uint8List? webBaselinePng;

  /// Non-null when the Flutter capture declared a structural root omission
  /// ([kRootOmittedNoChrome]) — the property comparison for this (entry,
  /// probeRole) is skipped as a fact about the component's shape, **not**
  /// an [InfraFailure]: the pipeline is healthy, there is simply no root
  /// chrome/text to compare. Callers keep the pixel signal running (the
  /// PNGs are real) and count these separately from infra skips — lumping
  /// them together buried genuine pipeline breaks inside a constant
  /// baseline of designed shapes.
  final String? propertyStructuralSkipReason;
}

/// Loads whatever [signal] needs for one (entry, probeRole) from
/// [capturedDir]/[baselineStore]. Property values come from each
/// platform's `<key>.<platform>.json` — Web's is raw `getComputedStyle()`
/// strings (normalized here via [normalizeWebSnapshot]); Flutter's is
/// expected to already be `PropertySnapshot.toJson()`-shaped per role
/// (Component ②/FlutterCaptureBackend, #3376, normalizes in-process before
/// writing — see `flutter_property_normalizer.dart`'s own doc comment on
/// why that normalization can't happen here in a pure-Dart CLI).
EntryLoadResult loadEntry({
  required MatrixEntry entry,
  required String probeRole,
  required ComparisonSignal signal,
  required Directory capturedDir,
  required BaselineStore baselineStore,
}) {
  PropertySnapshot? flutterProperty;
  PropertySnapshot? webProperty;
  String? propertyStructuralSkipReason;
  if (signal.includesProperty) {
    // Flutter 를 먼저 — 구조적 생략이면 property 비교 자체가 성립하지
    // 않으므로 Web property 를 요구하지 않는다 (Web json 부재는 그때도
    // 픽셀 로딩이 잡는다).
    propertyStructuralSkipReason = flutterStructuralSkipReason(
      key: entry.key,
      capturedDir: capturedDir,
      probeRole: probeRole,
    );
    if (propertyStructuralSkipReason == null) {
      webProperty = loadWebPropertySnapshot(
        key: entry.key,
        capturedDir: capturedDir,
        probeRole: probeRole,
      );
      flutterProperty = loadFlutterPropertySnapshot(
        key: entry.key,
        capturedDir: capturedDir,
        probeRole: probeRole,
      );
    }
  }

  Uint8List? flutterPng;
  Uint8List? webPng;
  Uint8List? flutterBaselinePng;
  Uint8List? webBaselinePng;
  if (signal.includesPixel) {
    final artifactKey = pixelArtifactKey(entry.key, probeRole);
    flutterPng = readCapturedPng(
      File('${capturedDir.path}/$artifactKey.flutter.png'),
    );
    webPng = readCapturedPng(File('${capturedDir.path}/$artifactKey.web.png'));

    final flutterBaselineFile = baselineStore.baselineFile(
      key: artifactKey,
      platform: .flutter,
      signal: .pixel,
    );
    final webBaselineFile = baselineStore.baselineFile(
      key: artifactKey,
      platform: .web,
      signal: .pixel,
    );
    flutterBaselinePng = flutterBaselineFile.existsSync()
        ? flutterBaselineFile.readAsBytesSync()
        : null;
    webBaselinePng = webBaselineFile.existsSync()
        ? webBaselineFile.readAsBytesSync()
        : null;
  }

  return EntryLoadResult(
    flutterProperty: flutterProperty,
    webProperty: webProperty,
    flutterPng: flutterPng,
    flutterBaselinePng: flutterBaselinePng,
    webPng: webPng,
    webBaselinePng: webBaselinePng,
    propertyStructuralSkipReason: propertyStructuralSkipReason,
  );
}

/// [kRootOmittedNoChrome] 마커 검사 — Flutter 캡처가 (probeRole 을 생략한
/// 채) 구조적 생략을 선언했으면 그 사유 문자열을, 아니면 `null` 을 낸다.
///
/// 파일 부재/파싱 실패는 여기서 판정하지 않는다(`null` 반환) — 그 사실은
/// 곧이어 도는 [loadFlutterPropertySnapshot] 또는 픽셀 로딩이 원래의
/// [InfraFailure] 로 보고한다. 이 함수는 "role 이 없는 이유가 설계인가" 만
/// 답한다.
String? flutterStructuralSkipReason({
  required String key,
  required Directory capturedDir,
  required String probeRole,
}) {
  final file = File('${capturedDir.path}/$key.flutter.json');
  if (!file.existsSync()) return null;

  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  if (decoded['rootOmitted'] != kRootOmittedNoChrome) return null;

  final byRole = decoded['byRole'];
  final hasRole = byRole is Map && byRole[probeRole] != null;
  // 마커가 있어도 role 이 실제로 존재하면 생략이 아니다 — 방어적으로
  // 정상 로딩 경로를 태운다.
  if (hasRole) return null;

  return '$key/$probeRole: Flutter root 스냅샷이 구조적으로 비어 property '
      '비교를 건너뜀 (root 소유 chrome/텍스트 없음 — 설계된 형태, 인프라 '
      '실패 아님). 픽셀 회귀는 계속 실행됨.';
}

Uint8List readCapturedPng(File file) {
  if (!file.existsSync()) {
    throw InfraFailure('캡처 파일을 찾지 못함: ${file.path}');
  }
  return file.readAsBytesSync();
}

/// Runs [decode] and folds a malformed-capture failure into an
/// [InfraFailure] scoped to this one (entry, role) — shared by
/// [loadWebPropertySnapshot] and [loadFlutterPropertySnapshot] so the
/// isolation boundary lives in exactly one place instead of drifting
/// between the two platforms the way #3860 found it had: the Web loader
/// caught `normalizeWebSnapshot`'s own `FormatException` (#3852) but not
/// the `jsonDecode` call one line above it, and the Flutter loader had no
/// try/catch at all — a corrupted Flutter capture threw an uncaught
/// `TypeError` straight out of `main()` and killed the whole run (exit
/// 255) instead of being isolated to its own cell.
///
/// Catch scope, chosen deliberately rather than "catch everything":
/// - `FormatException` — `jsonDecode`/`readAsStringSync` on invalid JSON
///   syntax, non-UTF8 bytes, or an empty file, and `normalizeWebSnapshot`'s
///   CSS-value parsers on a raw computed-style string they don't recognize
///   (#3852's original case).
/// - `TypeError` — every field read here and in
///   `PropertySnapshot.fromJson`/`NormalizedColor.fromJson`/
///   `FourSidePx.fromJson` goes through an `as` cast or a `!` null-check
///   operator — that's how this codebase asserts "the JSON has the shape I
///   expect" — so a syntactically-valid but wrong-shaped capture (a string
///   where a map was expected, a field of the wrong type) fails as
///   `TypeError`. This is the exact type #3860's measured Flutter repro hit.
///
/// Deliberately *not* caught: anything else — a `RangeError` from a
/// too-short array, a `StateError`/`ArgumentError` a real bug in the
/// normalizer would throw, an `Error` like `StackOverflowError`. Those
/// aren't "this one artifact is bad", they're "this code is bad"; folding
/// them into the same per-entry bucket would print a plausible "❌
/// card/root: ..." line for a bug that may be corrupting every entry, not
/// just this one, and let the run end looking clean instead of surfacing
/// the bug loudly. A one-cell parsing gap and a whole-run crash are
/// different severities on purpose.
T _isolateEntryParseFailure<T>({
  required String key,
  required String probeRole,
  required String platformLabel,
  required T Function() decode,
}) {
  try {
    return decode();
  } on FormatException catch (e) {
    throw InfraFailure(
      '$key/$probeRole 의 $platformLabel 캡처 파싱 실패: ${e.message}',
    );
  }
  // `TypeError` here is untrusted-disk-input validation, not a programming
  // bug (see the doc comment above) — `tool/parity/manifest.dart` ignores
  // the same lint for the same reason.
  // ignore: avoid_catching_errors
  on TypeError catch (e) {
    throw InfraFailure('$key/$probeRole 의 $platformLabel 캡처 형식이 예상과 다름: $e');
  }
}

PropertySnapshot loadWebPropertySnapshot({
  required String key,
  required Directory capturedDir,
  required String probeRole,
}) {
  final file = File('${capturedDir.path}/$key.web.json');
  if (!file.existsSync()) {
    throw InfraFailure('Web 속성 캡처를 찾지 못함: ${file.path}');
  }
  return _isolateEntryParseFailure(
    key: key,
    probeRole: probeRole,
    platformLabel: 'Web',
    decode: () {
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final byRole = decoded['byRole']! as Map<String, Object?>;
      final raw = byRole[probeRole];
      if (raw == null) {
        throw InfraFailure('$key 의 Web 캡처에 "$probeRole" 역할이 없음.');
      }
      return normalizeWebSnapshot(
        (raw as Map).cast(),
        key: key,
        probeRole: probeRole,
      );
    },
  );
}

PropertySnapshot loadFlutterPropertySnapshot({
  required String key,
  required Directory capturedDir,
  required String probeRole,
}) {
  final file = File('${capturedDir.path}/$key.flutter.json');
  if (!file.existsSync()) {
    throw InfraFailure(
      'Flutter 속성 캡처를 찾지 못함: ${file.path} — FlutterCaptureBackend '
      '(#3376) 가 아직 이 (component, variant, theme, surfaceStyle) 조합을 '
      '캡처하지 않았을 수 있다.',
    );
  }
  return _isolateEntryParseFailure(
    key: key,
    probeRole: probeRole,
    platformLabel: 'Flutter',
    decode: () {
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final byRole = decoded['byRole']! as Map<String, Object?>;
      final raw = byRole[probeRole];
      if (raw == null) {
        throw InfraFailure('$key 의 Flutter 캡처에 "$probeRole" 역할이 없음.');
      }
      return PropertySnapshot.fromJson((raw as Map).cast());
    },
  );
}

/// Parses `--mode=regression|parity|both` into the [PixelDiffMode] set it
/// selects — shared by `compare.dart` and `report.dart` so the flag's
/// meaning cannot drift between the two entrypoints.
Set<PixelDiffMode>? parsePixelModesFlag(String? raw) {
  switch (raw ?? 'both') {
    case 'regression':
      return {.regression};
    case 'parity':
      return {.parity};
    case 'both':
      return kAllPixelModes;
    default:
      return null;
  }
}
