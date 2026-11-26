// 비주얼 회귀(VRT) 요약 — 플랫폼별(빌드 환경별) own-baseline 픽셀 회귀의
// 컴포넌트 단위 집계와, 그 집계를 사람이 읽는 회귀 리포트 마크다운으로
// 렌더하는 단일 출처.
//
// `report.dart` 의 6-카테고리 PR 코멘트(`parity_report.dart`)가 "실패를
// 원인별로" 묶는 반면, 이 파일은 "무엇이 검증됐고 무엇이 검증되지 않았나"
// 를 캡처 셀(키 × 플랫폼) 전수로 답한다 — 실패 0 건이어도 리포트가
// 존재해야 "검증 안 함" 과 "검증하고 통과" 가 구분된다(빈 매니페스트가
// 초록 체크로 위장했던 전례와 같은 계열의 요구).
import '../baseline/parity_platform.dart';
import '../diff/pixel_diff.dart';

/// One capture cell's regression verdict — a cell is (matrix key ×
/// platform), i.e. one PNG compared (or not) against its own committed
/// baseline.
enum RegressionCellStatus {
  /// Baseline exists and the pixel diff stayed under the regression
  /// threshold.
  passed('통과'),

  /// Baseline exists and the pixel diff exceeded the regression threshold
  /// (or the dimensions no longer match) — an unapproved visual change.
  failed('회귀'),

  /// The diff exceeded the threshold but the allowlist carries an
  /// unexpired approval for exactly this capture's fingerprint.
  approved('승인된 변경'),

  /// No committed baseline for this (key, platform) yet — first capture.
  /// Nothing was compared; promoting this capture creates the baseline.
  noBaseline('baseline 없음'),

  /// The comparison did not run for a non-baseline reason — the signal
  /// excluded pixel, or a property failure short-circuited it.
  skipped('비교 스킵'),

  /// A required captured artifact was missing or unparseable — the cell
  /// could not even be loaded (`ParityExitCode.infraFailed` territory).
  infra('인프라 실패');

  const RegressionCellStatus(this.label);

  /// 리포트에 그대로 실리는 한국어 라벨.
  final String label;
}

/// One (matrix key × platform) regression verdict plus whatever detail the
/// report renders for it.
class RegressionCell {
  /// Creates one cell.
  const RegressionCell({
    required this.key,
    required this.component,
    required this.platform,
    required this.status,
    this.diff,
    this.note,
    this.diffArtifactPath,
    this.allowlistHint,
  });

  /// Matrix key (`button-primary-light-defaultStyle`).
  final String key;

  /// Catalog component slug the key belongs to (`button`) — the grouping
  /// unit of the 영향 범위 table. Carried explicitly because slugs contain
  /// hyphens, so it cannot be re-derived from [key] by splitting.
  final String component;

  /// Which build environment's capture this cell is.
  final ParityPlatform platform;

  /// The verdict.
  final RegressionCellStatus status;

  /// The pixel comparison, when one ran ([RegressionCellStatus.passed] /
  /// [RegressionCellStatus.failed] / [RegressionCellStatus.approved]).
  final PixelDiffResult? diff;

  /// Why the cell was skipped / infra-failed — free text, rendered in the
  /// report's "비교 미수행 사유" section for those statuses.
  final String? note;

  /// Diff PNG filename (relative to the diff output dir) for a failing
  /// cell, when one was written.
  final String? diffArtifactPath;

  /// The ready-to-paste `allowlist.yaml` entry for approving this change,
  /// for failing cells.
  final String? allowlistHint;
}

/// How informed a cell's verdict is — [RegressionCellCollector] keeps the
/// most-informed pair per key when a key has multiple probes. A probe
/// where the pixel comparison actually ran outranks one that couldn't
/// (skipped/infra), because the pixel comparison is key-level (same PNGs
/// whichever probe triggered it) — its verdict is a fact about the key.
int _informednessRank(RegressionCellStatus status) => switch (status) {
  .passed || .failed || .approved => _kRankCompared,
  .noBaseline => _kRankNoBaseline,
  .skipped => _kRankSkipped,
  .infra => _kRankInfra,
};

