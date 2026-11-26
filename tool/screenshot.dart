#!/usr/bin/env dart

/// CoUI Component Screenshot Tool.
///
/// Captures visual renders of docs_site component pages for
/// Flutter/Web parity verification. Waits for Flutter Web to
/// fully hydrate (via `flutter-first-frame` event) before
/// taking the shot so dynamic content isn't cut off.
///
/// Usage:
///   # docs_site must be running (default http://localhost:8080)
///   cd docs_site && dart run jaspr serve
///
///   # in another terminal
///   dart run tool/screenshot.dart resizable
///   dart run tool/screenshot.dart resizable --theme=dark
///   dart run tool/screenshot.dart resizable --out=/tmp/r.png --height=2400
///   dart run tool/screenshot.dart --path=/ --style=neoBrutalism
///
/// Flags:
///   --path=`<site path>`      Capture a site page that is not a component
///                             (e.g. `/`, `/components-overview`) instead
///                             of `/components/<component>`. Must start
///                             with `/`. Replaces the component argument.
///   --theme=light|dark|both   Theme(s) to render (default: both)
///   --style=`<id>`            Surface style to render under (e.g.
///                             `neoBrutalism`). Omit for the default
///                             style. Set as `data-coui-style` on the
///                             document, the same attribute the
///                             stylesheet keys off, so a preset is
///                             captured the way a user would see it.
///   --out=`<path>`            Output path
///                             (default: /tmp/{component}-{theme}.png).
///                             `{label}`, `{theme}` and `{style}` are
///                             substituted per file (`{label}` is the
///                             slug or the folded path, `index` for `/`;
///                             `{style}` is `default` when --style is
///                             omitted).
///   --url=`<base>`            Base URL (default: http://localhost:8080)
///   --selector=`<css>`        Capture only this element (default: full page)
///                             Example: --selector=.live-preview
///   --width=`<px>`            Viewport width (default: 1600)
///   --height=`<px>`           Viewport height (default: 2400)
///   --full-page=true|false    Capture full scrollable page (default: true,
///                             ignored when --selector is provided)
///   --timeout=`<ms>`          Max wait for Flutter first frame
///                             (default: 30000).
///
/// Capture conditions (#3378): alongside `<out>.png`, this tool always
/// writes `<out-without-ext>.conditions.json` — the renderer (CanvasKit/
/// Skwasm/none), Flutter/Dart SDK version, Chrome version, device pixel
/// ratio, and viewport actually used for that capture. A screenshot
/// captured under a silently different SDK/renderer/DPR is a different
/// fact than "the component changed" — recording the conditions is how a
/// baseline promotion decision tells the two apart later.
library;

import 'dart:convert';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';

import 'browser_launch.dart';
import 'screenshot_target.dart';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const _kDefaultBaseUrl = 'http://localhost:8080';
const _kDefaultWidth = 1600;
const _kDefaultHeight = 2400;
const _kDefaultTimeoutMs = 30000;
const _kStabilizationDelay = Duration(seconds: 2);

/// Flutter/Dart SDK version strings, resolved once per process — `flutter
/// --version --machine` shells out, so a `--theme=both` run (two captures)
/// or a caller looping over many components shares one lookup rather than
/// paying the process-spawn cost per screenshot.
({String flutterVersion, String dartVersion})? _sdkVersionCache;

// ---------------------------------------------------------------------------
// Entry
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final flags = _parseFlags(args);
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final target = (
    component: positional.isEmpty ? null : positional.first,
    path: flags['path'],
  );
  final problem = screenshotPageProblem(target);
  if (problem != null) {
    stderr.writeln(problem);
    _printUsage();
    exit(1);
  }

  final themeFlag = flags['theme'] ?? 'both';
  final width = int.parse(flags['width'] ?? '$_kDefaultWidth');
  final height = int.parse(flags['height'] ?? '$_kDefaultHeight');
  final timeoutMs = int.parse(flags['timeout'] ?? '$_kDefaultTimeoutMs');
  final baseUrl = flags['url'] ?? _kDefaultBaseUrl;
  final outTemplate = flags['out'];
  final selector = flags['selector'];
  final surfaceStyle = flags['style'];
  final fullPage = flags['full-page'] != 'false' && selector == null;

  final themes = switch (themeFlag) {
    'both' => const ['light', 'dark'],
    'light' => const ['light'],
    'dark' => const ['dark'],
    _ => throw ArgumentError(
      '--theme must be light|dark|both, got: $themeFlag',
    ),
  };

  final label = screenshotLabel(target);
  final url = screenshotUrl(target, baseUrl: baseUrl);
  for (final theme in themes) {
    final out = screenshotOutPath(
      label: label,
      theme: theme,
      surfaceStyle: surfaceStyle,
      template: outTemplate,
    );
    await _capture(
      target: target,
      label: label,
      url: url,
      theme: theme,
      surfaceStyle: surfaceStyle,
      width: width,
      height: height,
      timeoutMs: timeoutMs,
      out: out,
      fullPage: fullPage,
      selector: selector,
    );
  }
}

