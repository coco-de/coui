import '../diff/property_diff.dart';
import '../model/property_field.dart';
import 'classified_failure.dart';
import 'failure_category.dart';
import 'property_diff_codec.dart';

/// All classified failures from one `report.dart` run, plus the counts
/// its console summary / exit-code decision needs.
class ParityReport {
  const ParityReport({
    required this.failures,
    required this.passedCount,
    required this.infraFailedCount,
    required this.durationMs,
    this.propertyDiffs = const [],
    this.infraSkippedKeys = const [],
    this.structuralSkippedKeys = const [],
  });

  /// Reconstructs a [ParityReport] from [toJson]'s output — the input
  /// `report_comparison.dart` (#3861) reads to compute a paired
  /// intersection between two separate runs. [failures] doesn't
  /// round-trip (see [toJson]'s doc comment on why) — it comes back empty.
  factory ParityReport.fromJson(Map<String, Object?> json) => ParityReport(
    failures: const [],
    passedCount: json['passedCount']! as int,
    infraFailedCount: json['infraFailedCount']! as int,
    durationMs: json['durationMs']! as int,
    infraSkippedKeys: [
      for (final key in json['infraSkippedKeys']! as List) key as String,
    ],
    // 필드 도입 이전 실행이 쓴 report JSON 과의 paired 비교
    // (`compare_reports.dart`)가 깨지지 않도록 부재를 빈 목록으로 읽는다.
    structuralSkippedKeys: [
      for (final key
          in (json['structuralSkippedKeys'] ?? const <Object?>[]) as List)
        key as String,
    ],
    propertyDiffs: [
      for (final raw in json['propertyDiffs']! as List)
        propertyDiffResultFromJson((raw as Map).cast()),
    ],
  );

  final List<ClassifiedFailure> failures;

  /// Comparisons (pixel+property combined, per `ComparisonResult`) that
  /// produced zero [ClassifiedFailure]s.
  final int passedCount;

  /// Entries skipped because a required captured artifact was missing —
  /// counted separately from [failures] (`ParityExitCode.infraFailed` is a
  /// distinct exit code from `validationFailed`).
  final int infraFailedCount;

  /// Wall-clock time this run took — logged so NFR-001 (15 min budget)
  /// drift is visible without instrumenting the CI job separately.
  final int durationMs;

  /// Every `key/probeRole` this run skipped as an `InfraFailure` — a
  /// *list*, not just [infraFailedCount]'s bare total (#3861: "총계가
  /// 아니라 목록"). Two runs' comparable sets can differ (an entry newly
  /// InfraFailure-skipped, or the manifest itself changed) — a list lets
  /// `report_comparison.dart` compute which keys are excluded on *each*
  /// side, which a count alone cannot answer.
  final List<String> infraSkippedKeys;

  /// Every `key/probeRole` whose property comparison was skipped as a
  /// **structural** fact (Flutter 캡처의 `rootOmitted` 마커 — root 소유
  /// chrome/텍스트가 없는 설계된 형태) — [infraSkippedKeys] 와 분리하는
  /// 이유: 인프라 버킷에 섞이면 진짜 파이프라인 고장이 상수 배경 위에
  /// 묻힌다. 구조적 스킵은 exit code 에 영향을 주지 않는다 (픽셀 신호는
  /// 계속 돈다 — `entry_loader.dart` 참조).
  final List<String> structuralSkippedKeys;

  /// Every `PropertyDiffResult` this run actually computed — matching
  /// *and* failing fields alike (`ClassifiedFailure`, by contrast, only
  /// ever carries the failing ones). This is the raw data
  /// [fieldMismatchCounts]/[comparablePropertyCount] derive from, and what
  /// `report_comparison.dart` (#3861) pairs up across two runs by
  /// `key/probeRole`. Empty when the run used `--signal=pixel` (property
  /// wasn't computed at all).
  final List<PropertyDiffResult> propertyDiffs;

  bool get hasFailures => failures.isNotEmpty;

  /// How many `(entry, probeRole)` comparisons this run actually computed
  /// a property diff for — the denominator [fieldMismatchCounts] and
  /// `report_comparison.dart`'s per-field percentages use. Excludes
  /// anything [infraSkippedKeys] skipped and anything `--signal=pixel`
  /// excluded property from entirely — matches the "N 비교 가능" figure
  /// #3856's PR body computed by hand (216/202 there).
  int get comparablePropertyCount => propertyDiffs.length;