/// Informedness ranks — named so the switch above reads as an ordering.
const int _kRankCompared = 3;
const int _kRankNoBaseline = 2;
const int _kRankSkipped = 1;
const int _kRankInfra = 0;

/// Accumulates VRT cells across a manifest walk where one key can be
/// visited multiple times (one visit per probe), keeping the
/// most-informed cell pair per key.
///
/// Without this, "첫 probe 가 이긴다" — a key whose first probe
/// infra-fails or property-short-circuits would lock its cells to
/// 인프라/스킵 even when a later probe of the same key ran the key-level
/// pixel regression and produced a real verdict, making the VRT report
/// contradict the exit code of its own run.
class RegressionCellCollector {
  /// key → that key's current best cell pair, insertion-ordered so the
  /// report follows manifest order.
  final Map<String, List<RegressionCell>> _byKey = {};

  /// Offers one probe-visit's cell pair for [key]; kept only if it is
  /// better-informed than what the key already has.
  void offer(String key, List<RegressionCell> pair) {
    final existing = _byKey[key];
    if (existing == null || _pairRank(pair) > _pairRank(existing)) {
      _byKey[key] = pair;
    }
  }

  int _pairRank(List<RegressionCell> pair) => pair
      .map((cell) => _informednessRank(cell.status))
      .reduce((a, b) => a > b ? a : b);

  /// Every kept cell, flattened in manifest order.
  List<RegressionCell> get cells => [
    for (final pair in _byKey.values) ...pair,
  ];
}

/// 상태별 표기 이모지 — 표와 검증 요약이 같은 어휘를 쓰도록 한 곳에 둔다.
const Map<RegressionCellStatus, String> _kStatusMark = {
  RegressionCellStatus.passed: '✅',
  RegressionCellStatus.failed: '❌',
  RegressionCellStatus.approved: '☑️',
  RegressionCellStatus.noBaseline: '⏭',
  RegressionCellStatus.skipped: '−',
  RegressionCellStatus.infra: '⚠️',
};

/// Every cell of one report run, with the markdown renderer for the
/// component-grouped visual-regression report:
///
/// ```text
/// ## 🖼 비주얼 회귀 — Flutter · Web 빌드 환경별 컴포넌트 캡처
/// ### 영향 범위 — 컴포넌트 N개 중 M개 회귀   (컴포넌트 × 플랫폼 표)
/// ### 회귀 상세                              (해상도 · 픽셀 diff · 주요 변화)
/// ### 검증                                   (상태별 집계 표)
/// ```
class RegressionSummary {
  /// Creates a summary over [cells].
  const RegressionSummary({required this.cells});

  /// Every capture cell this run produced a verdict (or non-verdict) for.
  final List<RegressionCell> cells;

  /// Whether any cell is an unapproved regression.
  bool get hasFailures =>
      cells.any((cell) => cell.status == RegressionCellStatus.failed);

  /// How many cells actually compared against a baseline (passed + failed
  /// + approved) — the "회귀 비교 수행" figure. `0` means this report
  /// verified nothing, which the markdown states loudly.
  int get comparedCellCount => cells
      .where(
        (cell) =>
            cell.status == RegressionCellStatus.passed ||
            cell.status == RegressionCellStatus.failed ||
            cell.status == RegressionCellStatus.approved,
      )
      .length;

  Map<RegressionCellStatus, int> get _statusCounts {
    final counts = <RegressionCellStatus, int>{
      for (final status in RegressionCellStatus.values) status: 0,
    };
    for (final cell in cells) {
      counts.update(cell.status, (count) => count + 1);
    }
    return counts;
  }

  /// Cells grouped by component slug, insertion order preserved.
  Map<String, List<RegressionCell>> get _byComponent {
    final grouped = <String, List<RegressionCell>>{};
    for (final cell in cells) {
      grouped.putIfAbsent(cell.component, () => []).add(cell);
    }
    return grouped;
  }

