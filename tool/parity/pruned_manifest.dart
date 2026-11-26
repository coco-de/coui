#!/usr/bin/env dart

/// Pruned-pairs manifest CLI (#3620) — derives every (component, variant,
/// theme, surfaceStyle) combination `manifest.dart`'s normal derivation
/// excludes (`surface_style_pruning.dart`), paired with its `defaultStyle`
/// counterpart, and writes two files:
///
///  - `--out=<path>`: a manifest JSON in the exact shape `manifest.dart`
///    emits (`{entries: [...]}`), so the existing `capture_web.dart`/
///    Flutter capture backend can capture it with zero new capture code.
///  - `--pairs-out=<path>`: `{pairs: [{prunedKey, baselineKey}]}`, telling
///    `pruned_verify.dart` which two captured artifacts to diff against
///    each other after the capture step runs.
///
/// Usage:
///   `dart run tool/parity/pruned_manifest.dart --out=/tmp/pruned.json --pairs-out=/tmp/pairs.json`
///
/// Exit codes: `0` success, `2` infra failure (bad `--out`/`--pairs-out`).
library;

import 'dart:convert';
import 'dart:io';

import 'src/cli/flags.dart';
import 'src/manifest/material_reach.dart';
import 'src/manifest/pruned_pairs.dart';
import 'src/model/matrix_entry.dart';

Future<void> main(List<String> args) async {
  final flags = parseFlags(args);
  final outPath = flags['out'];
  final pairsOutPath = flags['pairs-out'];
  if (outPath == null || pairsOutPath == null) {
    stderr.writeln('❌ --out=<path> 와 --pairs-out=<path> 가 둘 다 필요하다.');
    _printUsage();
    exit(2);
  }

  // Same measurement `manifest.dart` prunes on — see `material_reach.dart`.
  final materialReach = await measureMaterialReachedSlugs();
  stdout.writeln(
    '[pruned_manifest] material reach: ${materialReach.length}개 컴포넌트의 '
    '예제가 표면 마커를 실제로 렌더한다',
  );

  final pairs = resolvePrunedPairs(materialReach: materialReach);

  // 같은 baseline entry 가 여러 pruned style 의 짝으로 반복 등장하므로,
  // 캡처 매니페스트에는 키 기준으로 한 번씩만 싣는다 — 캡처 비용을
  // 중복시키지 않는다.
  final entriesByKey = <String, MatrixEntry>{};
  for (final pair in pairs) {
    entriesByKey[pair.pruned.key] = pair.pruned;
    entriesByKey[pair.baseline.key] = pair.baseline;
  }

  final outFile = File(outPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'entries': entriesByKey.values.map((e) => e.toJson()).toList(),
    }),
  );

  final pairsFile = File(pairsOutPath);
  pairsFile.parent.createSync(recursive: true);
  pairsFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'pairs': [
        for (final pair in pairs)
          {'prunedKey': pair.pruned.key, 'baselineKey': pair.baseline.key},
      ],
    }),
  );

  stdout.writeln(
    '[pruned_manifest] ${entriesByKey.length}개 캡처 대상 (pruned '
    '${pairs.length}건 + 그 baseline) → $outPath, ${pairs.length}개 쌍 → '
    '$pairsOutPath',
  );
}

void _printUsage() {
  stderr
    ..writeln('Usage:')
    ..writeln(
      '  dart run tool/parity/pruned_manifest.dart --out=PATH '
      '--pairs-out=PATH',
    );
}
