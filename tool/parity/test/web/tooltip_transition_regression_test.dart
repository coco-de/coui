// Regression lock for the enter/exit animation of surface-marked overlays.
//
// `_kSurfaceGeometryTransitionCss` (#3622, `coui_web.dart`) emits a longhand
// `transition-property` list scoped to `.coui-theme-anim .coui-surface`. A
// longhand list *replaces* an earlier one for any element both rules match —
// it never merges — which the emitting file's own comment states as the
// reason it restates the colour set. `Tooltip`'s bubble carries
// `kWebSurfaceMarker` and Tailwind's `transition-all` on the *same* element
// and enters/exits by swapping `opacity-0 scale-90` ↔ `opacity-100
// scale-100`, so the moment that list omits `opacity`/`transform` every
// tooltip snaps in and out with no fade.
//
// Why this file and not `coui_web_theme_animation_test.dart`: that test
// asserts the CSS *string* CoUI emits. A cascade collision is not visible in
// the string — both rules are individually correct and the loss only exists
// once a browser resolves them together against an element carrying both
// class sets. This reads the resolved value, reusing #3612's probe.
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/transition_contract_probe.dart';

/// Same probe as the sibling `transition_contract_probe_test.dart` — reused
/// so a missing local Chrome degrades this test the same way.
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

  /// Renders the exact class pairing that collides: an element inside a
  /// `CoUIWeb` root (so `.coui-theme-anim` is on an ancestor) carrying both
  /// [kWebSurfaceMarker] and `transition-all`, the way `tooltip_style.dart`
  /// composes its bubble.
  Component harness() => .fragment([
    Document.html(attributes: {'data-coui-style': 'neoBrutalism'}),
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
    CoUIWeb(
      theme: .coui,
      child: Component.element(
        tag: 'div',
        id: 'probe',
        classes: '$kWebSurfaceMarker transition-all opacity-0 scale-90',
        children: const [Text('bubble')],
      ),
    ),
  ]);

  group('서페이스 마커 오버레이의 진입/퇴장 전환 회귀 고정 (#3622)', () {
    Future<ComputedTransitionContract> readContract(String bodyHtml) async {
      // Unique per call — a fixed name under the shared temp dir lets
      // concurrent jobs on one host delete each other's file mid-`goto`.
      final tempDir = Directory.systemTemp.createTempSync(
        'coui-parity-tooltip-transition-regression-',
      );
      final tempFile = File(p.join(tempDir.path, 'probe.html'))
        ..writeAsStringSync(bodyHtml);

      try {
        final browser = await pptr.puppeteer.launch(
          executablePath: chromePath,
        );
        try {
          final page = await browser.newPage();
          await page.goto('file://${tempFile.path}', wait: pptr.Until.load);

          return await readComputedTransitionContract(
            page,
            selector: '#probe',
          );
        } finally {
          await browser.close();
        }
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    }

    testServer(
      'geometry 전환 규칙이 opacity/transform 을 치환해 버리지 않는다 — '
      '마커 + transition-all 을 함께 단 요소의 진입/퇴장이 살아 있다',
      (tester) async {
        tester.pumpComponent(harness());
        final response = await tester.request('/');
        final contract = await readContract(response.body);

        // 진입/퇴장을 실제로 그리는 두 property. 하나라도 빠지면 툴팁·팝오버가
        // 페이드 없이 튄다.
        expectTransitionDeclaredForProperty(
          contract,
          'opacity',
          reason: '서페이스 마커 + transition-all 요소의 진입/퇴장(opacity)',
        );
        expectTransitionDeclaredForProperty(
          contract,
          'transform',
          reason: '서페이스 마커 + transition-all 요소의 진입/퇴장(transform)',
        );

        // 회귀 방향이 반대로도 무너지지 않게: geometry 전환(#3622 의 존재
        // 이유)과 색 크로스페이드(#3468)도 같은 요소에서 함께 살아 있어야
        // 한다. 셋 중 하나만 만족시키는 property 목록은 이 단언들 중
        // 하나에서 걸린다.
        expectTransitionDeclaredForProperty(
          contract,
          'border-width',
          reason: '서페이스 프리셋 geometry 크로스페이드 (#3622)',
        );
        expectTransitionDeclaredForProperty(
          contract,
          'background-color',
          reason: '테마 색 크로스페이드 (#3468)',
        );
      },
      skip: chromePath == null,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
