@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:image/image.dart' as img;
import 'package:puppeteer/puppeteer.dart' show Browser, DeviceViewport;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/model/probe_spec.dart';
import '../../src/report/entry_loader.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/runtime_capture.dart';
import '../../src/web/web_capture_backend.dart';

void main() {
  late Browser browser;
  late Directory directory;

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('capture-state-');
    browser = await launchCaptureBrowser(width: 1600, height: 1200);
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });

  Future<WebCaptureResult> capture(
    String component, {
    String variant = 'default',
    int width = 800,
    bool includeStage = true,
  }) {
    final key = '$component-$variant-light-defaultStyle';
    return captureWebEntry(
      browser: browser,
      entry: MatrixEntry(
        component: component,
        variant: variant,
        theme: ParityTheme.light,
        surfaceStyle: CoreSurfaceStyleId.defaultStyle,
        tier: ParityTier.t1,
        probes: captureProbes(
          key: key,
          component: component,
          variant: variant,
          flutterClassName: 'Widget',
        ).where((probe) => includeStage || probe.role != 'stage').toList(),
      ),
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      fontFaceCss: buildLocalFontFaceCss(),
      iconifyHeadHtml: buildLocalIconifyHeadHtml(),
      harnessDir: directory,
      availableWidthPx: width,
    );
  }

  test('a framed capture rejects a stale root-only manifest', () async {
    await expectLater(
      capture('mockup-device', includeStage: false),
      throwsFormatException,
    );
  });

  test('a counter captures its destination instead of its SSR zero', () async {
    final result = await capture('number-ticker');
    expect(result.renderPhase, 'client-settled');
    expect(result.captureContext['text'], '1234');
    expect(result.captureContext['viewportWidth'], 800);
  });

  test(
    'SSR captures use the requested viewport as well as host width',
    () async {
      final wide = await capture('button');
      final narrow = await capture('button', width: 400);
      expect(wide.renderPhase, 'ssr');
      expect(narrow.renderPhase, 'ssr');
      expect(wide.captureContext['viewportWidth'], 800);
      expect(narrow.captureContext['viewportWidth'], 400);
      expect(wide.captureContext['viewportHeight'], 1200);
      expect(narrow.captureContext['viewportHeight'], 1200);
      expect(
        narrow.rawPropertyByRole['root']!['widthPx'],
        wide.rawPropertyByRole['root']!['widthPx'],
      );
    },
  );

  test('stage measurement reaches the builder and painted padding', () async {
    final result = await capture('stage-container');
    expect(result.captureContext['text'], '왼쪽: 88, 오른쪽: 88');
    expect(result.rawPropertyByRole['root']!['widthPx'], 800);
    final narrow = await capture('stage-container', width: 400);
    expect(narrow.captureContext['text'], '왼쪽: 0, 오른쪽: 0');
    expect(narrow.captureContext['viewportWidth'], 400);
  });

  for (final (width, height, query) in [
    (1000, 40, '(min-width: 900px)'),
    (80, 1400, '(min-height: 1300px)'),
  ]) {
    test(
      'backend $width by $height pixels retain the declared viewport',
      () async {
        final original = kWebPreviewRegistry['button']!;
        addTearDown(() => kWebPreviewRegistry['button'] = original);
        kWebPreviewRegistry['button'] = (context, variant) => Component.element(
          tag: 'div',
          id: 'viewport-capture',
          children: [
            Component.element(
              tag: 'style',
              children: [
                RawText(
                  '''
              #viewport-capture { flex:none; width:${width}px;
              min-width:${width}px; height:${height}px; background:rgb(0,128,0); }
              @media $query { #viewport-capture { background:rgb(255,0,0); } }''',
                ),
              ],
            ),
          ],
        );
        final result = await capture('button');
        expect(result.captureContext['viewportWidth'], 800);
        expect(result.captureContext['viewportHeight'], 1200);
        final image = img.decodePng(result.pngBytes)!;
        expect((image.width, image.height), (width, height));
        for (final pixel in [
          image.getPixel(0, 0),
          image.getPixel(width - 1, height - 1),
        ]) {
          expect(
            [pixel.r, pixel.g, pixel.b],
            [0, 128, 0],
            reason:
                'The actual PNG must agree with the recorded '
                '800x1200 viewport.',
          );
        }
      },
    );
  }

  for (final (component, variant, expectedWidth) in [
    ('mockup', 'phone', 320),
    ('mockup', 'tablet', 320),
    ('mockup', 'landscape', 320),
    ('mockup-device', 'default', 320),
    ('mockup-device', 'flat', 256),
    ('responsive-container', 'default', 640),
  ]) {
    test(
      '$component/$variant retains loadable stage properties and both images at two host widths',
      () async {
        for (final width in [400, 800]) {
          final result = await capture(
            component,
            variant: variant,
            width: width,
          );
          final expected = expectedWidth.clamp(0, width);
          final bounds = result.captureContext['bodyBounds']! as Map;
          expect(result.rawPropertyByRole['stage']!['widthPx'], width);
          final key = '$component-$variant-light-defaultStyle';
          File('${directory.path}/$key.web.json').writeAsStringSync(
            jsonEncode({'byRole': result.rawPropertyByRole}),
          );
          final stageProperties = loadWebPropertySnapshot(
            key: key,
            capturedDir: directory,
            probeRole: 'stage',
          );
          expect(stageProperties.widthPx, width);
          expect(
            stageProperties.heightPx,
            closeTo(bounds['height']! as num, 0.01),
          );
          expect(result.rawPropertyByRole['root']!['widthPx'], expected);
          expect(bounds['left'], (width - expected) / 2);
          final stage = img.decodePng(result.pngByRole['stage']!)!;
          final body = img.decodePng(result.pngBytes)!;
          expect((body.width, body.height), (expected, stage.height));
          for (final pixel in body) {
            expect(
              pixel.toList(),
              stage
                  .getPixel(pixel.x + ((width - expected) ~/ 2), pixel.y)
                  .toList(),
            );
          }
          if (component == 'mockup-device' && variant == 'default') {
            final background = stage.getPixel(0, 0).toList();
            final left = (width - expected) ~/ 2;
            expect(
              stage.any(
                (pixel) =>
                    (pixel.x < left || pixel.x >= left + expected) &&
                    pixel.toList().toString() != background.toString(),
              ),
              isTrue,
              reason:
                  'The stage must retain real hardware/shadow pixels outside the body.',
            );
          }
        }
      },
    );
  }

  test('the viewport is800 and a column keeps its natural width', () async {
    final row = await capture('responsive-row-column');
    final column = await capture('responsive-row-column', variant: 'desktop');
    expect(row.captureContext['viewportWidth'], 800);
    expect(row.rawPropertyByRole['root']!['widthPx'], 800);
    expect(column.rawPropertyByRole['root']!['widthPx'], lessThan(200));
    final phone = await capture('responsive-row-column', width: 400);
    expect(phone.rawPropertyByRole['root']!['widthPx'], lessThan(200));
  });

  test('chain variants settle their own padding and alignment', () async {
    final stage = await capture('stage-container', variant: 'chain');
    expect(stage.captureContext['text'], '왼쪽: 48, 오른쪽: 48');
    final narrowStage = await capture(
      'stage-container',
      variant: 'chain',
      width: 400,
    );
    expect(narrowStage.captureContext['text'], '왼쪽: 104, 오른쪽: 104');
    final column = await capture(
      'responsive-row-column',
      variant: 'chain',
      width: 400,
    );
    expect(column.rawPropertyByRole['root']!['widthPx'], lessThan(200));
  });

  for (final (component, variant) in [
    ('loading', 'default'),
    ('skeleton', 'default'),
    ('skeleton', 'circle'),
    ('skeleton', 'text'),
    ('loading-region', 'default'),
  ]) {
    test(
      '$component/$variant CSS starts at zero on independent pages',
      () async {
        final first = await capture(component, variant: variant);
        final second = await capture(component, variant: variant);
        expect(first.renderPhase, 'initial-frame');
        final times = first.captureContext['animationTimes']! as List;
        expect(times, isNotEmpty);
        expect(times, everyElement(0));
        expect(first.captureContext['animationStates'], everyElement('paused'));
        expect(second.pngBytes, first.pngBytes);
      },
    );
  }
  test(
    'ordinary skeleton CSS still pulses without the capture policy',
    () async {
      const key = 'skeleton-default-light-defaultStyle';
      final entry = MatrixEntry(
        component: 'skeleton',
        variant: 'default',
        theme: ParityTheme.light,
        surfaceStyle: CoreSurfaceStyleId.defaultStyle,
        tier: ParityTier.t1,
        probes: [rootProbeSpec(key: key, flutterClassName: 'Skeleton')],
      );
      final body = await renderCaptureBodyHtml(entry);
      final file = File('${directory.path}/skeleton-live.html')
        ..writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml: body,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
            animationFreezeCss: '',
          ),
        );
      final page = await browser.newPage();
      try {
        await page.goto(file.uri.toString());
        await page.evaluate<void>('() => document.fonts.ready');
        expect(
          await page.evaluate<bool>('''
() => {
  window.skeletonInitialColor = getComputedStyle(
    document.querySelector('[role="status"]')).backgroundColor;
  return document.getAnimations().some(a => a.playState === 'running');
}
'''),
          isTrue,
        );
        await page.waitForFunction('''
() => getComputedStyle(document.querySelector('[role="status"]')).backgroundColor
  !== window.skeletonInitialColor
''');
      } finally {
        await page.close();
      }
    },
  );
  test(
    'the documented swipe surface opens from outside the old content box',
    () async {
      final html = File('${directory.path}/swiper.html')
        ..writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml: '<script>${await loadRuntimeCaptureScript()}</script>',
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            additionalHeadHtml:
                '<style>${buildLocalFontFaceCss()}</style>${buildLocalIconifyHeadHtml()}',
          ),
        );
      final page = await browser.newPage();
      try {
        await page.setViewport(const DeviceViewport(width: 800, height: 1200));
        await page.goto(
          html.uri
              .replace(
                fragment: jsonEncode({
                  'key': 'swiper-live',
                  'component': 'swiper',
                  'variant': 'default',
                  'width': 800,
                }),
              )
              .toString(),
        );
        await page.waitForSelector('[data-swiper-enabled="true"]');
        await page.evaluate<void>('() => document.fonts.ready');
        final info =
            jsonDecode(
                  await page.evaluate<String>('''
() => {
 const surface=document.querySelector('[data-swiper-enabled="true"]');
 const r=surface.getBoundingClientRect(), card=surface.querySelector('.coui-surface');
 const x=r.left+r.width*0.7, y=r.top+r.height/2;
 const hit=document.elementFromPoint(x,y);
 return JSON.stringify({width:r.width,x,y,right:r.right,
   onSurface:surface.contains(hit),onCard:card?.contains(hit)});
}
'''),
                )
                as Map;
        expect(info['width'], 800);
        expect(info['onSurface'], isTrue);
        expect(info['onCard'], isFalse);
        final x = (info['x'] as num).toDouble();
        final y = (info['y'] as num).toDouble();
        await page.mouse.move(Point(x, y));
        await page.mouse.down();
        await page.mouse.move(Point(x + 24, y));
        await page.waitForSelector('[role="dialog"][aria-modal="true"]');
        expect(
          await page.evaluate<bool>('''
() => !!document.querySelector('[data-swiper-enabled="true"]').closest('[inert]')
'''),
          isTrue,
        );
        for (var i = 1; i <= 8; i++) {
          await page.evaluate<void>(
            '() => new Promise(r => requestAnimationFrame(r))',
          );
          await page.mouse.move(Point(x + 232 * i / 8, y));
        }
        await page.mouse.up();
        await page.waitForFunction('''
() => document.querySelector('[data-swiper-enabled="true"]')?.getAttribute('aria-expanded') === 'true'
''');
        await page.waitForFunction('''
() => Math.abs(document.querySelector('[role="dialog"]').getBoundingClientRect().left) < 1
''');
      } finally {
        await page.close();
      }
    },
  );
}
