// The Web half of "a glass surface draws no second boundary", measured in
// a browser rather than read off a class string.
//
// This axis had no browser coverage at all. The only Web test that resolved
// a surface under the glass preset read `resolved.root.className` and
// stopped there, which means a Web-only regression in the suppression —
// wrong specificity, a rule that stopped being emitted, an inline
// declaration outranking it — landed entirely green. Class strings say what
// was asked for; only a browser says what won.
//
// ## What is actually asserted, and why each half matters
//
// The colour goes and **the box stays**. Both are load-bearing and they
// fail in opposite directions:
//
//   colour  — a surviving stroke is the defect this whole unit removes:
//             the same `outline` token painted twice on one edge, once at
//             25% by the material's band and once at 100% by the component.
//   width   — a zeroed one would be a different bug wearing the same look.
//             The border box is what the forced-colours rule recolours, so
//             losing it loses the boundary in the mode a user turned on to
//             see boundaries. And because the style swap writes a document
//             attribute without rebuilding, a width change moves layout at
//             the moment the swap is supposed to change paint alone.
//
// The width half is also the cross-platform tripwire. Flutter collapses a
// transparent border's width, so the obvious implementation there produces
// 1px per side less than here — a 2px divergence with no other witness.
//
// ## The settle is not politeness
//
// The card's own `transition` list includes `border-color`, so a computed
// read taken in the same frame as the attribute write returns the
// pre-transition value and this test would pass while measuring the state
// it was supposed to leave behind.
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// Mirrors `computed_style_probe_test.dart`'s system-Chrome lookup.
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

/// Long enough to outlast the chrome transition the card declares.
const _kSettleMs = 700;

/// A surface carrying the marker and a resting stroke, exactly as the
/// component resolvers emit them: the marker class first, the border as
/// Tailwind classes, and the fill variable published inline.
///
/// Hand-written rather than rendered through the component, because what is
/// under test is whether the preset's rule beats an ordinary border — and
/// the ordinary border is the thing that has to be present for that to mean
/// anything. Rendering the component would couple this to whichever variant
/// happened to be default.
///
/// `coui-surface-functional`, not `-content` — that is the role
/// liquidGlass actually suppresses a stroke for (#4424); its content role
/// draws flat and states no edge of its own, so it emits no suppression
/// rule to be beaten by anything.
String _bodyHtml() => '''
<style>
  body { margin: 0; }
  .surface { width: 240px; height: 120px; margin: 40px;
             border-radius: 16px; border-style: solid; border-width: 1px; }
</style>
<div id="s" class="surface coui-surface coui-surface-functional border-outline"
     style="--coui-surface-rgb: var(--coui-surface);"></div>
<!-- The path `!important` exists for. `emitColor` writes `border-color`
     inline whenever the resolved colour is token-less — i.e. on any raw
     caller override — and an inline declaration outranks every selector
     no matter how specific. Without this element the flag is untested:
     removing it leaves the class-based case above passing, because
     (0,2,0) already beats (0,1,0) on its own. -->
<div id="inline" class="surface coui-surface coui-surface-functional"
     style="--coui-surface-rgb: var(--coui-surface);
            border-color: rgb(200 30 30);"></div>
''';

void main() {
  final chromePath = _systemChromePath();
  final skipReason = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

  group('a glass surface draws no second boundary, in a browser', () {
    late Browser browser;

    setUpAll(() async {
      if (chromePath == null) return;
      browser = await launchCaptureBrowser(
        width: 420,
        height: 260,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      if (chromePath == null) return;
      await browser.close();
    });

    Future<Map<String, dynamic>> measure(String? styleId) async {
      final page = await browser.newPage();
      final dir = Directory.systemTemp.createTempSync('stroke-probe-');
      try {
        final html = buildOfflineTailwindHarnessHtml(
          bodyHtml: _bodyHtml(),
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          surfaceStyleId: styleId,
        );
        final file = File(p.join(dir.path, 'stroke.html'))
          ..writeAsStringSync(html);
        await page.goto(Uri.file(file.path).toString(), wait: Until.load);
        await page.evaluate<void>(
          '() => new Promise(function (d) { setTimeout(d, $_kSettleMs); })',
        );

        return (await page.evaluate<Map<dynamic, dynamic>>('''
() => {
  const cs = getComputedStyle(document.getElementById('s'));
  const inline = getComputedStyle(document.getElementById('inline'));
  return {
    color: cs.borderTopColor,
    width: cs.borderTopWidth,
    backdrop: cs.backdropFilter,
    inlineColor: inline.borderTopColor,
    inlineWidth: inline.borderTopWidth,
  };
}
''')).cast<String, dynamic>();
      } finally {
        await page.close();
        dir.deleteSync(recursive: true);
      }
    }

    test(
      'control — without the preset the surface keeps an ordinary stroke',
      () async {
        // The floor. If this surface had no visible border to begin with,
        // the assertion below would report a suppression that never
        // happened, and the whole file would be measuring an empty box.
        final plain = await measure(null);

        expect(plain['width'], '1px');
        expect(plain['color'], isNot('rgba(0, 0, 0, 0)'));
      },
      skip: skipReason,
    );

    test(
      'the preset takes the colour and leaves the box',
      () async {
        final glass = await measure(CoreSurfaceStyleId.liquidGlass.name);
        stdout.writeln('W-stroke  $glass');

        expect(
          glass['color'],
          'rgba(0, 0, 0, 0)',
          reason: 'the component stroke is a second boundary here',
        );
        expect(
          glass['width'],
          '1px',
          reason:
              'the box is what the forced-colours rule recolours, and '
              'zeroing it would move layout on a style swap',
        );
        // Not a restatement: it pins that the rule under test rode in on the
        // material, so a preset that lost its material would not quietly
        // keep suppressing strokes.
        expect(glass['backdrop'], contains('blur('));

        // The `!important` half. A caller that overrode the colour with a
        // raw value gets it inline, which outranks any selector — so
        // without the flag this surface keeps a red border while its
        // token-coloured sibling loses one, and glass would look different
        // depending on whether the app happened to use a token.
        expect(
          glass['inlineColor'],
          'rgba(0, 0, 0, 0)',
          reason:
              'an inline override outranks the preset rule without '
              '!important',
        );
        expect(glass['inlineWidth'], '1px');
      },
      skip: skipReason,
    );

    test(
      'and a preset with no material leaves the stroke alone',
      () async {
        // The other side of the pairing. Without this, a rule that
        // suppressed every surface under every preset would pass the test
        // above and be wrong everywhere else.
        final other = await measure(CoreSurfaceStyleId.neoBrutalism.name);

        expect(other['color'], isNot('rgba(0, 0, 0, 0)'));
      },
      skip: skipReason,
    );
  });
}
