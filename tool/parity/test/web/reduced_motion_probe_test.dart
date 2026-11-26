// EPIC-004 (#3597) child #3614 — ReducedMotionProbe (Web half).
//
// FR-019: emulating `prefers-reduced-motion: reduce` should zero every
// `--coui-duration-*` variable in the transition tier
// (`theme_config.dart`'s `_reducedMotionCssVariables`, scoped by
// `CoreReducedMotion.transitionCeilingMs`) while leaving display-tier
// variables (`Loading`'s spinner, `CoreDuration.ms1000`) untouched.
//
// NFR-005 role separation: doesn't re-check "does the source reference a
// token" (`check_motion_alias_tier.sh` already does) — only "does the
// rendered/computed behaviour honour the reduced-motion policy".
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/transition_contract_probe.dart';

/// Same probe as `offline_tailwind_harness_test.dart` (SPIKE-3) — reused
/// rather than reimplemented so a missing local Chrome degrades this
/// probe's own test the same way it already degrades that one.
String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();

  /// A real `CoUIWeb` root (so `enableThemeAnimation`'s crossfade rule is
  /// mounted) plus the offline-vendored Tailwind head, wrapping [child].
  Component harness(Component child) => .fragment([
    Document.head(
      children: [
        Component.element(tag: 'script', children: [RawText(vendoredScript)]),
        Component.element(
          tag: 'script',
          children: [RawText(themeConfig.tailwindConfig)],
        ),
        Component.element(
          tag: 'style',
          children: [RawText(themeConfig.cssVariables)],
        ),
      ],
    ),
    CoUIWeb(theme: .coui, child: child),
  ]);

  /// Writes [bodyHtml] to a temp file and loads it offline in headless
  /// Chrome with `prefers-reduced-motion` emulated per [reduce] — the
  /// caller reads whatever computed style it needs and is responsible for
  /// closing the returned browser.
  Future<(pptr.Browser, pptr.Page)> loadOffline(
    String bodyHtml,
    String tempFileSuffix, {
    required bool reduce,
  }) async {
    // A directory unique to this call — a fixed name under the shared
    // `Directory.systemTemp` lets concurrent jobs on one host delete each
    // other's file mid-`goto` (net::ERR_FILE_NOT_FOUND).
    final tempDir = Directory.systemTemp.createTempSync(
      'coui-parity-reduced-motion-probe-',
    );
    try {
      final tempFile = File(p.join(tempDir.path, '$tempFileSuffix.html'))
        ..writeAsStringSync(bodyHtml);

      final browser = await pptr.puppeteer.launch(executablePath: chromePath);
      final page = await browser.newPage();
      await page.emulateMediaFeatures([
        pptr.MediaFeature.prefersReducedMotion(
          reduce ? 'reduce' : 'no-preference',
        ),
      ]);
      await page.setOfflineMode(true);
      final _ = await page.goto(
        Uri.file(tempFile.path).toString(),
        wait: pptr.Until.load,
      );

      return (browser, page);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  }

  group(
    'ReducedMotionProbe — Web 전환 tier 억제 · 표시 tier 보존 (#3614, Chrome 필요)',
    () {
      testServer(
        '전환 tier — prefers-reduced-motion:reduce 하에서 서페이스 마커의 '
        'background-color 크로스페이드 duration 이 0 으로 억제된다',
        (tester) async {
          tester.pumpComponent(
            harness(const OutlinedContainer(id: 'probe', child: Text('x'))),
          );
          final response = await tester.request('/');

          final (browser, page) = await loadOffline(
            response.body,
            'transition-tier',
            reduce: true,
          );
          try {
            final contract = await readComputedTransitionContract(
              page,
              selector: '#probe',
            );
            expect(
              contract.declaresTransitionFor('background-color'),
              isFalse,
              reason:
                  'reduced-motion should collapse the transition-tier '
                  '--coui-duration-150 variable to 0ms, which makes this '
                  '"no transition declared" from `declaresTransitionFor`\'s '
                  'point of view (duration 0 = not declared). Computed: '
                  '$contract',
            );
          } finally {
            await browser.close();
          }
        },
        skip: chromePath == null,
        timeout: const Timeout(Duration(seconds: 60)),
      );

      testServer(
        '표시 tier — prefers-reduced-motion:reduce 하에서도 Loading(spinner) '
        '의 animation-duration(CoreDuration.ms1000)은 그대로 보존된다',
        (tester) async {
          tester.pumpComponent(harness(const Loading(id: 'probe')));
          final response = await tester.request('/');

          final (browser, page) = await loadOffline(
            response.body,
            'display-tier',
            reduce: true,
          );
          try {
            final json = await page.evaluate<String>(
              '''
() => {
  const el = document.querySelector('#probe .co-loading-spinner');
  if (!el) throw new Error('spinner sweep element not found');
  const cs = getComputedStyle(el);
  return JSON.stringify({ animationDuration: cs.animationDuration });
}
''',
            );
            final animationDuration =
                (jsonDecode(json) as Map<String, dynamic>)['animationDuration']
                    as String;
            expect(
              animationDuration,
              '1s',
              reason:
                  'display-tier CoreDuration.ms1000 must survive reduced '
                  'motion — a frozen spinner is itself an accessibility '
                  'failure. Computed animation-duration: $animationDuration',
            );
          } finally {
            await browser.close();
          }
        },
        skip: chromePath == null,
        timeout: const Timeout(Duration(seconds: 60)),
      );
    },
  );
}
