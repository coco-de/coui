#!/usr/bin/env dart

/// Comparator CLI (#3607) — PropertyDiff (1st signal) + PixelDiff (2nd
/// signal) against baseline/allowlist, for every entry in a manifest
/// produced by `tool/parity/manifest.dart` (#3604).
///
/// Usage:
///   `dart run tool/parity/compare.dart --manifest=/tmp/manifest.json`
///   `dart run tool/parity/compare.dart --manifest=... --signal=property`
///   `dart run tool/parity/compare.dart --manifest=... --mode=parity`
///
/// Flags:
///   --manifest=`<path>`  Required. Manifest JSON from `manifest.dart`.
///   --captured=`<dir>`   Where this run's artifacts live
///                        (default: `test/parity/captured`).
///   --baseline-root=`<dir>` `test/parity/` root — `BaselineStore.at(...)`
///                        reads `baseline/`/`allowlist.yaml` under it
///                        (default: `test/parity`).
///   --out=`<dir>`        Where to write failing-diff PNGs
///                        (default: `test/parity/diff`).
///   --signal=`property|pixel|both` Which comparison signal(s) to run
///                        (default: `both`).
///   --mode=`regression|parity|both` Which PixelDiff mode(s) to run when
///                        pixel is included (default: `both`). Has no
///                        effect on PropertyDiff, which is always the
///                        Flutter/Web/token 3-way check.
///
/// Exit codes: `0` all comparisons passed, `1` a comparison failed
/// (regression/parity/property mismatch), `2` infra failure (missing
/// manifest, missing captured artifact, malformed JSON) — a missing
/// artifact is not the same fact as "the artifact differs", and NFR-002's
/// false-positive tracking needs the two kept apart.
library;

import 'dart:convert';
import 'dart:io';

import 'src/baseline/baseline_store.dart';
import 'src/cli/flags.dart';
import 'src/diff/comparator.dart';
import 'src/model/capture_body.dart';
import 'src/model/matrix_entry.dart';
import 'src/report/diff_writer.dart';
import 'src/report/entry_loader.dart';

const String _kDefaultCapturedDir = 'test/parity/captured';
const String _kDefaultBaselineRoot = 'test/parity';
const String _kDefaultOutDir = 'test/parity/diff';

void main(List<String> args) {
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

  var failedCount = 0;
  var infraFailedCount = 0;
  var passedCount = 0;
  var structuralSkippedCount = 0;

  for (final entry in entries) {
    for (final probe in entry.probes) {
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
        stderr.writeln('❌ ${entry.key}/${probe.role}: ${e.message}');
        infraFailedCount++;
        continue;
      }

      // 구조적 property 스킵 — 설계된 형태(root 소유 chrome/텍스트 없음)라
      // property 비교가 성립하지 않는 항목. 인프라 실패와 별도로 세고,
      // 픽셀 신호는 계속 돈다 (entry_loader.dart 의
      // propertyStructuralSkipReason 참조).
      final structuralReason = loaded.propertyStructuralSkipReason;
      var effectiveSignal = signal;
      if (structuralReason != null) {
        structuralSkippedCount++;
        stdout.writeln('◻ $structuralReason');
        if (!signal.includesPixel) continue;
        effectiveSignal = ComparisonSignal.pixel;
      }

      // expectedProperty (the 3-way Flutter/Web/Core-token verdict,
      // property_diff.dart's TokenDivergence) is intentionally omitted
      // here — this CLI has no source yet for "what does the Core token
      // say this field should be" per component/field. The mechanism
      // exists and is unit-tested (property_diff_test.dart's confirmed
      // Command defect), but every field a real run through this CLI
      // produces resolves to TokenDivergence.notChecked until a token
      // source is wired in as follow-up work.
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
        stderr.writeln(
          '❌ ${entry.key}/${probe.role}: Comparison input format '
          '${pixelArtifactKey(entry.key, probe.role)}.flutter.png / '
          '${pixelArtifactKey(entry.key, probe.role)}.web.png '
          '(selected captures/baselines): ${error.message}',
        );
        infraFailedCount++;
        continue;
      }

      if (result.passed) {
        passedCount++;
        continue;
      }

      failedCount++;
      _reportFailure(result);
      writeComparisonDiffImages(result, outDir);
    }
  }

  stdout.writeln(
    '[compare] $passedCount passed, $failedCount failed, '
    '$infraFailedCount infra-skipped, '
    '$structuralSkippedCount structural-skipped',
  );

  if (infraFailedCount > 0 && failedCount == 0) {
    exit(ParityExitCode.infraFailed);
  }
  if (failedCount > 0) {
    exit(ParityExitCode.validationFailed);
  }
  exit(ParityExitCode.ok);
}

void _reportFailure(ComparisonResult result) {
  stdout.writeln('❌ ${result.key}/${result.probeRole}');
  if (result.propertyDiff != null && result.propertyDiff!.hasFailures) {
    stdout.writeln(result.propertyDiff!.describeFailures());
  }
  if (result.pixelSkippedReason != null) {
    stdout.writeln('  (pixel: ${result.pixelSkippedReason})');
  }
  if (result.paritySkippedReason != null) {
    stdout.writeln('  (parity: ${result.paritySkippedReason})');
  }
  if (result.flutterRegression != null && !result.flutterRegression!.passed) {
    stdout.writeln('  flutter regression: ${result.flutterRegression}');
  }
  if (result.webRegression != null && !result.webRegression!.passed) {
    stdout.writeln('  web regression: ${result.webRegression}');
  }
  if (result.crossPlatformParity != null &&
      !result.crossPlatformParity!.passed) {
    stdout.writeln('  parity: ${result.crossPlatformParity}');
  }
}

void _printUsage() {
  stderr
    ..writeln('Usage:')
    ..writeln('  dart run tool/parity/compare.dart --manifest=PATH [flags]')
    ..writeln()
    ..writeln('Flags:')
    ..writeln(
      '  --captured=DIR       Captured artifacts dir '
      '(default: $_kDefaultCapturedDir)',
    )
    ..writeln(
      '  --baseline-root=DIR  test/parity/ root '
      '(default: $_kDefaultBaselineRoot)',
    )
    ..writeln(
      '  --out=DIR            Diff PNG output dir '
      '(default: $_kDefaultOutDir)',
    )
    ..writeln('  --signal=property|pixel|both  (default: both)')
    ..writeln('  --mode=regression|parity|both  (default: both)');
}