Future<void> _capture({
  required ScreenshotPage target,
  required String label,
  required String url,
  required String theme,
  required String? surfaceStyle,
  required int width,
  required int height,
  required int timeoutMs,
  required String out,
  required bool fullPage,
  required String? selector,
}) async {
  stdout.writeln('[capture] $label ($theme) @ $url');

  final browser = await launchCaptureBrowser(width: width, height: height);

  try {
    final page = await browser.newPage();

    // docs_site uses `data-theme="dark"` on <html>, driven by localStorage.
    // Pre-set storage BEFORE navigation so initial paint uses the right theme.
    await page.evaluateOnNewDocument(
      "localStorage.setItem('theme', '$theme');",
    );
    // Fallback: also set media feature for components that listen to it.
    if (theme == 'dark') {
      await page.emulateMediaFeatures([
        MediaFeature.prefersColorsScheme('dark'),
      ]);
    }

    final _ = await page.goto(url, wait: .load);

    // Ensure `<html data-theme="...">` matches requested theme (docs_site
    // toggle may run after page load; we force it to avoid races).
    await page.evaluate<void>(
      "(theme) => document.documentElement.setAttribute('data-theme', theme)",
      args: [theme],
    );

    // The surface style is a plain document attribute — the same one the
    // switcher writes — so setting it here renders the preset exactly as a
    // user selecting it would. Absent means the default style, which is
    // expressed by the attribute being absent rather than by a value.
    if (surfaceStyle != null) {
      await page.evaluate<void>(
        "(id) => document.documentElement.setAttribute('data-coui-style', id)",
        args: [surfaceStyle],
      );
      // Let two frames pass before asking which transitions are running.
      // The style recalculation that starts them happens on the next
      // frame, not at the attribute write — queried in the same tick,
      // `getAnimations()` comes back empty and the wait below resolves at
      // once, so the capture lands mid-fade. A computed-style read taken
      // too early returns the previous style's values the same way, which
      // is how a preset can be measured as "identical to default".
      await page.evaluate<void>(
        '() => new Promise((resolve) => '
        'requestAnimationFrame(() => requestAnimationFrame(resolve)))',
      );
      // Switching the attribute starts a cross-fade, and a capture taken
      // during it shows neither style — the shadow layers interpolate,
      // so a stack the new style adds is caught at zero size and zero
      // alpha. Measured: reading immediately after the switch reports
      // the rim as `oklab(0 0 0 / 0) 0px 0px 0px 0px inset`.
      //
      // Waiting on the transitions themselves rather than on a fixed
      // delay, filtered to `CSSTransition` so an indefinite animation —
      // a spinner, a shimmer — cannot hold the capture forever.
      await page.evaluate<void>(
        '''
(timeoutMs) => Promise.race([
          Promise.all(
            document.getAnimations()
              .filter((a) => a.constructor.name === 'CSSTransition')
              .map((a) => a.finished.catch(() => {})),
          ),
          new Promise((resolve) => setTimeout(resolve, timeoutMs)),
        ])''',
        args: [timeoutMs],
      );
    }

    // Wait for Flutter first-frame (embedded flutter views broadcast this).
    try {
      final _ = await page.evaluate<bool>(
        '''
(timeoutMs) => new Promise((resolve) => {
          const hasGlass = () => !!document.querySelector('flutter-view, flt-glass-pane');
          if (hasGlass()) return resolve(true);
          const timer = setTimeout(() => resolve(false), timeoutMs);
          const observer = new MutationObserver(() => {
            if (hasGlass()) { clearTimeout(timer); resolve(true); }
          });
          observer.observe(document.body, { childList: true, subtree: true });
        })''',
        args: [timeoutMs],
      );
    } on Exception catch (_) {
      // Page may not embed Flutter — fine.
    }

    // Extra stabilization for layout + image loading + Flutter compositor.
    await Future<void>.delayed(_kStabilizationDelay);

    List<int> bytes;
    if (selector != null) {
      final el = await page.$(selector);
      bytes = await el.screenshot(format: .png);
    } else {
      bytes = await page.screenshot(
        format: .png,
        fullPage: fullPage,
      );
    }
    final _ = await File(out).writeAsBytes(bytes);
    stdout.writeln('[capture] saved: $out');

    final conditions = await _captureConditions(
      page: page,
      browser: browser,
      target: target,
      theme: theme,
      surfaceStyle: surfaceStyle,
      url: url,
      width: width,
      height: height,
    );
    final conditionsPath = _conditionsPathFor(out);
    File(
      conditionsPath,
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(conditions));
    stdout.writeln('[capture] conditions: $conditionsPath');
  } finally {
    await browser.close();
  }
}