  /// Renders the full report. Always renders — a run with zero failures
  /// (or zero comparisons) still produces a report, because "통과" 와
  /// "아예 비교하지 않음" 이 같은 침묵으로 보이면 안 된다.
  String toMarkdown() {
    final counts = _statusCounts;
    final grouped = _byComponent;
    final failedComponents = grouped.entries
        .where(
          (entry) => entry.value.any(
            (cell) => cell.status == RegressionCellStatus.failed,
          ),
        )
        .map((entry) => entry.key)
        .toSet();

    final buffer = StringBuffer()
      ..writeln('## 🖼 비주얼 회귀 — Flutter · Web 빌드 환경별 컴포넌트 캡처')
      ..writeln()
      ..writeln(
        '캡처 셀 ${formatThousands(cells.length)}개 '
        '(컴포넌트 ${grouped.length}개 · 플랫폼별 own-baseline 픽셀 회귀, '
        '임계 ${_regressionThresholdPercent()}%)',
      )
      ..writeln();

    if (comparedCellCount == 0) {
      buffer
        ..writeln(
          '> ⚠️ **이 실행은 아무 회귀도 검증하지 않았다** — baseline 이 '
          '없거나 픽셀 비교가 스킵되어 비교가 0건이다. 아래 표의 초록이 '
          '아니라 이 문장이 이 리포트의 결론이다. baseline 채우기: '
          '`melos run parity:promote`.',
        )
        ..writeln();
    }

    _writeScopeTable(buffer, grouped, failedComponents);
    _writeFailureDetails(buffer);
    _writeUnverifiedNotes(buffer);
    _writeVerificationTable(buffer, counts);

    return buffer.toString().trimRight();
  }

  /// 스킵/인프라 셀의 사유를 사유 텍스트로 묶어 렌더 — 같은 원인(예:
  /// 한 캡처 파일 부재)이 수십 셀에 반복되기 쉬워 셀별 나열 대신 사유별
  /// 집계로 보인다. 사유 없는 셀 뿐이면 섹션 자체를 생략.
  void _writeUnverifiedNotes(StringBuffer buffer) {
    final noted = cells.where(
      (cell) =>
          (cell.status == RegressionCellStatus.skipped ||
              cell.status == RegressionCellStatus.infra) &&
          cell.note != null,
    );
    final byNote = <String, List<RegressionCell>>{};
    for (final cell in noted) {
      byNote.putIfAbsent(cell.note!, () => []).add(cell);
    }
    if (byNote.isEmpty) return;

    buffer
      ..writeln('### 비교 미수행 사유')
      ..writeln();
    for (final entry in byNote.entries) {
      final affected = entry.value;
      final example = affected.first;
      buffer.writeln(
        '- ${_kStatusMark[example.status]} ${affected.length}셀 — '
        '${entry.key} (예: `${example.key}` · ${example.platform.wireName})',
      );
    }
    buffer.writeln();
  }

  void _writeScopeTable(
    StringBuffer buffer,
    Map<String, List<RegressionCell>> grouped,
    Set<String> failedComponents,
  ) {
    buffer
      ..writeln(
        '### 영향 범위 — 컴포넌트 ${grouped.length}개 중 '
        '${failedComponents.length}개 회귀',
      )
      ..writeln()
      ..writeln('| 컴포넌트 | Flutter | Web |')
      ..writeln('|---|---|---|');

    // 회귀가 있는 컴포넌트 먼저, 각 묶음 안에서는 슬러그 순 — 리뷰어가
    // 표 상단만 봐도 무엇이 깨졌는지 알 수 있게.
    final ordered = grouped.keys.toList()
      ..sort((a, b) {
        final aFailed = failedComponents.contains(a);
        final bFailed = failedComponents.contains(b);
        if (aFailed != bFailed) return aFailed ? -1 : 1;
        return a.compareTo(b);
      });

    for (final component in ordered) {
      final componentCells = grouped[component]!;
      final flutterText = _platformCellText(componentCells, .flutter);
      final webText = _platformCellText(componentCells, .web);
      buffer.writeln('| `$component` | $flutterText | $webText |');
    }

    buffer
      ..writeln()
      ..writeln(
        '${_kStatusMark[RegressionCellStatus.noBaseline]} = baseline 없음 '
        '(첫 캡처 — 비교 미수행) · '
        '${_kStatusMark[RegressionCellStatus.approved]} = allowlist 승인 · '
        '${_kStatusMark[RegressionCellStatus.skipped]} = 비교 스킵 · '
        '${_kStatusMark[RegressionCellStatus.infra]} = 인프라 실패',
      )
      ..writeln();
  }

