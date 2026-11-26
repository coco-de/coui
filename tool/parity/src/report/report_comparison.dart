// #3861 — computes a paired-intersection before/after comparison between
// two `ParityReport` runs, so "did this fix actually reduce field
// mismatches" is a tool's answer instead of someone rebuilding the sample
// by hand outside the repo (#3856's PR body table is the motivating
// example this closes: "이 처리가 도구가 아니라 사람 머릿속에 있었다").
//
// "Paired intersection" — restrict every count to `(entry, probeRole)`
// pairs that were *comparable in both runs* (had a property diff
// computed, not InfraFailure-skipped in either). Each run already
// excludes InfraFailure from its own numerator/denominator
// (`ParityReport.comparablePropertyCount`/`fieldMismatchCounts` only ever
// iterate `propertyDiffs`, never `infraSkippedKeys`) — but the two runs'
// *comparable sets* can still differ from each other (an entry newly
// InfraFailure-skipped in one run, or the manifest itself grew/shrank
// between runs). Comparing unrestricted before/after percentages against
// each other in that situation is comparing different denominators —
// restricting to the intersection is what makes the before/after counts
// below the same measurement taken twice.
import '../model/property_field.dart';
import 'parity_report.dart';

/// Fraction-to-percentage scale — named so `no-magic-number` doesn't flag
/// the bare `100` in `ReportComparison._percent`.
const int _kPercentScale = 100;

/// One [PropertyField]'s before/after mismatch counts, both counted over
/// the exact same paired set of keys ([ReportComparison.pairedCount]).
class FieldComparisonCounts {
  const FieldComparisonCounts({
    required this.field,
    required this.beforeMismatchCount,
    required this.afterMismatchCount,
  });

  /// `PropertyField.name` — the wire vocabulary `PropertyDiffResult.fields`
  /// already keys off.
  final String field;

  final int beforeMismatchCount;
  final int afterMismatchCount;
}

/// Everything [compareReports] computes for one before/after pair.
class ReportComparison {
  const ReportComparison({
    required this.beforeComparableCount,
    required this.afterComparableCount,
    required this.pairedCount,
    required this.perField,
    required this.newlyInfraSkipped,
    required this.newlyComparable,
  });

  /// The "before" run's own [ParityReport.comparablePropertyCount],
  /// unrestricted by the paired intersection — matches #3856's PR-body
  /// "전체 before=216 비교 가능".
  final int beforeComparableCount;

  /// Same, for "after" — matches #3856's "after=202 비교 가능".
  final int afterComparableCount;

  /// How many `key/probeRole` pairs were comparable in *both* runs — the
  /// denominator every [FieldComparisonCounts] entry uses (#3856's PR-body
  /// table used `n=200` for exactly this reason).
  final int pairedCount;

  /// Keyed by `PropertyField.name` — every [PropertyField] is present.
  final Map<String, FieldComparisonCounts> perField;

  /// `key/probeRole` pairs comparable in "before" that became
  /// InfraFailure-skipped in "after" — #3856's "16개 엔트리가 가짜
  /// 불일치 대신 정직하게 비교 불가로" claim, as a computed list instead
  /// of a claim nobody can re-check.
  final List<String> newlyInfraSkipped;

  /// The reverse: InfraFailure-skipped in "before", comparable in "after"
  /// — #3856's "slider 2개 엔트리가 처음으로 비교 가능해졌다" claim.
  final List<String> newlyComparable;

  /// One-glance markdown table in the same shape as #3856's PR-body table
  /// (`필드 | before | after`), so a reviewer sees the number a person
  /// previously had to compute by hand outside the repo.
  String toMarkdownTable() {
    final buffer = StringBuffer()
      ..writeln(
        '| 필드 | before ($beforeComparableCount comparable) | '
        'after ($afterComparableCount comparable) |',
      )
      ..writeln('|---|---|---|')
      ..writeln('paired n=$pairedCount');
    for (final field in PropertyField.values) {
      final counts = perField[field.name];
      if (counts == null) continue;
      buffer.writeln(
        '| ${field.name} '
        '| ${_percent(counts.beforeMismatchCount)}% '
        '(${counts.beforeMismatchCount}/$pairedCount) '
        '| ${_percent(counts.afterMismatchCount)}% '
        '(${counts.afterMismatchCount}/$pairedCount) |',
      );
    }
    if (newlyInfraSkipped.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          '${newlyInfraSkipped.length}건이 after 에서 새로 인프라 스킵됨 — '
          '${newlyInfraSkipped.join(', ')}',
        );
    }
    if (newlyComparable.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          '${newlyComparable.length}건이 after 에서 새로 비교 가능해짐 — '
          '${newlyComparable.join(', ')}',
        );
    }
    return buffer.toString();
  }

  String _percent(int mismatchCount) {
    if (pairedCount == 0) return '0.0';
    return (mismatchCount / pairedCount * _kPercentScale).toStringAsFixed(1);
  }
}

String _pairKey(String key, String probeRole) =>
    probeRole.isEmpty ? key : '$key/$probeRole';

/// Computes the paired-intersection before/after comparison #3856's PR
/// body did by hand — see this file's own top doc comment for why
/// "paired" (not each run's own unrestricted percentage) is the number
/// that's actually comparable across two runs.
ReportComparison compareReports({
  required ParityReport before,
  required ParityReport after,
}) {
  final beforeByKey = {
    for (final diff in before.propertyDiffs)
      _pairKey(diff.key, diff.probeRole): diff,
  };
  final afterByKey = {
    for (final diff in after.propertyDiffs)
      _pairKey(diff.key, diff.probeRole): diff,
  };

  final beforeKeys = beforeByKey.keys.toSet();
  final afterKeys = afterByKey.keys.toSet();
  final pairedKeys = beforeKeys.intersection(afterKeys);

  final beforeMismatch = <String, int>{};
  final afterMismatch = <String, int>{};
  for (final pairKey in pairedKeys) {
    for (final field in beforeByKey[pairKey]!.fields) {
      if (field.matches) continue;
      beforeMismatch.update(field.field, (v) => v + 1, ifAbsent: () => 1);
    }
    for (final field in afterByKey[pairKey]!.fields) {
      if (field.matches) continue;
      afterMismatch.update(field.field, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  final perField = <String, FieldComparisonCounts>{
    for (final field in PropertyField.values)
      field.name: FieldComparisonCounts(
        field: field.name,
        beforeMismatchCount: beforeMismatch[field.name] ?? 0,
        afterMismatchCount: afterMismatch[field.name] ?? 0,
      ),
  };

  final beforeOnlyKeys = beforeKeys.difference(afterKeys);
  final afterOnlyKeys = afterKeys.difference(beforeKeys);

  final newlyInfraSkipped = [
    for (final key in beforeOnlyKeys)
      if (after.infraSkippedKeys.contains(key)) key,
  ]..sort();
  final newlyComparable = [
    for (final key in afterOnlyKeys)
      if (before.infraSkippedKeys.contains(key)) key,
  ]..sort();

  return ReportComparison(
    beforeComparableCount: before.comparablePropertyCount,
    afterComparableCount: after.comparablePropertyCount,
    pairedCount: pairedKeys.length,
    perField: perField,
    newlyInfraSkipped: newlyInfraSkipped,
    newlyComparable: newlyComparable,
  );
}