  /// For every [PropertyField], how many of [comparablePropertyCount]
  /// comparisons had that field mismatch (Flutter vs Web beyond
  /// tolerance) — the number that, before #3861, only existed in a
  /// person's head after manually re-tallying `describeFailures()` text
  /// across every entry (#3852's `color 74/188`, #3856's `fontWeight
  /// 38%→22%`). Every [PropertyField] is present (possibly `0`) so a
  /// caller can iterate without a null-check, same convention as
  /// [byCategory].
  Map<String, int> get fieldMismatchCounts {
    final counts = <String, int>{
      for (final field in PropertyField.values) field.name: 0,
    };
    for (final diff in propertyDiffs) {
      for (final field in diff.fields) {
        if (field.matches) continue;
        counts.update(field.field, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }

  /// [failures] grouped by category, every category present (possibly
  /// empty) so callers can iterate `FailureCategory.values` without a
  /// null-check.
  Map<FailureCategory, List<ClassifiedFailure>> get byCategory {
    final map = <FailureCategory, List<ClassifiedFailure>>{
      for (final category in FailureCategory.values) category: [],
    };
    for (final failure in failures) {
      map[failure.category]!.add(failure);
    }
    return map;
  }

  /// Everything `report_comparison.dart`'s paired-intersection tooling
  /// (#3861) needs from this run, as a plain JSON map `report.dart
  /// --report-json=` writes to disk. [failures] is *not* round-tripped —
  /// `ClassifiedFailure.summary` is already-rendered prose with no
  /// field-level structure of its own to re-aggregate, and the
  /// markdown/console renderers only ever run against this same
  /// in-process instance. This JSON is an input to a *different* run's
  /// comparison tool, not a full report reconstruction.
  Map<String, Object?> toJson() => {
    'passedCount': passedCount,
    'infraFailedCount': infraFailedCount,
    'durationMs': durationMs,
    'infraSkippedKeys': infraSkippedKeys,
    'structuralSkippedKeys': structuralSkippedKeys,
    'propertyDiffs': [
      for (final diff in propertyDiffs) propertyDiffResultToJson(diff),
    ],
  };

  /// One-paragraph-per-category console output — the "실패 건이 재실행
  /// 없이" completion criterion's plain-text form.
  String consoleSummary() {
    final grouped = byCategory;
    final buffer = StringBuffer()
      ..writeln(
        '[report] $passedCount passed, ${failures.length} failed, '
        '$infraFailedCount infra-skipped, '
        '${structuralSkippedKeys.length} structural-skipped '
        '(${durationMs}ms)',
      );
    for (final category in FailureCategory.values) {
      final items = grouped[category]!;
      if (items.isEmpty) continue;
      buffer.writeln(
        '${category.wireName} (${items.length}) — ${category.description}',
      );
      for (final failure in items) {
        final label = failure.probeRole.isEmpty
            ? failure.key
            : '${failure.key}/${failure.probeRole}';
        buffer.writeln('  - $label: ${_firstLine(failure.summary)}');
      }
    }
    return buffer.toString();
  }

  /// The PR comment body, grouped by category with per-failure detail and
  /// allowlist-registration instructions. `null` when there is nothing to
  /// say — the caller (report.dart) uses that to skip posting entirely
  /// (#3617 완료 정의: "실패 0건 시 코멘트 미게시"). This method has no
  /// GitHub knowledge of its own; posting is the caller's job.
  String? toMarkdownComment() {
    if (!hasFailures) return null;

    final grouped = byCategory;
    final buffer = StringBuffer()
      ..writeln(
        // #3861: infraFailedCount 는 헤더에서 항상 보여야 한다 — 이 값이
        // 클수록(예: #3852 root-attribution 수정 이후) "실패 N건" 만으로는
        // 몇 건이 애초에 비교조차 되지 않았는지 리뷰어가 알 방법이 없다.
        '## 🔴 Parity gate — ${failures.length}건 실패 · '
        '$infraFailedCount건 인프라 스킵',
      )
      ..writeln()
      ..writeln('실행 시간: ${(durationMs / 1000).toStringAsFixed(1)}s')
      ..writeln();

    for (final category in FailureCategory.values) {
      final items = grouped[category]!;
      if (items.isEmpty) continue;

      buffer
        ..writeln(
          '### `${category.wireName}` — ${category.description} '
          '(${items.length})',
        )
        ..writeln();

      for (final failure in items) {
        final label = failure.probeRole.isEmpty
            ? failure.key
            : '${failure.key}/${failure.probeRole}';
        buffer
          ..writeln('<details><summary><code>$label</code></summary>')
          ..writeln()
          ..writeln('```')
          ..writeln(failure.summary)
          ..writeln('```');

        if (failure.diffArtifactPaths.isNotEmpty) {
          final paths = failure.diffArtifactPaths
              .map((path) => '`$path`')
              .join(', ');
          buffer
            ..writeln()
            ..writeln('Diff: $paths (아티팩트 탭에서 다운로드 — 30일 보존)');
        }

        if (failure.allowlistHint != null) {
          buffer
            ..writeln()
            ..writeln(
              '의도된 변경이면 `test/parity/allowlist.yaml` 에 다음을 추가:',
            )
            ..writeln('```yaml')
            ..writeln(failure.allowlistHint)
            ..writeln('```');
        }

        buffer
          ..writeln('</details>')
          ..writeln();
      }
    }

    return buffer.toString().trimRight();
  }

  String _firstLine(String text) => text.split('\n').first;
}