  String _platformCellText(
    List<RegressionCell> componentCells,
    ParityPlatform platform,
  ) {
    final platformCells = componentCells
        .where((cell) => cell.platform == platform)
        .toList();
    if (platformCells.isEmpty) return '—';

    final counts = <RegressionCellStatus, int>{};
    for (final cell in platformCells) {
      counts.update(cell.status, (count) => count + 1, ifAbsent: () => 1);
    }
    final total = platformCells.length;

    final passed = counts[RegressionCellStatus.passed] ?? 0;
    if (passed == total) {
      return '${_kStatusMark[RegressionCellStatus.passed]} $passed/$total';
    }
    if ((counts[RegressionCellStatus.noBaseline] ?? 0) == total) {
      return '${_kStatusMark[RegressionCellStatus.noBaseline]} baseline 없음';
    }

    final parts = <String>[
      for (final status in RegressionCellStatus.values)
        if ((counts[status] ?? 0) > 0)
          '${_kStatusMark[status]} ${counts[status]}',
    ];
    return '${parts.join(' · ')} (/$total)';
  }

  void _writeFailureDetails(StringBuffer buffer) {
    final failing =
        cells
            .where((cell) => cell.status == RegressionCellStatus.failed)
            .toList()
          ..sort((a, b) {
            final byKey = a.key.compareTo(b.key);
            if (byKey != 0) return byKey;
            return a.platform.wireName.compareTo(b.platform.wireName);
          });
    if (failing.isEmpty) return;

    buffer
      ..writeln('### 회귀 상세')
      ..writeln();

    for (final cell in failing) {
      buffer
        ..writeln('#### `${cell.key}` · ${cell.platform.wireName}')
        ..writeln();

      final diff = cell.diff;
      if (diff != null) {
        buffer
          ..writeln('```')
          ..writeln(diff.describe())
          ..writeln('```');
      }

      if (cell.diffArtifactPath != null) {
        buffer
          ..writeln()
          ..writeln('Diff 이미지: `${cell.diffArtifactPath}`');
      }

      if (cell.allowlistHint != null) {
        buffer
          ..writeln()
          ..writeln(
            '의도된 변경이면 `test/parity/allowlist.yaml` 에 추가 후, 새 '
            '렌더를 baseline 으로 승격(`melos run parity:promote -- '
            '${cell.key}`):',
          )
          ..writeln('```yaml')
          ..writeln(cell.allowlistHint)
          ..writeln('```');
      }

      buffer.writeln();
    }
  }

  void _writeVerificationTable(
    StringBuffer buffer,
    Map<RegressionCellStatus, int> counts,
  ) {
    buffer
      ..writeln('### 검증')
      ..writeln()
      ..writeln('| 항목 | 결과 |')
      ..writeln('|---|---|')
      ..writeln(
        '| 회귀 비교 수행 (baseline 보유) | '
        '${formatThousands(comparedCellCount)}건 |',
      );
    for (final status in RegressionCellStatus.values) {
      final count = counts[status]!;
      buffer.writeln(
        '| ${_kStatusMark[status]} ${status.label} | '
        '${formatThousands(count)}건 |',
      );
    }
  }

  String _regressionThresholdPercent() =>
      (kRegressionThreshold * _kPercentMultiplier).toStringAsFixed(
        _kThresholdPercentDecimals,
      );
}

/// Ratio → percent.
const int _kPercentMultiplier = 100;

/// Decimal places for the threshold in the header — enough to render the
/// 0.1% regression threshold exactly.
const int _kThresholdPercentDecimals = 1;
