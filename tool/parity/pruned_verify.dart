#!/usr/bin/env dart

/// Pruned-pairs verification CLI (#3620, property signal added #3663 item
/// 1) — for every `{prunedKey, baselineKey}` pair `pruned_manifest.dart`
/// derived and the nightly sweep's capture step already ran, diffs the
/// pruned capture against its `defaultStyle` baseline **within the same
/// platform, same run** on *both* comparison signals this repo has —
/// PropertyDiff (`property_diff.dart`, exact field comparison) and
/// PixelDiff (`pixel_diff.dart`, same rasterizer twice, so this uses the
/// tight regression threshold `kRegressionThreshold`, not the loose
/// cross-platform parity one).
///
/// Both signals run because either one catching a mismatch means the
/// pruning rule is wrong — pixel comparison alone cannot: a translucent
/// fill on a same-colour flat backdrop can move zero pixels while still
/// changing `backgroundColor` from an opaque `rgb(...)` to
/// `rgba(..., 0.7)`, which PixelDiff has no way to see (see
/// `src/diff/pruned_pair_verifier.dart`'s header for the empirical case
/// this was missing).
///
/// A mismatch here means a pruning input is wrong — the combination
/// `surface_style_pruning.dart` excluded from the PR-gate manifest actually
/// renders differently from `defaultStyle` and should not have been pruned.
/// Since the material half of that rule is measured from the Web render
/// (`material_reach.dart`), a mismatch on the *Flutter* side of a pair
/// whose Web side matched is the case the measurement cannot see: the
/// Flutter example composes a marked surface its Web twin does not — a
/// cross-platform composition asymmetry in the component or its example,
/// to be fixed there.
///
/// Usage:
///   `dart run tool/parity/pruned_verify.dart --pairs=/tmp/pairs.json --captured=/tmp/captured`
///
/// Exit codes: `0` every pruned/baseline pair matched on every signal that
/// ran, `1` at least one pruning rule is wrong, `2` infra failure (missing
/// captured artifact — PNG or property JSON).
library;

import 'dart:convert';
import 'dart:io';

import 'src/cli/flags.dart';
import 'src/diff/pruned_pair_verifier.dart';
import 'src/model/property_snapshot.dart';
import 'src/report/entry_loader.dart';

void main(List<String> args) {
  final flags = parseFlags(args);
  final pairsPath = flags['pairs'];
  if (pairsPath == null) {
    stderr.writeln('❌ --pairs=<path> 가 필요하다 (pruned_manifest.dart 출력).');
    _printUsage();
    exit(2);
  }
  final pairsFile = File(pairsPath);
  if (!pairsFile.existsSync()) {
    stderr.writeln('❌ pairs 파일을 찾지 못함: $pairsPath');
    exit(2);
  }

  final capturedDir = Directory(flags['captured'] ?? 'test/parity/captured');
  final outDir = Directory(flags['out'] ?? 'test/parity/pruned-diff');

  final List<Object?> pairs;
  try {
    final decoded = jsonDecode(pairsFile.readAsStringSync());
    pairs = (decoded as Map<String, Object?>)['pairs']! as List<Object?>;
  } on Object catch (e) {
    stderr.writeln('❌ pairs 파일 파싱 실패: $e');
    exit(2);
  }

  var mismatchCount = 0;
  var infraFailedCount = 0;
  var matchedCount = 0;

  for (final raw in pairs) {
    final entry = (raw! as Map).cast<String, Object?>();
    final prunedKey = entry['prunedKey']! as String;
    final baselineKey = entry['baselineKey']! as String;

    for (final platform in const ['flutter', 'web']) {
      final prunedFile = File('${capturedDir.path}/$prunedKey.$platform.png');
      final baselineFile = File(
        '${capturedDir.path}/$baselineKey.$platform.png',
      );
      if (!prunedFile.existsSync() || !baselineFile.existsSync()) {
        stderr.writeln(
          '❌ 캡처 산출물 없음: $prunedKey/$baselineKey ($platform) — '
          'pruned=${prunedFile.existsSync()} '
          'baseline=${baselineFile.existsSync()}',
        );
        infraFailedCount++;
        continue;
      }

      // pruned_manifest.dart 는 `rootProbeSpec` 만 쓴다(단일 probe, role
      // 'root') — MatrixEntry.probes 를 다시 로드할 필요 없이 고정값으로
      // 조회한다.
      final PropertySnapshot prunedProperty;
      final PropertySnapshot baselineProperty;
      try {
        prunedProperty = platform == 'web'
            ? loadWebPropertySnapshot(
                key: prunedKey,
                capturedDir: capturedDir,
                probeRole: 'root',
              )
            : loadFlutterPropertySnapshot(
                key: prunedKey,
                capturedDir: capturedDir,
                probeRole: 'root',
              );
        baselineProperty = platform == 'web'
            ? loadWebPropertySnapshot(
                key: baselineKey,
                capturedDir: capturedDir,
                probeRole: 'root',
              )
            : loadFlutterPropertySnapshot(
                key: baselineKey,
                capturedDir: capturedDir,
                probeRole: 'root',
              );
      } on InfraFailure catch (e) {
        stderr.writeln(
          '❌ 속성 캡처 산출물 없음: $prunedKey/$baselineKey ($platform) — '
          '${e.message}',
        );
        infraFailedCount++;
        continue;
      }

      final PrunedPairVerifyResult verifyResult;
      try {
        verifyResult = verifyPrunedPair(
          prunedKey: prunedKey,
          baselineKey: baselineKey,
          platform: platform,
          prunedPng: prunedFile.readAsBytesSync(),
          baselinePng: baselineFile.readAsBytesSync(),
          prunedProperty: prunedProperty,
          baselineProperty: baselineProperty,
        );
      } on FormatException catch (error) {
        stderr.writeln(
          '❌ PNG colour format: $prunedKey/$baselineKey ($platform) — '
          '${error.message}',
        );
        infraFailedCount++;
        continue;
      }

      if (verifyResult.passed) {
        matchedCount++;
        continue;
      }

      mismatchCount++;
      stdout.writeln(
        '❌ 프루닝 오판 의심: $prunedKey ($platform) 이 baseline $baselineKey '
        '와 다르다 — 이 플랫폼의 예제가 마커 표면을 합성한다면 Web SSR '
        '실측(material_reach.dart)과 갈린 것이고, 아니면 프루닝 규칙 자체를 '
        '재검토할 것.',
      );
      for (final line in verifyResult.describeFailures()) {
        stdout.writeln('  $line');
      }
      final diffBytes = verifyResult.pixelDiff?.diffImageBytes;
      if (diffBytes != null) {
        outDir.createSync(recursive: true);
        File(
          '${outDir.path}/$prunedKey.vs.$baselineKey.$platform.diff.png',
        ).writeAsBytesSync(diffBytes);
      }
    }
  }

  stdout.writeln(
    '[pruned_verify] $matchedCount matched, $mismatchCount mismatched, '
    '$infraFailedCount infra-skipped',
  );

  if (infraFailedCount > 0 && mismatchCount == 0) {
    exit(2);
  }
  if (mismatchCount > 0) {
    exit(1);
  }
  exit(0);
}

void _printUsage() {
  stderr
    ..writeln('Usage:')
    ..writeln(
      '  dart run tool/parity/pruned_verify.dart --pairs=PATH '
      '[--captured=DIR] [--out=DIR]',
    );
}
