// #3861 — reproduces #3856's PR-body before/after table end-to-end through
// `compareReports`, proving the counting/pairing arithmetic this issue adds
// actually produces that PR's published numbers — not a plausible-looking
// approximation.
//
// Why this is a *constructed* reproduction, not a live re-capture: #3856's
// own adversarial re-verification needed 12 independent agents to rebuild
// the exact before/after arms (their "before" isn't a plain `git checkout`
// of the pre-fix commit — that commit's `entry_loader.dart` doesn't isolate
// the `color(srgb ...)` box-shadow parse crash the *same* commit also
// fixed, so literally checking it out and running the full T1 catalog
// crashes the whole run rather than producing 216 comparable entries; #3856
// only got there by selectively reverting just the probe/pin changes on top
// of the crash-isolation fix). Redoing that surgery is #3852's own scope,
// not #3861's ("비교기 로직도 범위 밖 — 이 이슈는 집계·보고다"), and the raw
// per-entry captures were never committed either (that's the exact gap
// #3861 exists to close for *future* before/after comparisons). So instead
// this test builds two `ParityReport`s whose `propertyDiffs`/
// `infraSkippedKeys` are shaped to reproduce the PR body's published
// ground truth exactly:
//
//   before(216 comparable; fontWeight/fontSizePx/lineHeightPx/
//   letterSpacingPx/color = 76/150/150/198/66) →
//   after(202 comparable; 44/106/106/176/64), paired n=200, 16 entries
//   newly infra-skipped (dialog×10 + navigation-menu×2 + swiper×2 +
//   swiper-sheet×2), 2 newly comparable (slider×2).
//
// If `compareReports` produces anything other than 38.0%/22.0% (fontWeight),
// 75.0%/53.0% (fontSizePx, lineHeightPx), 99.0%/88.0% (letterSpacingPx), or
// 33.0%/32.0% (color) from this input, the tool's arithmetic — not #3856's
// hand-tally — is what's wrong.
import 'package:test/test.dart';

import '../../src/diff/property_diff.dart';
import '../../src/model/property_field.dart';
import '../../src/report/parity_report.dart';
import '../../src/report/report_comparison.dart';

const _kPairedCount = 200;

// #3856's PR-body table, field name -> (before mismatch count, after
// mismatch count), all out of the same paired n=200.
const _kHeadlineCounts = {
  'fontWeight': (before: 76, after: 44),
  'fontSizePx': (before: 150, after: 106),
  'lineHeightPx': (before: 150, after: 106),
  'letterSpacingPx': (before: 198, after: 176),
  'color': (before: 66, after: 64),
};

// #3856: "16개 엔트리가 가짜 불일치 대신 정직하게 비교 불가로" — comparable
// in "before", InfraFailure-skipped in "after".
const _kNewlyInfraSkippedKeys = [
  'dialog-0/root',
  'dialog-1/root',
  'dialog-2/root',
  'dialog-3/root',
  'dialog-4/root',
  'dialog-5/root',
  'dialog-6/root',
  'dialog-7/root',
  'dialog-8/root',
  'dialog-9/root',
  'navigation-menu-0/root',
  'navigation-menu-1/root',
  'swiper-0/root',
  'swiper-1/root',
  'swiper-sheet-0/root',
  'swiper-sheet-1/root',
];

// #3856: "slider 2개 엔트리가 이번에 처음으로 비교 가능해졌다" —
// InfraFailure-skipped in "before", comparable in "after".
const _kNewlyComparableKeys = ['slider-0/root', 'slider-1/root'];

FieldDivergence _field(String name, {required bool mismatch}) =>
    FieldDivergence(
      field: name,
      matches: !mismatch,
      flutterDescription: 'flutter',
      webDescription: 'web',
    );

/// One `PropertyDiffResult` for a paired key at index [i] (`0..199`),
/// deriving each headline field's match/mismatch from whether [i] falls
/// under that field's [arm] mismatch count — the rest of `PropertyField`
/// always matches (#3856's PR body: "backgroundColor/border*/paddingPx 불변",
/// i.e. those aren't the fields this fix touched).
PropertyDiffResult _pairedDiff(int i, {required String arm}) {
  bool mismatchFor(String field) {
    final counts = _kHeadlineCounts[field]!;
    final n = arm == 'before' ? counts.before : counts.after;
    return i < n;
  }

  return PropertyDiffResult(
    key: 'paired-$i',
    probeRole: 'root',
    fields: [
      for (final field in PropertyField.values)
        _field(
          field.name,
          mismatch: _kHeadlineCounts.containsKey(field.name)
              ? mismatchFor(field.name)
              : false,
        ),
    ],
  );
}

