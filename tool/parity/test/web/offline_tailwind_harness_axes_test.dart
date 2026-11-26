// #3605 — surfaceStyleId / additionalHeadHtml extension to the SPIKE-3
// (#3602) harness. Kept as a separate file from
// `offline_tailwind_harness_test.dart` (SPIKE-3's own file) so the spike's
// original test intent is not diluted by a different issue's coverage.
import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:test/test.dart';

import '../../src/web/offline_tailwind_harness.dart';

/// The typography tier the harness pins every page to — written out rather
/// than built from `kTypographyTierAttribute`, so the test is a second
/// source for the attribute's spelling.
const _kDesktopPin = 'data-coui-typography-tier="desktop"';

void main() {
  final themeConfig = ThemeConfig.defaults();
  const vendored = '/* vendor script stub */';

  group('buildOfflineTailwindHarnessHtml — surfaceStyleId', () {
    test('omitting surfaceStyleId leaves the html tag exactly as before', () {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '<div></div>',
        themeConfig: themeConfig,
        vendoredTailwindScript: vendored,
      );
      expect(html, contains('<html data-theme="light" $_kDesktopPin>'));
      // The JS-injected surface-style CSS block (always present — see the
      // "dark/surface injection" group below) legitimately mentions
      // `data-coui-style` as a CSS attribute-selector fragment; what must
      // stay absent is the *HTML attribute* on the root tag itself.
      expect(
        html,
        isNot(contains('<html data-theme="light" data-coui-style')),
      );
    });

    test('a non-null surfaceStyleId is stamped on the html tag', () {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '<div></div>',
        themeConfig: themeConfig,
        vendoredTailwindScript: vendored,
        surfaceStyleId: 'neoBrutalism',
      );
      expect(
        html,
        contains(
          '<html data-theme="light" data-coui-style="neoBrutalism" '
          '$_kDesktopPin>',
        ),
      );
    });

    test('dark theme and a surface style combine on the same tag', () {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '<div></div>',
        themeConfig: themeConfig,
        vendoredTailwindScript: vendored,
        theme: 'dark',
        surfaceStyleId: 'liquidGlass',
      );
      expect(
        html,
        contains(
          '<html data-theme="dark" data-coui-style="liquidGlass" '
          '$_kDesktopPin>',
        ),
      );
    });
  });

  group('buildOfflineTailwindHarnessHtml — typography tier', () {
    test('every page is pinned to the desktop tier, whatever its axes', () {
      // The capture viewport is in the desktop range, but a probe that opens
      // a narrow one must read the headings the baselines were taken with —
      // so the tier is stated, not left to the width.
      for (final (theme, style) in [
        ('light', null),
        ('dark', 'neoBrutalism'),
      ]) {
        final html = buildOfflineTailwindHarnessHtml(
          bodyHtml: '<div></div>',
          themeConfig: themeConfig,
          vendoredTailwindScript: vendored,
          theme: theme,
          surfaceStyleId: style,
        );
        final tag = RegExp('<html[^>]*>').firstMatch(html)![0]!;
        expect(tag, contains(_kDesktopPin), reason: '$theme / $style');
      }
    });
  });

  group(
    'buildOfflineTailwindHarnessHtml — dark/surface-style CSS injection',
    () {
      test(
        'the dark variable block rides a script, not a static style',
        () {
          final html = buildOfflineTailwindHarnessHtml(
            bodyHtml: '<div></div>',
            themeConfig: themeConfig,
            vendoredTailwindScript: vendored,
          );
          // A static <style> block would let the Tailwind CDN's JIT scanner
          // see the dark values at parse time and, per
          // `docs_core/lib/site_head.dart`'s own comment, break light mode —
          // so this must ride inside a <script>, appended after the CSS
          // variables <style> tag.
          final scriptIndex = html.indexOf('document.createElement("style")');
          expect(scriptIndex, isPositive);
          final scriptTagStart = html.lastIndexOf('<script>', scriptIndex);
          final styleTagEnd = html.indexOf('</style>');
          expect(scriptTagStart, greaterThan(styleTagEnd));
          expect(html, contains(themeConfig.darkVariableBlock));
        },
      );

      test(
        'the surface-style variable blocks are present for every preset',
        () {
          // Every preset's rule rides along unconditionally — the CSS
          // attribute selectors themselves gate which one applies, so a
          // single harness page loaded under any surfaceStyleId (or none)
          // still has every preset's rule available, matching the live
          // site's single shared injection.
          final html = buildOfflineTailwindHarnessHtml(
            bodyHtml: '<div></div>',
            themeConfig: themeConfig,
            vendoredTailwindScript: vendored,
          );
          expect(html, contains(themeConfig.surfaceStyleVariableBlocks));
        },
      );
    },
  );

  group('buildOfflineTailwindHarnessHtml — additionalHeadHtml', () {
    test('is appended after the CSS variable style block', () {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '<div></div>',
        themeConfig: themeConfig,
        vendoredTailwindScript: vendored,
        additionalHeadHtml: '<style>@font-face{font-family:Probe}</style>',
      );
      expect(html, contains('@font-face{font-family:Probe}'));
      expect(
        html.indexOf(themeConfig.cssVariables),
        lessThan(html.indexOf('@font-face')),
      );
    });

    test('defaults to empty — no stray markup when omitted', () {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: '<div></div>',
        themeConfig: themeConfig,
        vendoredTailwindScript: vendored,
      );
      expect(html, isNot(contains('@font-face')));
    });
  });
}
