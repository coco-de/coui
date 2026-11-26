#!/usr/bin/env dart

/// Reporter CLI (#3617) — classifies every failing comparison from a
/// manifest (`tool/parity/manifest.dart`, #3604) + captured artifacts
/// (`compare.dart`/#3607's own inputs) into the six failure categories the
/// issue names, prints a console summary, writes a PR-comment markdown
/// file, and (with `--post-comment`) posts it via `gh pr comment`.
/// Motion-probe failures are folded in from `--flutter-motion-json=`/
/// `--web-motion-json=` (`dart test --reporter=json` / `flutter test
/// --machine` output, scoped by the caller to just the parity-probe test
/// suites).
///
/// Usage:
///   `dart run tool/parity/report.dart --manifest=/tmp/manifest.json`
///   `dart run tool/parity/report.dart --manifest=... --post-comment`
///   `dart run tool/parity/report.dart --manifest=... \`
///     `--flutter-motion-json=/tmp/flutter-motion.json \`
///     `--web-motion-json=/tmp/web-motion.json`
///
/// Flags (property/pixel flags mirror `compare.dart`):
///   --manifest=`<path>`            Required.
///   --captured=`<dir>`             (default: `test/parity/captured`)
///   --baseline-root=`<dir>`        (default: `test/parity`)
///   --out=`<dir>`                  Diff PNG dir (default: `test/parity/diff`)
///   --signal=`property|pixel|both` (default: `both`)
///   --mode=`regression|parity|both` (default: `both`)
///   --flutter-motion-json=`<path>` `dart`/`flutter` test JSON event log to
///                                   mine for Flutter motion-probe failures.
///   --web-motion-json=`<path>`     Same, for Web motion-probe failures.
///   --comment-out=`<path>`         (default: `test/parity/report/pr-comment.md`)
///   --vrt-out=`<path>`             (default: `test/parity/report/vrt-report.md`)
///                                   Component-grouped visual-regression
///                                   report (영향 범위 · 회귀 상세 · 검증) —
///                                   written on every run, pass or fail, so
///                                   "통과" 와 "비교 미수행" 이 구분된다.
///   --post-comment                 Attempt `gh pr comment` when there is a
///                                   comment to post.
///   --report-json=`<path>`         Write `ParityReport.toJson()` here
///                                   (#3861) — field-level mismatch counts
///                                   + the infra-skipped key list, for
///                                   `compare_reports.dart`'s paired
///                                   before/after comparison. Not written
///                                   when omitted.
///
/// Exit codes: `0` all comparisons passed, `1` a classified failure exists,
/// `2` infra failure only (no classified failures, but a required artifact
/// was missing) — same convention as `compare.dart` (`ParityExitCode`).
library;

import 'dart:convert';
import 'dart:io';

import 'src/baseline/baseline_store.dart';
import 'src/baseline/parity_platform.dart';
import 'src/cli/flags.dart';
import 'src/diff/comparator.dart';
import 'src/diff/pixel_diff.dart';
import 'src/diff/property_diff.dart';
import 'src/model/capture_body.dart';
import 'src/model/matrix_entry.dart';
import 'src/report/classified_failure.dart';
import 'src/report/compare_result_classifier.dart';
import 'src/report/diff_writer.dart';
import 'src/report/entry_loader.dart';
import 'src/report/failure_category.dart';
import 'src/report/motion_failure_classifier.dart';
import 'src/report/motion_test_event.dart';
import 'src/report/parity_report.dart';
import 'src/report/pr_comment_poster.dart';
import 'src/report/regression_summary.dart';

const String _kDefaultCapturedDir = 'test/parity/captured';
const String _kDefaultBaselineRoot = 'test/parity';
const String _kDefaultOutDir = 'test/parity/diff';
const String _kDefaultCommentOut = 'test/parity/report/pr-comment.md';
const String _kDefaultVrtOut = 'test/parity/report/vrt-report.md';

