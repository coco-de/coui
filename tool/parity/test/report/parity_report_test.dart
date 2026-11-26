import 'package:test/test.dart';

import '../../src/diff/property_diff.dart';
import '../../src/report/classified_failure.dart';
import '../../src/report/failure_category.dart';
import '../../src/report/parity_report.dart';

PropertyDiffResult _diffResult(
  String key, {
  String probeRole = 'root',
  required List<FieldDivergence> fields,
}) => PropertyDiffResult(key: key, probeRole: probeRole, fields: fields);

const _matchingFontWeight = FieldDivergence(
  field: 'fontWeight',
  matches: true,
  flutterDescription: '400',
  webDescription: '400',
);
const _mismatchingFontWeight = FieldDivergence(
  field: 'fontWeight',
  matches: false,
  flutterDescription: '600',
  webDescription: '400',
);
const _matchingColor = FieldDivergence(
  field: 'color',
  matches: true,
  flutterDescription: 'c1',
  webDescription: 'c1',
);

void main() {
  group('ParityReport — #3861 field-level mismatch aggregation', () {
    test('comparablePropertyCount counts every propertyDiffs entry', () {
      final report = ParityReport(
        failures: const [],
        passedCount: 2,
        infraFailedCount: 0,
        durationMs: 100,
        propertyDiffs: [
          _diffResult('a', fields: [_matchingFontWeight, _matchingColor]),
          _diffResult('b', fields: [_mismatchingFontWeight, _matchingColor]),
        ],
      );

      expect(report.comparablePropertyCount, 2);
    });

    test(
      'fieldMismatchCounts tallies mismatches per field, every '
      'PropertyField present even at 0',
      () {
        final report = ParityReport(
          failures: const [],
          passedCount: 0,
          infraFailedCount: 0,
          durationMs: 100,
          propertyDiffs: [
            _diffResult('a', fields: [_mismatchingFontWeight, _matchingColor]),
            _diffResult('b', fields: [_mismatchingFontWeight, _matchingColor]),
            _diffResult('c', fields: [_matchingFontWeight, _matchingColor]),
          ],
        );

        final counts = report.fieldMismatchCounts;
        expect(counts['fontWeight'], 2);
        expect(counts['color'], 0);
        // 어떤 PropertyDiffResult 도 언급하지 않은 필드(예: opacity)도
        // 0 으로 존재 — 호출자가 null-check 없이 순회할 수 있어야 한다.
        expect(counts['opacity'], 0);
      },
    );

    test('infraSkippedKeys is a list, not just a bare count', () {
      const report = ParityReport(
        failures: [],
        passedCount: 0,
        infraFailedCount: 2,
        durationMs: 100,
        infraSkippedKeys: ['dialog-outlined-light-flat/root', 'swiper-x/root'],
      );

      expect(report.infraSkippedKeys, hasLength(2));
      expect(
        report.infraSkippedKeys,
        containsAll(['dialog-outlined-light-flat/root', 'swiper-x/root']),
      );
    });
  });

  group('ParityReport — toJson/fromJson round trip (#3861)', () {
    test('round-trips passedCount/infraFailedCount/durationMs/keys/diffs', () {
      final report = ParityReport(
        failures: const [
          ClassifiedFailure(
            category: FailureCategory.regression,
            key: 'card',
            probeRole: 'root',
            summary: '실패는 round-trip 되지 않는다',
          ),
        ],
        passedCount: 5,
        infraFailedCount: 1,
        durationMs: 4321,
        infraSkippedKeys: const ['dialog-x/root'],
        structuralSkippedKeys: const ['star-rating-x/root'],
        propertyDiffs: [
          _diffResult('a', fields: [_mismatchingFontWeight, _matchingColor]),
        ],
      );

      final decoded = ParityReport.fromJson(report.toJson());

      expect(decoded.passedCount, 5);
      expect(decoded.infraFailedCount, 1);
      expect(decoded.durationMs, 4321);
      expect(decoded.infraSkippedKeys, ['dialog-x/root']);
      expect(decoded.structuralSkippedKeys, ['star-rating-x/root']);
      expect(decoded.comparablePropertyCount, 1);
      expect(decoded.fieldMismatchCounts['fontWeight'], 1);
      // failures 는 의도적으로 round-trip 되지 않는다 (toJson 의 doc
      // comment 참조 — 이건 다른 실행의 비교 도구를 위한 입력이지 이 실행
      // 자체의 완전한 복원이 아니다).
      expect(decoded.failures, isEmpty);
    });

    test('structuralSkippedKeys 부재(구 report JSON)는 빈 목록으로 읽는다', () {
      final json = const ParityReport(
        failures: [],
        passedCount: 1,
        infraFailedCount: 0,
        durationMs: 10,
      ).toJson()..remove('structuralSkippedKeys');
      expect(ParityReport.fromJson(json).structuralSkippedKeys, isEmpty);
    });
  });

  group('ParityReport — no failures', () {
    test('toMarkdownComment is null (완료 정의: 실패 0건 시 코멘트 미게시)', () {
      const report = ParityReport(
        failures: [],
        passedCount: 12,
        infraFailedCount: 0,
        durationMs: 4200,
      );

      expect(report.hasFailures, isFalse);
      expect(report.toMarkdownComment(), isNull);
    });

    test('consoleSummary still reports passed count + duration (NFR-001)', () {
      const report = ParityReport(
        failures: [],
        passedCount: 12,
        infraFailedCount: 0,
        durationMs: 4200,
      );

      final summary = report.consoleSummary();
      expect(summary, contains('12 passed'));
      expect(summary, contains('4200ms'));
    });
  });

  group('ParityReport — with failures', () {
    const failures = [
      ClassifiedFailure(
        category: FailureCategory.regression,
        key: 'card-outlined-light-neoBrutalism',
        probeRole: 'root',
        summary: 'flutter-regression: PixelDiffResult(regression, 2.0% ...)',
        diffArtifactPaths: [
          'card-outlined-light-neoBrutalism.root.flutter-regression.diff.png',
        ],
        allowlistHint:
            '- key: card-outlined-light-neoBrutalism\n  signal: pixel\n'
            '  fingerprint: abc123\n  reason: <>\n  expires: <>',
      ),
      ClassifiedFailure(
        category: FailureCategory.motionMissing,
        key: 'flutter: Dialog enter animates opacity',
        probeRole: '',
        summary: 'jumped straight from 0.0 to 1.0 ...',
      ),
    ];

    const report = ParityReport(
      failures: failures,
      passedCount: 3,
      infraFailedCount: 1,
      durationMs: 9000,
    );

    test('groups by every category, including empty ones', () {
      final grouped = report.byCategory;
      expect(grouped.keys, containsAll(FailureCategory.values));
      expect(grouped[FailureCategory.regression], hasLength(1));
      expect(grouped[FailureCategory.motionMissing], hasLength(1));
      expect(grouped[FailureCategory.parityProperty], isEmpty);
    });

    test('consoleSummary lists every category with a nonzero count', () {
      final summary = report.consoleSummary();
      expect(summary, contains('regression (1)'));
      expect(summary, contains('motion-missing (1)'));
      expect(summary, contains('2 failed'));
      expect(summary, contains('1 infra-skipped'));
    });

    test('toMarkdownComment includes diff link + allowlist hint', () {
      final comment = report.toMarkdownComment();
      expect(comment, isNotNull);
      expect(comment, contains('regression'));
      expect(comment, contains('motion-missing'));
      expect(
        comment,
        contains(
          'card-outlined-light-neoBrutalism.root.flutter-regression.diff.png',
        ),
      );
      expect(comment, contains('allowlist.yaml'));
      expect(comment, contains('abc123'));
    });

    test(
      'toMarkdownComment header includes infraFailedCount (#3861 — '
      'parity_report.dart:74-79 이 누락하던 값)',
      () {
        final comment = report.toMarkdownComment();
        expect(comment, isNotNull);
        final header = comment!.split('\n').first;
        expect(header, contains('2건 실패'));
        expect(header, contains('1건 인프라 스킵'));
      },
    );
  });
}
