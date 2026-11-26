import '../baseline/parity_platform.dart';
import 'failure_category.dart';

/// One classified parity failure — the unit `report.dart` (#3617) counts,
/// groups, and renders into the console summary / PR comment.
class ClassifiedFailure {
  const ClassifiedFailure({
    required this.category,
    required this.key,
    required this.probeRole,
    required this.summary,
    this.diffArtifactPaths = const [],
    this.allowlistHint,
    this.platform,
  });

  final FailureCategory category;

  /// Matrix key (`card-outlined-dark-neoBrutalism`) for pixel/property
  /// failures, or the motion probe's test name for motion failures.
  final String key;

  /// Probe role (`root`) for pixel/property failures, `''` for motion
  /// failures — motion probes name a `test()`, not a probe role.
  final String probeRole;

  /// Human-readable cause — what a developer reads in the PR comment
  /// without re-running anything (#3617 완료 정의: "실패 건이 재실행 없이
  /// 코멘트만으로 원인 파악 가능").
  final String summary;

  /// Paths (relative to the diff output dir compare.dart already wrote to)
  /// of diff PNGs this failure produced, empty when there is none (a
  /// property-only or motion failure has no pixel diff image).
  final List<String> diffArtifactPaths;

  /// For [FailureCategory.regression]/[FailureCategory.allowlistExpired]
  /// only — the exact `allowlist.yaml` entry a reviewer would add to
  /// approve this change, with the real fingerprint already filled in.
  /// `null` for every other category (property/pixel-parity failures
  /// aren't a single-platform artifact an allowlist entry names the same
  /// way, and motion probes aren't a `ParitySignal`-addressable artifact
  /// yet).
  final String? allowlistHint;

  /// Which platform's own-baseline comparison failed — set only for
  /// [FailureCategory.regression]/[FailureCategory.allowlistExpired]
  /// (regression is inherently single-platform). `null` for every other
  /// category: a cross-platform property/pixel mismatch belongs to both
  /// platforms at once, and a motion failure carries the platform in its
  /// [key] prefix instead. The regression summary (`regression_summary.
  /// dart`) matches failures back to their (key, platform) cell through
  /// this field.
  final ParityPlatform? platform;
}
