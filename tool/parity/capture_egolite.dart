#!/usr/bin/env dart

/// Explicit native Ego capture; uses an existing agent-owned space and page.
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;

import 'src/cli/flags.dart';
import 'src/model/matrix_entry.dart';
import 'src/web/ego_capture_backend.dart';
import 'src/web/local_fonts.dart';
import 'src/web/local_icons.dart';
import 'src/web/offline_tailwind_harness.dart';
import 'src/web/web_capture_backend.dart';

Future<void> main(List<String> args) async {
  try {
    await _capture(args);
  } on Object catch (error) {
    stderr.writeln('Ego capture infrastructure failure: $error');
    exitCode = ParityExitCode.infraFailed;
  }
}

Future<void> _capture(List<String> args) async {
  final flags = parseFlags(args);
  final boxOutPath = flags['box-observations'];
  if (boxOutPath != null && boxOutPath.isEmpty) {
    throw ArgumentError(
      '--box-observations requires an owned output directory',
    );
  }
  final boxOut = boxOutPath == null ? null : Directory(boxOutPath);
  final space = int.tryParse(flags['space'] ?? '');
  if (space == null ||
      ['manifest', 'out', 'work', 'page'].any((key) => flags[key] == null)) {
    stderr.writeln(
      'Required: --manifest=PATH --out=DIR --work=OWNED_DIR '
      '--space=ID --page=LABEL',
    );
    exitCode = ParityExitCode.infraFailed;
    return;
  }
  final decoded =
      jsonDecode(File(flags['manifest']!).readAsStringSync()) as Map;
  final entries = [
    for (final raw in decoded['entries'] as List)
      MatrixEntry.fromJson((raw as Map).cast<String, Object?>()),
  ];
  final out = Directory(flags['out']!)..createSync(recursive: true);
  final work = Directory(flags['work']!)..createSync(recursive: true);
  final config = ThemeConfig.defaults();
  final tailwind = loadVendoredTailwindScript();
  final fonts = buildLocalFontFaceCss();
  final icons = buildLocalIconifyHeadHtml();
  final failures = <String, String>{};
  final boxCounts = <String, int>{};
  var done = 0;
  for (final entry in entries) {
    done++;
    try {
      final result = await captureEgoEntry(
        entry: entry,
        additiveBoxObservations: boxOut != null,
        sourceManifest: File(flags['manifest']!),
        space: space,
        page: flags['page']!,
        workDir: Directory('${work.path}/${entry.key}'),
        themeConfig: config,
        vendoredTailwindScript: tailwind,
        fontFaceCss: fonts,
        iconifyHeadHtml: icons,
      );
      writeWebCaptureArtifacts(
        result: result,
        entry: entry,
        outDir: out,
        boxObservationOutDir: boxOut,
      );
      for (final observation in result.boxPaddingByRole.values) {
        final status = observation['status']! as String;
        boxCounts.update(status, (count) => count + 1, ifAbsent: () => 1);
      }
    } on Object catch (error) {
      failures[entry.key] = '$error';
      stderr.writeln('${entry.key}: $error');
      // A native failure may mean control was handed back to the user.
      // Stop rather than retrying another entry against that page.
      break;
    }
    if (done % 25 == 0 || done == entries.length) {
      stdout.writeln('[capture_egolite] $done/${entries.length}');
    }
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
  File('${out.path}/egolite-capture-exit.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'entries': entries.length,
      'attempted': done,
      'succeeded': done - failures.length,
      'unattempted': entries.length - done,
      'failures': failures,
      'backend': 'Native Ego Lite; existing space/page only',
      'space': space,
      'page': flags['page'],
    }),
  );
  exitCode = failures.isEmpty ? ParityExitCode.ok : ParityExitCode.infraFailed;
}