/// Gathers this capture's reproducibility-relevant conditions (#3378) —
/// renderer, SDK versions, Chrome version, device pixel ratio, viewport.
/// Called after the screenshot itself so a failure here never blocks the
/// PNG from being written.
Future<Map<String, Object?>> _captureConditions({
  required Page page,
  required Browser browser,
  required ScreenshotPage target,
  required String theme,
  required String? surfaceStyle,
  required String url,
  required int width,
  required int height,
}) async {
  final sdk = _sdkVersion();
  final renderer = await _detectFlutterRenderer(page);
  final devicePixelRatio = await page.evaluate<num>(
    '() => window.devicePixelRatio',
  );
  final chromeVersion = await browser.version;

  return {
    'component': target.component,
    'path': target.path,
    'theme': theme,
    'surfaceStyle': surfaceStyle,
    'url': url,
    'capturedAt': DateTime.now().toUtc().toIso8601String(),
    'renderer': renderer,
    'flutterVersion': sdk.flutterVersion,
    'dartVersion': sdk.dartVersion,
    'chromeVersion': chromeVersion,
    'devicePixelRatio': devicePixelRatio,
    'viewport': {'width': width, 'height': height},
  };
}

/// `flutter --version --machine`, cached process-wide (see
/// [_sdkVersionCache]'s own doc comment for why).
({String flutterVersion, String dartVersion}) _sdkVersion() {
  final cached = _sdkVersionCache;
  if (cached != null) return cached;

  const unknown = (flutterVersion: 'unknown', dartVersion: 'unknown');
  final result = Process.runSync('flutter', ['--version', '--machine']);
  if (result.exitCode != 0) {
    _sdkVersionCache = unknown;
    return unknown;
  }

  final Map<String, Object?> decoded;
  try {
    decoded = jsonDecode(result.stdout as String) as Map<String, Object?>;
  } on FormatException {
    _sdkVersionCache = unknown;
    return unknown;
  }

  final resolved = (
    flutterVersion: decoded['frameworkVersion'] as String? ?? 'unknown',
    dartVersion: decoded['dartSdkVersion'] as String? ?? 'unknown',
  );
  _sdkVersionCache = resolved;
  return resolved;
}

/// Which Flutter web renderer actually loaded on this page, inferred from
/// which asset it fetched — `--web-renderer` no longer exists as a build
/// flag (current axis is default-CanvasKit vs `--wasm`/Skwasm, #3378), so
/// this reads the ground truth from the page itself rather than trusting
/// whatever the capture caller assumed the build used.
Future<String> _detectFlutterRenderer(Page page) async {
  final resourceUrls = await page.evaluate<List<Object?>>(
    "() => performance.getEntriesByType('resource').map((e) => e.name)",
  );
  final urls = resourceUrls.cast<String>();
  if (urls.any((u) => u.contains('canvaskit'))) return 'canvaskit';
  if (urls.any((u) => u.contains('skwasm'))) return 'skwasm';

  final hasFlutterEmbed = await page.evaluate<bool>(
    "() => !!document.querySelector('flutter-view, flt-glass-pane')",
  );
  return hasFlutterEmbed
      ? 'unknown (flutter embed present, no canvaskit/skwasm resource matched)'
      : 'n/a (no flutter embed on this page)';
}

/// `/tmp/button-light.png` → `/tmp/button-light.conditions.json` — same
/// stem as the PNG so the two files are found together.
String _conditionsPathFor(String outPngPath) {
  if (outPngPath.endsWith('.png')) {
    return '${outPngPath.substring(0, outPngPath.length - 4)}.conditions.json';
  }
  return '$outPngPath.conditions.json';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, String> _parseFlags(List<String> args) {
  final map = <String, String>{};
  for (final a in args) {
    if (!a.startsWith('--')) continue;
    final eq = a.indexOf('=');
    if (eq < 0) {
      map[a.substring(2)] = 'true';
    } else {
      map[a.substring(2, eq)] = a.substring(eq + 1);
    }
  }
  return map;
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tool/screenshot.dart <component> [flags]
  dart run tool/screenshot.dart --path=<site path> [flags]

Flags:
  --path=<site path>   Capture a non-component page, e.g. / or /components-overview
  --theme=light|dark|both  Theme (default: both)
  --style=<id>         Surface style (data-coui-style), e.g. neoBrutalism
  --out=<path>         Output path; {label}, {theme} and {style} are substituted
                       (default: /tmp/<component>[-<style>]-<theme>.png)
  --url=<base>         Base URL (default: http://localhost:8080)
  --width=<px>         Viewport width (default: $_kDefaultWidth)
  --height=<px>        Viewport height (default: $_kDefaultHeight)
  --full-page=true|false  Full scrollable page capture (default: true)
  --timeout=<ms>       Max wait for Flutter first frame (default: $_kDefaultTimeoutMs)
''');
}
