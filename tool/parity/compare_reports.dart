#!/usr/bin/env dart

/// Paired-intersection report comparator (#3861) — takes two
/// `report.dart --report-json=` outputs and prints the same field-by-field
/// before/after mismatch table a person previously had to compute by hand
/// outside the repo (#3856's PR body is the motivating example this
/// closes — see `src/report/report_comparison.dart`'s doc comment for why
/// "paired intersection" is the right denominator, not each run's own
/// unrestricted percentage).
///
/// Usage:
///   `dart run tool/parity/compare_reports.dart \`
///     `--before=/tmp/before-report.json --after=/tmp/after-report.json`
///   `dart run tool/parity/compare_reports.dart --before=... --after=... \`
///     `--out=/tmp/comparison.md`
///
/// Flags:
///   --before=`<path>`  Required. A `ParityReport.toJson()` file from the
///                       "before" run (`report.dart --report-json=`).
///   --after=`<path>`   Required. Same, for the "after" run.
///   --out=`<path>`     Optional. Also write the markdown table to this
///                       file (in addition to stdout).
///
/// Exit codes: `0` comparison computed successfully (regardless of
/// whether it improved or regressed — this tool reports, it doesn't
/// gate), `2` a `--before=`/`--after=` file was missing or unparseable.
library;

import 'dart:convert';
import 'dart:io';

import 'src/cli/flags.dart';
import 'src/report/parity_report.dart';
import 'src/report/report_comparison.dart';

void main(List<String> args) {
  final flags = parseFlags(args);

  final beforePath = flags['before'];
  final afterPath = flags['after'];
  if (beforePath == null || afterPath == null) {
    stderr.writeln('❌ --before=<path> 와 --after=<path> 가 모두 필요하다.');
    _printUsage();
    exit(ParityExitCode.infraFailed);
  }

  final ParityReport before;
  final ParityReport after;
  try {
    before = _readReport(beforePath);
    after = _readReport(afterPath);
  } on Object catch (e) {
    stderr.writeln('❌ report JSON 읽기/파싱 실패: $e');
    exit(ParityExitCode.infraFailed);
  }

  final comparison = compareReports(before: before, after: after);
  final table = comparison.toMarkdownTable();
  stdout.writeln(table);

  final outPath = flags['out'];
  if (outPath != null) {
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(table);
    stdout.writeln('[compare-reports] 저장 → $outPath');
  }
}

ParityReport _readReport(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('파일을 찾지 못함: $path');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  return ParityReport.fromJson((decoded as Map).cast());
}

void _printUsage() {
  stderr
    ..writeln('Usage:')
    ..writeln(
      '  dart run tool/parity/compare_reports.dart --before=PATH '
      '--after=PATH [--out=PATH]',
    );
}
