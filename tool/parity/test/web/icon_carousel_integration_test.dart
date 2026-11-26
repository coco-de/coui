/// A glyph the bundle does not carry, through the merged CarouselBanner slot.
///
/// The docs preview draws `lucide:image`, which the bundle now holds — the
/// bundled path is inline SVG, and this test measures the Iconify adapter. So
/// it renders its own banner around an icon that stays outside the bundle.
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/model/capture_surface.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../../src/web/web_capture_backend.dart';

const _unbundled = IconName('lucide', 'a-arrow-down');

/// The banner the way the docs preview states it, with [_unbundled] as the
/// thumbnail. Wrapped like `renderCaptureBodyHtml` wraps a preview so the
/// harness measures the same box.
class _UnbundledBanner extends StatelessComponent {
  const _UnbundledBanner({required this.key_, required this.variant});

  final String key_;
  final String variant;

  @override
  Component build(BuildContext context) => .fragment([
    Style(styles: docsContentTheme().styles),
    CoUIWeb(
      theme: .coui,
      child: div(
        [
          if (variant == 'md')
            const CarouselBanner(
              size: CoreCarouselBannerSize.md,
              thumbnail: Icon(_unbundled),
              title: Text('회원 할인'),
              description: Text('4월 말까지 묶음 상품 20% 할인'),
            )
          else
            const CarouselBanner(
              thumbnail: Icon(_unbundled),
              title: Text('겨울 시즌 할인'),
              description: Text('12월 31일까지 전 상품 20% 할인'),
            ),
        ],
        styles: const Styles(
          raw: {
            'display': 'inline-block',
            'width': kCaptureAvailableWidthCss,
          },
        ),
        attributes: {'data-parity-key': key_},
      ),
    ),
  ]);
}

String? _chromePath() {
  for (final path in const [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
  ]) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

void main() {
  final chrome = _chromePath();
  late Browser browser;
  late Directory folder;
  setUpAll(() async {
    browser = await launchCaptureBrowser(
      width: 1000,
      height: 400,
      executablePath: chrome,
    );
    folder = Directory.systemTemp.createTempSync('coui-icon-carousel-');
  });
  tearDownAll(() async {
    await browser.close();
    folder.deleteSync(recursive: true);
  });

  for (final variant in ['default', 'md']) {
    for (final theme in ParityTheme.values) {
      test(
        '$variant/${theme.name}: unbundled glyph is centred at24 with stroke1.5',
        () async {
          expect(CoreBundledIcons.icons, isNot(contains(_unbundled.id)));
          final key = 'carousel-banner-$variant-${theme.name}-defaultStyle';
          final entry = MatrixEntry(
            component: 'carousel-banner',
            variant: variant,
            theme: theme,
            surfaceStyle: CoreSurfaceStyleId.defaultStyle,
            tier: ParityTier.t1,
            probes: [
              rootProbeSpec(key: key, flutterClassName: 'CarouselBanner'),
            ],
          );
          final body = await renderComponentBodyHtml(
            _UnbundledBanner(key_: key, variant: variant),
          );
          expect(body, contains('icon="lucide:a-arrow-down"'));
          final file = writeHarnessFile(
            entry: entry,
            bodyHtml: body,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            fontFaceCss: buildLocalFontFaceCss(),
            iconifyHeadHtml: buildLocalIconifyHeadHtml(),
            harnessDir: folder,
          );
          final page = await browser.newPage();
          try {
            await page.setOfflineMode(true);
            await page.goto(Uri.file(file.path).toString(), wait: Until.load);
            await page.waitForFunction('''
() => {
  const host = document.querySelector('iconify-icon');
  const path = host?.shadowRoot?.querySelector('path');
  return path && getComputedStyle(path).strokeWidth === '1.5px';
}
''');
            final row =
                jsonDecode(
                      await page.evaluate<String>('''
() => {
  const host = document.querySelector('iconify-icon');
  const box = host.closest('.co-carousel-banner-thumbnail');
  const path = host.shadowRoot.querySelector('path');
  const h = host.getBoundingClientRect(), b = box.getBoundingClientRect();
  const cs = getComputedStyle(path), m = path.getScreenCTM();
  const probe = document.createElement('span');
  probe.style.cssText = 'position:absolute;color:rgb(var(--coui-on-surface-variant))';
  box.append(probe);
  const expectedColor = getComputedStyle(probe).color;
  probe.remove();
  return JSON.stringify({
    width:h.width,height:h.height,cell:b.width,
    centreX:h.x+h.width/2-(b.x+b.width/2),
    centreY:h.y+h.height/2-(b.y+b.height/2),
    stroke:parseFloat(cs.strokeWidth)*Math.hypot(m.a,m.b),
    color:cs.color,expectedColor,path:path.outerHTML,
    svg:host.shadowRoot.querySelector('svg').outerHTML,
    canonical:customElements.get('iconify-icon').getIcon('lucide:a-arrow-down').body
  });
}
'''),
                    )
                    as Map<String, dynamic>;
            expect(row['width'], 24);
            expect(row['height'], 24);
            expect(row['cell'], variant == 'md' ? 72 : 56);
            expect(row['centreX'], closeTo(0, 0.01));
            expect(row['centreY'], closeTo(0, 0.01));
            expect(row['stroke'], closeTo(1.5, 0.0001));
            expect(row['color'], row['expectedColor']);
            expect(row['canonical'], contains('stroke-width="2"'));
            if (Platform.environment['COUI_ICON_CAROUSEL_EVIDENCE']
                case final String out) {
              Directory(out).createSync(recursive: true);
              File('$out/$key.json').writeAsStringSync(
                const JsonEncoder.withIndent('  ').convert(row),
              );
              File('$out/$key.png').writeAsBytesSync(await page.screenshot());
            }
          } finally {
            await page.close();
          }
        },
        skip: chrome == null,
      );
    }
  }
}