void main(List<String> args) {
  final stopwatch = Stopwatch()..start();
  final flags = parseFlags(args);

  final manifestPath = flags['manifest'];
  if (manifestPath == null) {
    stderr.writeln('❌ --manifest=<path> 가 필요하다.');
    _printUsage();
    exit(ParityExitCode.infraFailed);
  }
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('❌ 매니페스트 파일을 찾지 못함: $manifestPath');
    exit(ParityExitCode.infraFailed);
  }

  final signal = ComparisonSignal.tryParse(flags['signal'] ?? 'both');
  if (signal == null) {
    stderr.writeln('❌ --signal 값이 잘못됨: ${flags['signal']}');
    _printUsage();
    exit(ParityExitCode.infraFailed);
  }
  final pixelModes = parsePixelModesFlag(flags['mode']);
  if (pixelModes == null) {
    stderr.writeln('❌ --mode 값이 잘못됨: ${flags['mode']}');
    _printUsage();
    exit(ParityExitCode.infraFailed);
  }

  final List<MatrixEntry> entries;
  try {
    final decoded = jsonDecode(manifestFile.readAsStringSync());
    final rawEntries = (decoded as Map<String, Object?>)['entries']! as List;
    entries = [
      for (final raw in rawEntries) MatrixEntry.fromJson((raw as Map).cast()),
    ];
  } on Object catch (e) {
    stderr.writeln('❌ 매니페스트 파싱 실패: $e');
    exit(ParityExitCode.infraFailed);
  }

  final capturedDir = Directory(flags['captured'] ?? _kDefaultCapturedDir);
  final baselineStore = BaselineStore.at(
    flags['baseline-root'] ?? _kDefaultBaselineRoot,
  );
  final outDir = Directory(flags['out'] ?? _kDefaultOutDir);
  final now = DateTime.now();

  final failures = <ClassifiedFailure>[];
  // #3861 — raw per-comparison data `ParityReport.fieldMismatchCounts` /
  // `report_comparison.dart`'s paired-intersection tooling read. Kept as a
  // list (not just a running tally) precisely so a *list* of skipped keys
  // (not a bare count) is what `--report-json=` ends up writing — see
  // `ParityReport.infraSkippedKeys`'s own doc comment on why a count alone
  // can't answer "which keys are excluded".
  final propertyDiffs = <PropertyDiffResult>[];
  final infraSkippedKeys = <String>[];
  final structuralSkippedKeys = <String>[];
  var passedCount = 0;
  final matrixResults = <Map<String, Object?>>[];

  // VRT 요약 셀 (키 × 플랫폼) — 픽셀 회귀는 probe 가 아니라 키 단위 PNG
  // 비교라 키당 셀 한 쌍이면 되는데, probe 마다 결과의 정보량이 다를 수
  // 있다(한 probe 는 인프라 실패, 다른 probe 는 픽셀 비교 수행). collector
  // 가 키마다 가장 정보량 높은 쌍을 유지한다 — "첫 probe 가 이긴다" 로
  // 두면 뒤 probe 의 실제 회귀 판정이 리포트에서 가려진다.
  final regressionCellCollector = RegressionCellCollector();

  for (final entry in entries) {
    var entryFailed = false;
    var entryIncomplete = false;
    var entryCompared = false;
    final roleResults = <String, String>{};
    for (final probe in entry.probes) {
      final artifactKey = pixelArtifactKey(entry.key, probe.role);
      void recordInfra(String message) {
        stderr.writeln('❌ ${entry.key}/${probe.role}: $message');
        infraSkippedKeys.add('${entry.key}/${probe.role}');
        entryIncomplete = true;
        roleResults[probe.role] = 'infra';
        regressionCellCollector.offer(artifactKey, [
          for (final platform in ParityPlatform.values)
            RegressionCell(
              key: artifactKey,
              component: entry.component,
              platform: platform,
              status: RegressionCellStatus.infra,
              note: message,
            ),
        ]);
      }

      final EntryLoadResult loaded;
      try {
        loaded = loadEntry(
          entry: entry,
          probeRole: probe.role,
          signal: signal,
          capturedDir: capturedDir,
          baselineStore: baselineStore,
        );
      } on InfraFailure catch (e) {
        recordInfra(e.message);
        continue;
      }

      // 구조적 property 스킵 — 설계된 형태(root 소유 chrome/텍스트 없음)라
      // property 비교가 성립하지 않는 항목. 인프라 실패와 별도로 세고,
      // 픽셀 신호는 계속 돈다 (entry_loader.dart 의
      // propertyStructuralSkipReason 참조). 픽셀이 애초에 제외된 실행
      // (--signal=property)에서는 이 항목의 비교가 전부 스킵이므로 VRT
      // 셀만 정직하게 남기고 넘어간다.
      final structuralReason = loaded.propertyStructuralSkipReason;
      var effectiveSignal = signal;
      if (structuralReason != null) {
        structuralSkippedKeys.add('${entry.key}/${probe.role}');
        stdout.writeln('◻ $structuralReason');
        if (!signal.includesPixel) {
          roleResults[probe.role] = 'skipped';
          regressionCellCollector.offer(artifactKey, [
            for (final platform in ParityPlatform.values)
              RegressionCell(
                key: artifactKey,
                component: entry.component,
                platform: platform,
                status: RegressionCellStatus.skipped,
                note: structuralReason,
              ),
          ]);
          continue;
        }
        effectiveSignal = ComparisonSignal.pixel;
      }

      // expectedProperty — see compare.dart's own doc comment on why this
      // CLI has no Core-token source wired in yet (follow-up work).
      final ComparisonResult result;
      try {
        result = compareEntry(
          key: entry.key,
          probeRole: probe.role,
          signal: effectiveSignal,
          propertyFields: probe.fields,
          flutterProperty: loaded.flutterProperty,
          webProperty: loaded.webProperty,
          flutterPng: loaded.flutterPng,
          flutterBaselinePng: loaded.flutterBaselinePng,
          webPng: loaded.webPng,
          webBaselinePng: loaded.webBaselinePng,
          pixelModes: pixelModes,
        );
      } on FormatException catch (error) {
        // Validate only comparisons the existing mode/short-circuit actually
        // runs. An unused baseline or cross-pair cannot create a new failure.
        recordInfra(
          'Comparison input format $artifactKey.flutter.png / $artifactKey.web.png '
          '(selected captures/baselines): ${error.message}',
        );
        continue;
      }
      final propertyDiff = result.propertyDiff;
      if (propertyDiff != null) propertyDiffs.add(propertyDiff);

      final classified = classifyComparisonResult(
        result,
        baselineStore: baselineStore,
        flutterCapturedPng: loaded.flutterPng,
        webCapturedPng: loaded.webPng,
        now: now,
      );

      if (classified.isEmpty) {
        passedCount++;
        roleResults[probe.role] = 'pass';
      } else {
        failures.addAll(classified);
        entryFailed = true;
        roleResults[probe.role] = 'fail';
      }
      entryCompared = true;
      writeComparisonDiffImages(result, outDir);
      writePropertyDiffJson(result, outDir);

      regressionCellCollector.offer(artifactKey, [
        _regressionCell(
          entry: entry,
          probeRole: probe.role,
          platform: .flutter,
          diff: result.flutterRegression,
          hasBaseline: loaded.flutterBaselinePng != null,
          pixelSkippedReason: result.pixelSkippedReason,
          classified: classified,
        ),
        _regressionCell(
          entry: entry,
          probeRole: probe.role,
          platform: .web,
          diff: result.webRegression,
          hasBaseline: loaded.webBaselinePng != null,
          pixelSkippedReason: result.pixelSkippedReason,
          classified: classified,
        ),
      ]);
    }
    matrixResults.add({
      'key': entry.key,
      'status': entryIncomplete
          ? 'infra'
          : entryFailed
          ? 'fail'
          : entryCompared
          ? 'pass'
          : 'skipped',
      'roles': roleResults,
    });
  }
  final infraFailedCount = infraSkippedKeys.length;

  final flutterMotionPath = flags['flutter-motion-json'];
  if (flutterMotionPath != null) {
    failures.addAll(
      _classifyMotionFile(File(flutterMotionPath), platformLabel: 'flutter'),
    );
  }
  final webMotionPath = flags['web-motion-json'];
  if (webMotionPath != null) {
    failures.addAll(
      _classifyMotionFile(File(webMotionPath), platformLabel: 'web'),
    );
  }

  stopwatch.stop();
  final report = ParityReport(
    failures: failures,
    passedCount: passedCount,
    infraFailedCount: infraFailedCount,
    durationMs: stopwatch.elapsedMilliseconds,
    propertyDiffs: propertyDiffs,
    infraSkippedKeys: infraSkippedKeys,
    structuralSkippedKeys: structuralSkippedKeys,
  );

  stdout.writeln(report.consoleSummary());
  final matrixCounts = <String, int>{
    for (final status in ['pass', 'fail', 'infra', 'skipped'])
      status: matrixResults.where((r) => r['status'] == status).length,
  };
  stdout.writeln(
    '[matrix] ${matrixCounts['pass']} passed keys, '
    '${matrixCounts['fail']} failed keys, ${matrixCounts['infra']} infra keys, '
    '${matrixCounts['skipped']} skipped keys (${entries.length} total)',
  );

  // VRT 리포트 — 실패 유무와 무관하게 항상 쓴다. "통과" 와 "아예 비교하지
  // 않음"(baseline 없음/픽셀 스킵)이 같은 침묵으로 보이면 안 되기 때문 —
  // PR 코멘트가 실패 시에만 존재하는 것과 정확히 반대 방향의 요구다.
  final regressionSummary = RegressionSummary(
    cells: regressionCellCollector.cells,
  );
  final vrtPath = flags['vrt-out'] ?? _kDefaultVrtOut;
  final vrtFile = File(vrtPath);
  vrtFile.parent.createSync(recursive: true);
  vrtFile.writeAsStringSync('${regressionSummary.toMarkdown()}\n');
  stdout.writeln('[report] VRT 리포트 작성 → $vrtPath');

  // #3861 — the machine-readable counterpart to the two human-facing
  // renders below (console/PR comment): field-level mismatch counts +
  // the infra-skipped key list, for `compare_reports.dart`'s paired
  // before/after comparison. Written unconditionally (pass or fail) —
  // an "after" run with zero failures is exactly the run a before/after
  // comparison needs to prove an improvement, not just a regression.
  final reportJsonPath = flags['report-json'];
  if (reportJsonPath != null) {
    final reportJsonFile = File(reportJsonPath);
    reportJsonFile.parent.createSync(recursive: true);
    reportJsonFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        ...report.toJson(),
        'matrix': {'counts': matrixCounts, 'entries': matrixResults},
      }),
    );
    stdout.writeln('[report] report JSON 작성 → $reportJsonPath');
  }

  final commentPath = flags['comment-out'] ?? _kDefaultCommentOut;
  final commentFile = File(commentPath);
  final comment = report.toMarkdownComment();
  if (comment != null) {
    commentFile.parent.createSync(recursive: true);
    commentFile.writeAsStringSync(comment);
    stdout.writeln('[report] PR 코멘트 작성 → $commentPath');
  } else if (commentFile.existsSync()) {
    // 이전 실행이 남긴 실패 코멘트 파일을 이번 성공 실행이 그대로 두면,
    // 그 파일을 무조건 게시하는 다른 스텝이 stale 코멘트를 올릴 수 있다.
    commentFile.deleteSync();
  }

  final requestedPosting = flags['post-comment'] == 'true';
  if (requestedPosting) {
    final decision = decidePrCommentPosting(
      requestedPosting: requestedPosting,
      comment: comment,
      hasGhToken:
          (Platform.environment['GH_TOKEN']?.isNotEmpty ?? false) ||
          (Platform.environment['GITHUB_TOKEN']?.isNotEmpty ?? false),
      hasGhExecutable: _ghIsAvailable(),
    );
    stdout.writeln('[report] post-comment: ${decision.reason}');
    if (decision.shouldPost) {
      final result = postPrComment(comment!);
      stdout.writeln('[report] ${result.detail}');
      // 코멘트 게시 실패는 인프라 amenity 실패일 뿐 — 검증 실패 종료 코드를
      // 오염시키지 않는다. 로그로만 남긴다 (result.success == false 라도
      // 계속 아래 exit-code 로직으로 진행).
    }
  }

  if (infraFailedCount > 0 && failures.isEmpty) {
    exit(ParityExitCode.infraFailed);
  }
  if (failures.isNotEmpty) {
    exit(ParityExitCode.validationFailed);
  }
  exit(ParityExitCode.ok);
}

