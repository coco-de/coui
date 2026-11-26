#!/usr/bin/env dart

// ArgumentError/StateError from ParityManifest.resolve() are this CLI's
// "bad usage" signal, not a programming bug — catching them at the entry
// point and turning them into a clean exit code is the intended use.
// ignore_for_file: avoid_catching_errors

/// ParityManifest CLI — derives the verification matrix from the catalog
/// and surface-style enum. See `src/manifest/parity_manifest.dart` for the
/// derivation itself; this file is only argument parsing + JSON I/O.
///
/// Usage:
///   `dart run tool/parity/manifest.dart --out=/tmp/manifest.json`
///   `dart run tool/parity/manifest.dart --tier=t1 --out=/tmp/manifest.t1.json`
///   `dart run tool/parity/manifest.dart --components=dialog,command --out=/tmp/m.json`
///   `dart run tool/parity/manifest.dart --pruned --out=/tmp/pruned.json`
///   `dart run tool/parity/manifest.dart --tier=t1 --changed-from=origin/main --out=/tmp/m.json`
///
/// Flags:
///   --tier=t1|t2           Restrict to one tier (default: both).
///   --components=`<csv>`   Restrict to these catalog slugs (default: all).
///                          Mutually exclusive with --changed-from.
///   --changed-from=REF     Incremental selection (#3610) — derives the
///                          component filter from `git diff --name-only
///                          REF...HEAD` instead of a hand-typed list.
///                          A path outside any component's own directory
///                          (an infra file, or anything the mapping does
///                          not recognize) makes this fall back to no
///                          restriction at all — "모르면 전체". No changed
///                          path touching any component exits early with
///                          an empty manifest. This is the entry point
///                          Epic F's PR gate job (#3618) calls.
///   --pruned                Output the combinations pruning excluded instead
///                          of the verification matrix — the nightly
///                          re-verification target (#3620, Epic F).
///   --out=`<path>`         Required. Where to write the manifest JSON.
library;

import 'dart:convert';
import 'dart:io';

import 'src/cli/flags.dart';
import 'src/manifest/changed_components.dart';
import 'src/manifest/material_reach.dart';
import 'src/manifest/parity_manifest.dart';
import 'src/model/parity_tier.dart';

