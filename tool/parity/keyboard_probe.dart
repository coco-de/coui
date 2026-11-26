#!/usr/bin/env dart

/// Presses the keys every Web collection promises and checks where focus
/// lands (#4154) — against the hydrated docs site, not an SSR snapshot.
///
/// The key sequences and their expected results live in
/// `src/web/keyboard_probe_spec.dart`; this is the browser half that plays
/// them. See that file for why the check is the focus result rather than
/// whether a handler is registered.
///
/// Usage:
///   # a built docs_site served over HTTP (`jaspr build` output)
///   dart run tool/parity/keyboard_probe.dart --url=http://localhost:8080
///   dart run tool/parity/keyboard_probe.dart --component=tree --component=menu
///
/// Flags:
///   --url=`<base>`          Base URL (default: http://localhost:8080)
///   --component=`<slug>`    Only this spec (repeatable; default: all)
///   --out=`<path>`          Also write a Markdown report here
///
/// Exits 1 when any step does not land where its spec says, 2 on usage
/// errors.
library;

import 'dart:io';

import '../browser_launch.dart';
import 'src/web/keyboard_probe.dart';
import 'src/web/keyboard_probe_spec.dart';

const _kDefaultBaseUrl = 'http://localhost:8080';

/// Viewport for the run — a desktop width, so no example is laid out for a
/// narrow screen.
const _kViewportWidth = 1440;
const _kViewportHeight = 1200;

Future<void> main(List<String> args) async {
  var baseUrl = _kDefaultBaseUrl;
  String? out;
  final only = <String>{};
  for (final arg in args) {
    if (arg.startsWith('--url=')) {
      baseUrl = arg.substring('--url='.length);
    } else if (arg.startsWith('--component=')) {
      only.add(arg.substring('--component='.length));
    } else if (arg.startsWith('--out=')) {
      out = arg.substring('--out='.length);
    } else {
      stderr.writeln('unknown argument: $arg');
      exitCode = 2;
      return;
    }
  }

  final specs = [
    for (final spec in kKeyboardProbeSpecs)
      if (only.isEmpty || only.contains(spec.component)) spec,
  ];
  final unknown = only.difference({for (final s in specs) s.component});
  if (unknown.isNotEmpty) {
    stderr.writeln('no keyboard probe spec for: ${unknown.join(', ')}');
    exitCode = 2;
    return;
  }

  final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
  final browser = await launchCaptureBrowser(
    width: _kViewportWidth,
    height: _kViewportHeight,
  );
  final results = <KeyboardProbeResult>[];
  try {
    for (final spec in specs) {
      // A fresh page per spec: the probe binds collection labels on
      // `window`, and focus left over from one page must not leak into
      // the next.
      final page = await browser.newPage();
      try {
        final result = await runKeyboardProbe(
          page,
          baseUrl: base,
          spec: spec,
        );
        results.add(result);
        stdout.writeln(
          '${result.passed ? 'PASS' : 'FAIL'}  ${spec.component} '
          '(${spec.steps.length} keys)',
        );
        for (final failure in result.failures) {
          stdout.writeln('      $failure');
        }
      } finally {
        await page.close();
      }
    }
  } finally {
    await browser.close();
  }

  final failed = results.where((r) => !r.passed).toList();
  stdout.writeln(
    '\n${results.length - failed.length}/${results.length} collections '
    'honour their keys',
  );
  if (out != null) File(out).writeAsStringSync(_report(results));
  if (failed.isNotEmpty) exitCode = 1;
}

String _report(List<KeyboardProbeResult> results) {
  final buffer = StringBuffer()
    ..writeln('## Keyboard probe (hydrated docs site)')
    ..writeln()
    ..writeln('| Component | Keys | Result |')
    ..writeln('|---|---|---|');
  for (final result in results) {
    final failures = [
      for (final failure in result.failures)
        'step ${failure.step}: ${failure.message}',
    ];
    final verdict = result.passed ? '✅' : '❌ ${failures.join('<br>')}';
    buffer.writeln(
      '| `${result.spec.component}` | ${result.spec.steps.length} | '
      '${verdict.replaceAll('|', r'\|')} |',
    );
  }
  return buffer.toString();
}
