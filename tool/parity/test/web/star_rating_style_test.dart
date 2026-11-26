import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  test(
    'StarRating value and count preserve role, overlays and disabled ink',
    () async {
      final cases = <String, (CoreComponentSize, CoreTextStyle?, bool)>{
        for (final size in [
          CoreComponentSize.sm,
          CoreComponentSize.md,
          CoreComponentSize.lg,
          CoreComponentSize.xl,
        ])
          'size-${size.name}': (size, null, true),
        'code': (.lg, const CoreTextStyle.token(CoreTextStyles.codeMd), true),
        'overlay': (
          .lg,
          const CoreTextStyle.token(
            CoreTextStyles.codeMd,
          ).copyWith(fontSize: 17, lineHeight: 1.3),
          true,
        ),
        'raw': (
          .lg,
          const CoreTextStyle(
            fontSize: 17,
            fontWeight: 700,
            lineHeightPx: 20.3,
            fontFamily: CoreFontFamily.mono,
            letterSpacing: 0.03,
            color: CoreColor(0xFF123456),
          ),
          true,
        ),
        'token-color': (
          .lg,
          const CoreTextStyle(color: CoreColor.token(CoreColors.primary)),
          true,
        ),
        'disabled-token': (
          .lg,
          const CoreTextStyle(color: CoreColor.token(CoreColors.primary)),
          false,
        ),
        'disabled-raw': (
          .lg,
          const CoreTextStyle(
            fontSize: 17,
            fontWeight: 700,
            lineHeightPx: 20.3,
            fontFamily: CoreFontFamily.mono,
            color: CoreColor(0xFF123456),
          ),
          false,
        ),
      };
      final body = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          CoUIWeb(
            theme: .coui,
            child: div([
              for (final entry in cases.entries)
                div([
                  StarRating(
                    value: 3.5,
                    count: 27,
                    showValue: true,
                    showCount: true,
                    size: entry.value.$1,
                    enabled: entry.value.$3,
                    starRatingStyle: CoreStarRatingStyle(
                      valueStyle: entry.value.$2,
                      countStyle: entry.value.$2,
                    ),
                  ),
                ], id: entry.key),
              div([
                Theme(
                  data: ThemeData.coui.copyWith(
                    coreComponentTheme: CoreComponentTheme(
                      starRating: CoreStarRatingTheme(
                        style: CoreStarRatingStyle(
                          valueStyle: const CoreTextStyle.token(
                            CoreTextStyles.codeMd,
                          ).copyWith(fontSize: 17, fontWeight: 600),
                          countStyle: const CoreTextStyle.token(
                            CoreTextStyles.codeMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const StarRating(
                    value: 3.5,
                    count: 27,
                    showValue: true,
                    showCount: true,
                    starRatingStyle: CoreStarRatingStyle(
                      valueStyle: CoreTextStyle(
                        color: CoreColor.token(CoreColors.primary),
                      ),
                      countStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
                    ),
                  ),
                ),
              ], id: 'theme-priority'),
              for (final color in [
                CoreColors.primary,
                CoreColors.onSurface,
                CoreColors.onSurfaceSubtle,
                CoreColors.disabledContent,
              ])
                span(
                  const [Text('Reference')],
                  id: 'ref-${color.name}',
                  styles: Styles(
                    raw: {'color': CoreColor.token(color).toValue()},
                  ),
                ),
            ]),
          ),
        ]),
      );
      final dir = Directory.systemTemp.createTempSync('coui-star-typography-');
      final browser = await launchCaptureBrowser(width: 900, height: 1600);
      try {
        final page = await browser.newPage();
        await page.setOfflineMode(true);
        for (final custom in [false, true]) {
          final typography = custom
              ? CoreTypography.coui.copyWith(
                  codeMd: CoreTypography.coui.codeMd.copyWith(
                    fontSize: 19,
                    fontWeight: 600,
                    lineHeightPx: 23.5,
                    letterSpacing: 0.02,
                  ),
                )
              : CoreTypography.coui;
          for (final theme in ['light', 'dark']) {
            final file = File('${dir.path}/$custom-$theme.html')
              ..writeAsStringSync(
                buildOfflineTailwindHarnessHtml(
                  bodyHtml: body,
                  themeConfig: ThemeConfig.from(
                    CouiColorPresets.source,
                    typography: typography,
                  ),
                  theme: theme,
                  vendoredTailwindScript: loadVendoredTailwindScript(),
                  additionalHeadHtml:
                      '<style>${buildLocalFontFaceCss()}</style>',
                ),
              );
            await page.goto(file.uri.toString(), wait: .load);
            await page.evaluate<void>(
              '() => document.fonts.ready.then(() => {})',
            );
            final rows =
                jsonDecode(
                      await page.evaluate<String>('''
() => JSON.stringify([...document.querySelectorAll('div[id]:not([id^="co-"])')].map(root=>{
  const read=text=>{const e=[...root.querySelectorAll('*')].find(e=>
    !e.children.length&&e.textContent===text); if(!e)return null;
    const s=getComputedStyle(e),owner=e.parentElement;
    return {size:s.fontSize,weight:s.fontWeight,line:s.lineHeight,
      family:s.fontFamily,tracking:s.letterSpacing,color:s.color,
      classes:owner.className,inlineColor:owner.style.color};};
  return {name:root.id,value:read('3.5'),count:read('(27)'),
    refs:Object.fromEntries([...document.querySelectorAll('[id^="ref-"]')]
      .map(e=>[e.id.slice(4),getComputedStyle(e).color]))};
}).filter(e=>e.value))
'''),
                    )
                    as List;
            expect(rows, hasLength(cases.length + 1));
            for (final row in rows.cast<Map<String, dynamic>>()) {
              final name = row['name'] as String;
              final refs = row['refs'] as Map<String, dynamic>;
              for (final slot in ['value', 'count']) {
                final text = row[slot] as Map<String, dynamic>;
                final reason = '$custom $theme $name $slot $text';
                final raw = name == 'raw' || name == 'disabled-raw';
                final code =
                    name == 'code' ||
                    name == 'overlay' ||
                    (name == 'theme-priority' && slot == 'value');
                final size = switch (name) {
                  'size-sm' => 12,
                  'size-md' => 14,
                  'size-xl' => 16,
                  'overlay' || 'raw' || 'disabled-raw' => 17,
                  'code' => custom ? 19 : 13,
                  'theme-priority' => slot == 'value' ? 17 : 13,
                  _ => 15,
                };
                expect(text['size'], '${size}px', reason: reason);
                expect(
                  text['weight'],
                  raw
                      ? '700'
                      : code
                      ? (custom || name == 'theme-priority' ? '600' : '400')
                      : name == 'theme-priority'
                      ? '400'
                      : '500',
                  reason: reason,
                );
                expect(
                  text['line'],
                  raw
                      ? '20px'
                      : name == 'overlay'
                      ? '22px'
                      : code
                      ? (custom ? '24px' : '21px')
                      : name == 'theme-priority'
                      ? '20px'
                      : switch (name) {
                          'size-sm' => '17px',
                          'size-md' => '20px',
                          'size-xl' => '22px',
                          _ => '21px',
                        },
                  reason: reason,
                );
                expect(
                  text['family'],
                  startsWith(raw || code ? '"Geist Mono"' : 'Pretendard'),
                  reason: reason,
                );
                expect(
                  text['color'],
                  name.startsWith('disabled-')
                      ? refs['disabled-content']
                      : name == 'raw'
                      ? 'rgb(18, 52, 86)'
                      : name == 'token-color' ||
                            (name == 'theme-priority' && slot == 'value')
                      ? refs['primary']
                      : refs[slot == 'value'
                            ? 'on-surface'
                            : 'on-surface-subtle'],
                  reason: reason,
                );
                if (name == 'raw') {
                  expect(text['tracking'], '0.51px', reason: reason);
                }
                if (name != 'raw') {
                  expect(text['inlineColor'], isEmpty, reason: reason);
                }
              }
            }
          }
        }
      } finally {
        await browser.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}