/// Builds one VRT summary cell for ([entry].key, [platform]) out of what
/// the comparison already produced. Status precedence:
///
/// 1. [pixelSkippedReason] — pixel never ran because the signal excluded
///    it; baseline presence is unknown (never loaded). A property failure
///    does NOT land here — the parity-only short-circuit
///    (`comparator.dart`'s `paritySkippedReason`) leaves the own-baseline
///    regression running, so those cells carry a real verdict.
/// 2. no baseline — first capture, nothing to compare against.
/// 3. [diff] `null` with a baseline present — the `--mode=` flag excluded
///    regression.
/// 4. diff passed / failed. A failing diff with no matching classified
///    regression failure means the allowlist approved it
///    (`compare_result_classifier.dart` drops approved changes).
RegressionCell _regressionCell({
  required MatrixEntry entry,
  required String probeRole,
  required ParityPlatform platform,
  required PixelDiffResult? diff,
  required bool hasBaseline,
  required String? pixelSkippedReason,
  required List<ClassifiedFailure> classified,
}) {
  final artifactKey = pixelArtifactKey(entry.key, probeRole);
  if (pixelSkippedReason != null) {
    return RegressionCell(
      key: artifactKey,
      component: entry.component,
      platform: platform,
      status: .skipped,
      note: pixelSkippedReason,
    );
  }
  if (!hasBaseline) {
    return RegressionCell(
      key: artifactKey,
      component: entry.component,
      platform: platform,
      status: .noBaseline,
    );
  }
  if (diff == null) {
    return RegressionCell(
      key: artifactKey,
      component: entry.component,
      platform: platform,
      status: .skipped,
      note: '--mode= 가 regression 을 제외함.',
    );
  }
  if (diff.passed) {
    return RegressionCell(
      key: artifactKey,
      component: entry.component,
      platform: platform,
      status: .passed,
      diff: diff,
    );
  }

  ClassifiedFailure? regressionFailure;
  for (final failure in classified) {
    final isRegressionCategory =
        failure.category == FailureCategory.regression ||
        failure.category == FailureCategory.allowlistExpired;
    if (isRegressionCategory && failure.platform == platform) {
      regressionFailure = failure;
      break;
    }
  }
  if (regressionFailure == null) {
    // 임계 초과지만 분류기가 실패로 만들지 않음 = allowlist 승인.
    return RegressionCell(
      key: artifactKey,
      component: entry.component,
      platform: platform,
      status: .approved,
      diff: diff,
    );
  }

  return RegressionCell(
    key: artifactKey,
    component: entry.component,
    platform: platform,
    status: .failed,
    diff: diff,
    diffArtifactPath: regressionFailure.diffArtifactPaths.isNotEmpty
        ? regressionFailure.diffArtifactPaths.first
        : null,
    allowlistHint: regressionFailure.allowlistHint,
  );
}