PropertyDiffResult _unpairedDiff(String pairKey) {
  final parts = pairKey.split('/');
  return PropertyDiffResult(
    key: parts.first,
    probeRole: parts.length > 1 ? parts[1] : '',
    fields: [
      for (final field in PropertyField.values)
        _field(field.name, mismatch: false),
    ],
  );
}

void main() {
  final beforeReport = ParityReport(
    failures: const [],
    passedCount: 0,
    infraFailedCount: _kNewlyComparableKeys.length,
    durationMs: 0,
    propertyDiffs: [
      for (var i = 0; i < _kPairedCount; i++) _pairedDiff(i, arm: 'before'),
      for (final key in _kNewlyInfraSkippedKeys) _unpairedDiff(key),
    ],
    infraSkippedKeys: _kNewlyComparableKeys,
  );

  final afterReport = ParityReport(
    failures: const [],
    passedCount: 0,
    infraFailedCount: _kNewlyInfraSkippedKeys.length,
    durationMs: 0,
    propertyDiffs: [
      for (var i = 0; i < _kPairedCount; i++) _pairedDiff(i, arm: 'after'),
      for (final key in _kNewlyComparableKeys) _unpairedDiff(key),
    ],
    infraSkippedKeys: _kNewlyInfraSkippedKeys,
  );

  group('compareReports — #3856 reproduction', () {
    test('before/after comparable totals match the PR body (216/202)', () {
      expect(beforeReport.comparablePropertyCount, 216);
      expect(afterReport.comparablePropertyCount, 202);
    });

    test('paired intersection is exactly n=200', () {
      final comparison = compareReports(
        before: beforeReport,
        after: afterReport,
      );
      expect(comparison.beforeComparableCount, 216);
      expect(comparison.afterComparableCount, 202);
      expect(comparison.pairedCount, 200);
    });

    test(
      'per-field mismatch counts match the PR-body table exactly '
      '(76/150/150/198/66 → 44/106/106/176/64)',
      () {
        final comparison = compareReports(
          before: beforeReport,
          after: afterReport,
        );

        for (final entry in _kHeadlineCounts.entries) {
          final counts = comparison.perField[entry.key]!;
          expect(
            counts.beforeMismatchCount,
            entry.value.before,
            reason: '${entry.key} before mismatch count',
          );
          expect(
            counts.afterMismatchCount,
            entry.value.after,
            reason: '${entry.key} after mismatch count',
          );
        }
      },
    );

    test('fields the fix never touched stay at 0/0 (backgroundColor etc)', () {
      final comparison = compareReports(
        before: beforeReport,
        after: afterReport,
      );
      for (final field in PropertyField.values) {
        if (_kHeadlineCounts.containsKey(field.name)) continue;
        expect(comparison.perField[field.name]!.beforeMismatchCount, 0);
        expect(comparison.perField[field.name]!.afterMismatchCount, 0);
      }
    });

    test(
      '16 entries newly infra-skipped in after, 2 newly comparable '
      '(#3856: dialog×10 + navigation-menu×2 + swiper×2 + swiper-sheet×2 '
      "→ 'nothing to compare'; slider×2 → newly comparable)",
      () {
        final comparison = compareReports(
          before: beforeReport,
          after: afterReport,
        );
        expect(comparison.newlyInfraSkipped, hasLength(16));
        expect(
          comparison.newlyInfraSkipped,
          containsAll(_kNewlyInfraSkippedKeys),
        );
        expect(comparison.newlyComparable, hasLength(2));
        expect(comparison.newlyComparable, containsAll(_kNewlyComparableKeys));
      },
    );

    test('toMarkdownTable renders the exact percentages from the PR body', () {
      final comparison = compareReports(
        before: beforeReport,
        after: afterReport,
      );
      final table = comparison.toMarkdownTable();

      // fontWeight 38.0% (76/200) -> 22.0% (44/200)
      expect(table, contains('38.0% (76/200)'));
      expect(table, contains('22.0% (44/200)'));
      // fontSizePx/lineHeightPx 75.0% (150/200) -> 53.0% (106/200)
      expect(table, contains('75.0% (150/200)'));
      expect(table, contains('53.0% (106/200)'));
      // letterSpacingPx 99.0% (198/200) -> 88.0% (176/200)
      expect(table, contains('99.0% (198/200)'));
      expect(table, contains('88.0% (176/200)'));
      // color 33.0% (66/200) -> 32.0% (64/200)
      expect(table, contains('33.0% (66/200)'));
      expect(table, contains('32.0% (64/200)'));
      expect(table, contains('paired n=200'));
    });
  });
}
