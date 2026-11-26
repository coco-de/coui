#!/usr/bin/env dart

/// Rests the real pointer on a hover-opened trigger of the hydrated docs
/// site and fails when the panel changes state with no input (#4204).
///
/// The spec table and the two-stage verdict live in
/// `src/web/oscillation_probe.dart`; this is the CLI the nightly runs.
///
/// Usage:
///   # a built docs_site served over HTTP (`jaspr build` output)
///   dart run tool/parity/oscillation_probe.dart --url=http://localhost:8080
///   dart run tool/parity/oscillation_probe.dart --component=navigation-menu
///   dart run tool/parity/oscillation_probe.dart --selftest
///
/// Flags:
///   --url=`<base>`          Base URL (default: http://localhost:8080)
///   --component=`<slug>`    Only this spec (repeatable; default: all)
///   --out=`<path>`          Also write a Markdown report here
///   --selftest             Play the probe against built-in fixtures (a
///                          steady panel, a looping one, one with no
///                          handlers) before the real specs, and fail if
///                          any fixture gets the wrong verdict. With
///                          neither `--url` nor `--component`, only the
///                          fixtures run.
///
/// Exits 1 when a spec fails (or a fixture gets the wrong verdict), 2 on
/// usage errors.
library;

import 'dart:io';

import '../browser_launch.dart';
import 'src/web/oscillation_probe.dart';

const _kDefaultBaseUrl = 'http://localhost:8080';

/// Viewport for the run — wide enough that no docs page stacks its
/// preview behind a narrow-screen layout. Same as the keyboard probe.
const _kViewportWidth = 1440;
const _kViewportHeight = 1200;

Future<void> main(List<String> args) async {
  var baseUrl = _kDefaultBaseUrl;
  String? out;
  var selftest = false;
  var urlGiven = false;
  final only = <String>{};
  for (final arg in args) {
    if (arg.startsWith('--url=')) {
      baseUrl = arg.substring('--url='.length);
      urlGiven = true;
    } else if (arg.startsWith('--component=')) {
      only.add(arg.substring('--component='.length));
    } else if (arg.startsWith('--out=')) {
      out = arg.substring('--out='.length);
    } else if (arg == '--selftest') {
      selftest = true;
    } else {
      stderr.writeln('unknown argument: $arg');
      exitCode = 2;
      return;
    }
  }

  final specs = [
    for (final spec in kOscillationProbeSpecs)
      if (only.isEmpty || only.contains(spec.component)) spec,
  ];
  final unknown = only.difference({for (final s in specs) s.component});
  if (unknown.isNotEmpty) {
    stderr.writeln('no oscillation probe spec for: ${unknown.join(', ')}');
    exitCode = 2;
    return;
  }
  // `--selftest` alone checks the detector without a docs site; the
  // specs run as well when a site was named.
  final runSpecs = !selftest || urlGiven || only.isNotEmpty;

  final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
  final browser = await launchCaptureBrowser(
    width: _kViewportWidth,
    height: _kViewportHeight,
  );
  final selftestFailures = <String>[];
  final results = <OscillationProbeResult>[];
  try {
    if (selftest) {
      selftestFailures.addAll(await oscillationSelfTestFailures(browser));
      stdout.writeln(
        selftestFailures.isEmpty
            ? 'PASS  selftest (every fixture got its verdict)'
            : 'FAIL  selftest',
      );
      for (final failure in selftestFailures) {
        stdout.writeln('      $failure');
      }
    }
    if (runSpecs) {
      for (final spec in specs) {
        // A fresh page per spec: the probe binds its observer on `window`.
        final page = await browser.newPage();
        try {
          final result = await runOscillationProbe(
            page,
            baseUrl: base,
            spec: spec,
          );
          results.add(result);
          final observation = result.observation;
          stdout.writeln(
            '${result.passed ? 'PASS' : 'FAIL'}  ${spec.component} '
            '(opened: ${observation.opened}, '
            'changes: ${observation.changes.length})',
          );
          for (final failure in result.failures) {
            stdout.writeln('      $failure');
          }
        } finally {
          await page.close();
        }
      }
    }
  } finally {
    await browser.close();
  }

  final failed = results.where((r) => !r.passed).toList();
  if (runSpecs) {
    stdout.writeln(
      '\n${results.length - failed.length}/${results.length} hover panels '
      'held still under a resting pointer',
    );
  }
  if (out != null) {
    File(out).writeAsStringSync(_report(results, selftestFailures, selftest));
  }
  if (failed.isNotEmpty || selftestFailures.isNotEmpty) exitCode = 1;
}

String _report(
  List<OscillationProbeResult> results,
  List<String> selftestFailures,
  bool selftest,
) {
  final buffer = StringBuffer()
    ..writeln('## Oscillation probe (hydrated docs site)')
    ..writeln();
  if (selftest) {
    buffer
      ..writeln(
        selftestFailures.isEmpty
            ? 'Self-test: ✅ every fixture got its verdict.'
            : 'Self-test: ❌ ${selftestFailures.join('<br>')}',
      )
      ..writeln();
  }
  buffer
    ..writeln('| Component | Opened | Changes at rest | Result |')
    ..writeln('|---|---|---|---|');
  for (final result in results) {
    final observation = result.observation;
    final verdict = result.passed ? '✅' : '❌ ${result.failures.join('<br>')}';
    buffer.writeln(
      '| `${result.spec.component}` | ${observation.opened} | '
      '${observation.changes.length} | ${verdict.replaceAll('|', r'\|')} |',
    );
  }

  return buffer.toString();
}