Future<void> main(List<String> args) async {
  final flags = parseFlags(args);
  final outPath = flags['out'];
  if (outPath == null) {
    stderr.writeln('❌ --out=<path> 가 필요하다.');
    _printUsage();
    exit(ParityExitCode.infraFailed);
  }

  ParityTier? tier;
  final tierRaw = flags['tier'];
  if (tierRaw != null) {
    tier = ParityTier.tryParse(tierRaw);
    if (tier == null) {
      stderr.writeln('❌ --tier 는 t1|t2 여야 한다 (받은 값: $tierRaw).');
      exit(ParityExitCode.infraFailed);
    }
  }

  List<String>? components;
  try {
    components = parseListFlag(flags, 'components');
  } on ArgumentError catch (e) {
    stderr.writeln('❌ $e');
    exit(ParityExitCode.infraFailed);
  }

  final pruned = flags['pruned'] == 'true';

  final changedFrom = flags['changed-from'];
  if (changedFrom != null) {
    if (components != null) {
      stderr.writeln('❌ --changed-from 과 --components 는 동시에 쓸 수 없다.');
      exit(ParityExitCode.infraFailed);
    }

    final changedPaths = _changedPathsFrom(changedFrom);
    final selection = changedComponentsFor(changedPaths);
    switch (selection) {
      case ChangedComponentNone():
        stdout.writeln(
          '[manifest] --changed-from=$changedFrom: 변경된 컴포넌트 없음 — '
          '매트릭스 비어있음, 조기 종료',
        );
        final outFile = File(outPath)..parent.createSync(recursive: true);
        outFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({'entries': <Object?>[]}),
        );
        exit(ParityExitCode.ok);
      case ChangedComponentFallbackToAll(:final reason):
        stdout.writeln(
          '[manifest] --changed-from=$changedFrom: 전체로 폴백 — $reason',
        );
        components = null;
      case ChangedComponentSet(:final slugs):
        stdout.writeln(
          '[manifest] --changed-from=$changedFrom: '
          '${slugs.length}개 컴포넌트 매칭 (${slugs.join(', ')})',
        );
        components = slugs.toList();
    }
  }

  // The material half of pruning rule 2 is measured, not declared — one
  // server render per (component, variant), ~1 s for the whole catalog
  // (`material_reach.dart`). Reported so a run whose measurement came
  // back empty (an SSR path that stopped emitting the marker) is visible
  // in the log rather than silently pruning every material preset.
  final materialReach = await measureMaterialReachedSlugs();
  stdout.writeln(
    '[manifest] material reach: ${materialReach.length}개 컴포넌트의 예제가 '
    '표면 마커를 실제로 렌더한다',
  );

  final List<Object?> entriesJson;
  try {
    final entries = pruned
        ? ParityManifest.resolvePruned(
            materialReach: materialReach,
            tier: tier,
            components: components,
          )
        : ParityManifest.resolve(
            materialReach: materialReach,
            tier: tier,
            components: components,
            source: changedFrom != null ? .derivedFromDiff : .handTyped,
          );
    // Only the diff-derived matrix can reach here empty — a hand-typed
    // filter throws above, and `--pruned` has its own reasons to be empty
    // that have nothing to do with a tier.
    if (entries.isEmpty && !pruned && changedFrom != null) {
      // Names what was changed and skipped rather than reporting a bare
      // zero. "0개 항목" alone reads the same whether nothing was in scope
      // or the gate declined to look — and the second is what this branch
      // is. The gate is allowed to check nothing; it is not allowed to be
      // quiet about which components it passed over.
      final skipped = (components ?? const <String>[]).join(', ');
      stdout.writeln(
        '[manifest] --changed-from=$changedFrom: 변경된 컴포넌트가 전부 '
        '${tier?.name ?? '요청한 tier'} 밖 — 검사 대상 없음, 조기 종료'
        '${skipped.isEmpty ? '' : ' (건너뛴 컴포넌트: $skipped)'}',
      );
    }
    entriesJson = entries.map((e) => e.toJson()).toList();
  } on ArgumentError catch (e) {
    stderr.writeln('❌ $e');
    exit(ParityExitCode.infraFailed);
  } on StateError catch (e) {
    stderr.writeln('❌ $e');
    exit(ParityExitCode.infraFailed);
  }

  final outFile = File(outPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({'entries': entriesJson}),
  );

  final label = pruned ? 'pruned' : 'manifest';
  stdout.writeln('[$label] ${entriesJson.length}개 항목 → $outPath');
  exit(ParityExitCode.ok);
}

/// Repo-root-relative paths changed between [ref] and `HEAD`, via
/// `git diff --name-only <ref>...HEAD` (three-dot: what this branch itself
/// did since it forked from [ref] — the same diff a PR's "Files changed"
/// tab shows, not the unrelated history [ref] has moved past since).
///
/// Exits with [ParityExitCode.infraFailed] on git failure (bad ref, not a
/// repo, …) — that is this CLI's "the tool itself is broken" signal, kept
/// distinct from "there were no changes" (an empty, successful diff).
List<String> _changedPathsFrom(String ref) {
  final result = Process.runSync('git', ['diff', '--name-only', '$ref...HEAD']);
  if (result.exitCode != 0) {
    stderr.writeln('❌ git diff --name-only $ref...HEAD 실패: ${result.stderr}');
    exit(ParityExitCode.infraFailed);
  }
  return (result.stdout as String)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

void _printUsage() {
  stderr
    ..writeln('Usage:')
    ..writeln('  dart run tool/parity/manifest.dart --out=PATH [flags]')
    ..writeln()
    ..writeln('Flags:')
    ..writeln('  --tier=t1|t2         Restrict to one tier (default: both)')
    ..writeln('  --components=CSV     Restrict to these catalog slugs')
    ..writeln('                       (default: all; exclusive with')
    ..writeln('                       --changed-from)')
    ..writeln('  --changed-from=REF   Derive the component filter from')
    ..writeln('                       `git diff --name-only REF...HEAD`')
    ..writeln('  --pruned             Output pruned combinations instead of')
    ..writeln('                       the verification matrix');
}
