// EPIC-004 (#3597) child #3612 — WebTransitionContractProbe.
//
// Proves `transition_contract_probe.dart` against the real
// `CoUIWeb`/`OutlinedContainer` production markup (SSR'd via `jaspr_test`,
// not hand-written HTML) loaded offline in headless Chrome — the same
// vendored-Tailwind technique SPIKE-3 (#3602) established.
import 'dart:async';
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

  /// Renders a real `CoUIWeb` + `OutlinedContainer` tree via `jaspr_test`
  /// SSR, with [surfaceStyleId] baked directly onto `<html
  /// data-coui-style=…>` — mirroring what a client-side
  /// `SurfaceStyleScope.setSurfaceStyle` call would set at runtime. This
  /// harness has no compiled client bootstrap to make that call itself
  /// (see the library doc comment on why a static bake is sufficient for a
  /// *declared* transition contract), so the attribute is authored directly
  /// into the SSR'd HTML the same way `offline_tailwind_harness.dart`
  /// already bakes `data-theme`.
  Component harness(CoreSurfaceStyleId surfaceStyleId) => .fragment([
    Document.html(attributes: {'data-coui-style': surfaceStyleId.name}),
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
      child: const OutlinedContainer(
        id: 'probe',
        child: Text('probe content'),
      ),
    ),
  ]);

  group('WebTransitionContractProbe 배선 (#3612)', () {
    testServer(
      'CoUIWeb + OutlinedContainer 를 SSR 하면 서페이스 마커·크로스페이드 클래스가 '
      '실제로 출력에 담긴다 — probe 대상이 실재함을 확인',
      (tester) async {
        tester.pumpComponent(harness(.neoBrutalism));
        final response = await tester.request('/');
        expect(response.statusCode, HttpStatus.ok);
        expect(response.body, contains('id="probe"'));
        expect(response.body, contains(kWebSurfaceMarker));
        // `coui-theme-anim` on an ancestor is the crossfade rule's own
        // scope selector (`coui_web.dart`) — confirms `enableThemeAnimation`
        // actually reaches SSR output, not just a config flag nobody reads.
        expect(response.body, contains('coui-theme-anim'));
        expect(response.body, contains('data-coui-style="neoBrutalism"'));
      },
    );
  });

  group('WebTransitionContractProbe (오프라인 렌더, Chrome 필요, #3612)', () {
    /// Writes [bodyHtml] to a temp file, loads it offline in headless
    /// Chrome, and returns the computed transition contract for `#probe`.
    Future<ComputedTransitionContract> readContractFrom(
      String bodyHtml,
      String tempFileSuffix,
    ) async {
      // Unique per call — see the reduced-motion probe for why a fixed name
      // under the shared temp dir breaks under concurrent jobs.
      final tempDir = Directory.systemTemp.createTempSync(
        'coui-parity-transition-contract-probe-',
      );
      final tempFile = File(p.join(tempDir.path, '$tempFileSuffix.html'))
        ..writeAsStringSync(bodyHtml);

      try {
        final browser = await pptr.puppeteer.launch(
          executablePath: chromePath,
        );
        try {
          final page = await browser.newPage();
          await page.setOfflineMode(true);
          final _ = await page.goto(
            Uri.file(tempFile.path).toString(),
            wait: pptr.Until.load,
          );

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
      '양성 대조군 — 서페이스 마커의 background-color 전환은 이미 선언돼 있고 '
      '(#3468) duration 이 CoreDuration.fast 토큰과 일치한다',
      (tester) async {
        tester.pumpComponent(harness(.neoBrutalism));
        final response = await tester.request('/');
        final contract = await readContractFrom(response.body, 'positive');

        expectTransitionDeclaredForProperty(
          contract,
          'background-color',
          reason: 'OutlinedContainer background-color (.coui-theme-anim)',
        );
        expectTransitionDurationMatchesToken(
          contract,
          'background-color',
          expectedMs: CoreDuration.fast,
          reason: 'OutlinedContainer background-color (.coui-theme-anim)',
        );
      },
      skip: chromePath == null,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    // FR-024 — the geometry half of the surface-preset cross-fade, now a
    // regression lock rather than a defect lock.
    //
    // This assertion was authored inverted (`isFalse`, "no transition
    // declared") because #3622's fix lived on a sibling epic branch at the
    // time and the alternative was a permanently-red test in the merged
    // suite. Its own failure `reason` prescribed the flip for the moment
    // the fix reached this lineage. That moment came: #3622 (PR #3635)
    // merged at `4a55d47fa`, this probe went red, and this is that flip.
    //
    // Worth recording *why the red was correct*: the sibling probe for the
    // same epic (#3613's `WebLifecycleProbe`) locked down its own defect
    // the same way but could not detect its fix landing at all — it passes
    // identically before and after #3621, which is why it is now filed as
    // tautological (#3644). This one turned red on contact with reality.
    // The difference is the mechanism: reading a computed value from a
    // live browser can disagree with you; asserting tree-presence in a
    // harness with no simulated clock cannot.
    //
    // Duration is asserted against the token, not merely "nonzero" —
    // `coui_web.dart`'s `_kSurfaceGeometryTransitionCss` emits
    // `CoreDuration.fast`, the same token the colour half uses, so a
    // geometry cross-fade that drifts off the token fails here.
    testServer(
      '회귀 고정 — 서페이스 프리셋 전환 시 geometry(border-width)에도 '
      '전환이 선언돼 있고 duration 이 CoreDuration.fast 토큰과 일치한다 (#3622)',
      (tester) async {
        tester.pumpComponent(harness(.neoBrutalism));
        final response = await tester.request('/');
        final contract = await readContractFrom(response.body, 'geometry');

        expectTransitionDeclaredForProperty(
          contract,
          'border-width',
          reason: 'surface marker border-width (.coui-theme-anim)',
        );
        expectTransitionDurationMatchesToken(
          contract,
          'border-width',
          expectedMs: CoreDuration.fast,
          reason: 'surface marker border-width (.coui-theme-anim)',
        );
      },
      skip: chromePath == null,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