/// Reads [file] as a `package:test` JSON event log and classifies every
/// non-passing test in it. Every test in the file is treated as a motion
/// probe — the caller (the CI "motion probes" step) is expected to have
/// already scoped the `dart test`/`flutter test` invocation to just the
/// parity-probe suites, so there is nothing else in the log to filter out.
List<ClassifiedFailure> _classifyMotionFile(
  File file, {
  required String platformLabel,
}) {
  if (!file.existsSync()) {
    stderr.writeln(
      '⚠️ [report] $platformLabel motion JSON 을 찾지 못함: ${file.path} — '
      '건너뜀.',
    );
    return const [];
  }

  final motionFailures = parseMotionTestFailures(
    file.readAsStringSync(),
    isMotionProbe: (name) => true,
  );

  return [
    for (final failure in motionFailures)
      ClassifiedFailure(
        category: classifyMotionFailure(failure.errorMessage),
        key: '$platformLabel: ${failure.testName}',
        probeRole: '',
        summary: failure.errorMessage,
      ),
  ];
}

bool _ghIsAvailable() {
  try {
    return Process.runSync('gh', ['--version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

void _printUsage() {
  stderr
    ..writeln('Usage:')
    ..writeln('  dart run tool/parity/report.dart --manifest=PATH [flags]')
    ..writeln()
    ..writeln('Flags:')
    ..writeln(
      '  --captured=DIR              (default: $_kDefaultCapturedDir)',
    )
    ..writeln(
      '  --baseline-root=DIR         (default: $_kDefaultBaselineRoot)',
    )
    ..writeln('  --out=DIR                   (default: $_kDefaultOutDir)')
    ..writeln('  --signal=property|pixel|both  (default: both)')
    ..writeln('  --mode=regression|parity|both  (default: both)')
    ..writeln('  --flutter-motion-json=PATH  Flutter motion-probe test log')
    ..writeln('  --web-motion-json=PATH      Web motion-probe test log')
    ..writeln(
      '  --comment-out=PATH          (default: $_kDefaultCommentOut)',
    )
    ..writeln(
      '  --vrt-out=PATH              (default: $_kDefaultVrtOut) — '
      '컴포넌트별 비주얼 회귀 리포트, 매 실행 기록',
    )
    ..writeln('  --post-comment              Post via `gh pr comment`')
    ..writeln(
      '  --report-json=PATH         Write ParityReport.toJson() (#3861) '
      '— field-level mismatch counts + infra-skipped keys, for '
      '`compare_reports.dart`',
    );
}
