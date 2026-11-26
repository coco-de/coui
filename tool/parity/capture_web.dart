#!/usr/bin/env dart

/// WebCaptureBackend CLI (#3605) — SSR (jaspr) → offline harness → puppeteer
/// capture, for every entry in a manifest produced by
/// `tool/parity/manifest.dart` (#3604).
///
/// Usage:
///   `dart run tool/parity/capture_web.dart --manifest=/tmp/manifest.json`
///   `dart run tool/parity/capture_web.dart --manifest=... --keep-harness`
///
/// Flags:
///   --manifest=`<path>`  Required. Manifest JSON from `manifest.dart`.
///   --out=`<dir>`        Where to write `<key>.web.png`/`.json`
///                        (default: `test/parity/captured`).
///   --keep-harness       Don't delete the per-entry harness HTML after
///                        capture (debugging — inspect what was actually
///                        loaded).
///
/// Exit codes: `0` success, `2` infra failure (missing preview registry
/// entry, browser crash, unreadable manifest) — this stage never judges
/// pass/fail against a baseline (that's `compare.dart`, #3607), so exit
/// code `1` never applies here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;

import '../browser_launch.dart';
import 'src/cli/flags.dart';
import 'src/model/matrix_entry.dart';
import 'src/web/local_fonts.dart';
import 'src/web/local_icons.dart';
import 'src/web/offline_tailwind_harness.dart';
import 'src/web/web_capture_backend.dart';

const String _kDefaultOutDir = 'test/parity/captured';
const String _kHarnessDir = 'test/parity/harness/web';

/// Wide enough that Tier1 components (dialogs, popovers, tables) don't
/// clip against the viewport edge before their own bounding box does.
const int _kViewportWidth = 1600;
const int _kViewportHeight = 1200;

/// How often to print a progress line — frequent enough to show the run
/// is alive on a large manifest, sparse enough not to spam a small one.
const int _kProgressInterval = 25;

Future<void> main(List<String> args) async {
  final flags = parseFlags(args);
  final boxOutPath = flags['box-observations'];
  if (boxOutPath != null && boxOutPath.isEmpty) {
    stderr.writeln('--box-observations requires an owned output directory');
    exitCode = ParityExitCode.infraFailed;
    return;
  }
  final boxOut = boxOutPath == null ? null : Directory(boxOutPath);
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

  final outDir = Directory(flags['out'] ?? _kDefaultOutDir);
  final harnessDir = Directory(_kHarnessDir);
  final keepHarness = flags['keep-harness'] == 'true';

  final themeConfig = ThemeConfig.defaults();
  final vendoredTailwindScript = loadVendoredTailwindScript();
  final fontFaceCss = buildLocalFontFaceCss();
  final iconifyHeadHtml = buildLocalIconifyHeadHtml();

  final browser = await launchCaptureBrowser(
    width: _kViewportWidth,
    height: _kViewportHeight,
    softwareRasterization: true,
  );
  final failures = <String, Object>{};
  final boxCounts = <String, int>{};

  try {
    var done = 0;
    for (final entry in entries) {
      try {
        final result = await captureWebEntry(
          browser: browser,
          entry: entry,
          additiveBoxObservations: boxOut != null,
          themeConfig: themeConfig,
          vendoredTailwindScript: vendoredTailwindScript,
          fontFaceCss: fontFaceCss,
          iconifyHeadHtml: iconifyHeadHtml,
          harnessDir: harnessDir,
          keepHarness: keepHarness,
        );
        writeWebCaptureArtifacts(
          result: result,
          entry: entry,
          outDir: outDir,
          boxObservationOutDir: boxOut,
        );
        for (final observation in result.boxPaddingByRole.values) {
          final status = observation['status']! as String;
          boxCounts.update(status, (count) => count + 1, ifAbsent: () => 1);
        }
      } on Object catch (e) {
        failures[entry.key] = e;
        stderr.writeln('❌ ${entry.key}: $e');
      }
      done++;
      if (done % _kProgressInterval == 0 || done == entries.length) {
        stdout.writeln('[capture_web] $done/${entries.length}');
      }
    }
  } finally {
    await browser.close();
  }

  if (boxOut != null) {
    boxOut.createSync(recursive: true);
    File('${boxOut.path}/box-observation-completeness.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'entriesExpected': entries.length,
        'sourceCompleteWeb': boxCounts['source-complete'] ?? 0,
        'incomplete': boxCounts['incomplete'] ?? 0,
        'notRequested': boxCounts['not-requested'] ?? 0,
        'captureFailures': failures.keys.toList(),
        'pairGateEvaluated': false,
        'sameQuantityEligibleValidated': 0,
        'canonicalCutover': false,
      }),
    );
  }
  if (failures.isNotEmpty) {
    stderr.writeln(
      '❌ ${failures.length}/${entries.length}건 캡처 실패 — 위 로그 참조.',
    );
    exit(ParityExitCode.infraFailed);
  }

  stdout.writeln(
    '[capture_web] ${entries.length}개 항목 캡처 완료 → ${outDir.path}',
  );
  exit(ParityExitCode.ok);
}

void _printUsage() {
  stderr
    ..writeln('Usage:')
    ..writeln('  dart run tool/parity/capture_web.dart --manifest=PATH [flags]')
    ..writeln()
    ..writeln('Flags:')
    ..writeln('  --out=DIR          Output dir (default: $_kDefaultOutDir)')
    ..writeln('  --keep-harness     Keep the per-entry harness HTML file')
    ..writeln(
      '  --box-observations=DIR  Separate additive padding-source results',
    );
}
