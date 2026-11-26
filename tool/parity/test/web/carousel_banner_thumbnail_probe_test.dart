// Real browser layout and image pixels from the shipped CarouselBanner SSR.
@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:image/image.dart' as pixels;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../test/fixtures/carousel_banner_images.dart';
import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

class _CallerImage extends StatelessComponent {
  const _CallerImage(this.src, this.id);

  final String src;
  final String id;

  @override
  Component build(BuildContext context) => img(src: src, id: id, alt: 'Caller');
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
  late pptr.Browser browser;
  late Map<String, dynamic> measured;
  late pixels.Image screenshot;
  final folder = Directory.systemTemp.createTempSync(
    'coui-carousel-thumbnail-',
  );

  setUpAll(() async {
    final content = <Component>[];
    for (final size in CoreCarouselBannerSize.values) {
      void add(String name, Component? thumbnail, {bool interactive = false}) {
        content.add(
          div([
            CarouselBanner(
              id: '${size.name}-$name-banner',
              size: size,
              thumbnail: thumbnail,
              title: const Component.text('Title'),
              onTap: interactive ? () {} : null,
            ),
          ], styles: const Styles(raw: {'width': '360px'})),
        );
      }

      add('icon', Icon(LucideIcons.check, id: '${size.name}-icon'));
      add(
        'override-icon',
        Icon(
          LucideIcons.check,
          id: '${size.name}-override-icon',
          iconStyle: const CoreIconStyle(
            size: 20,
            color: CoreColor(0xFFFF0000),
          ),
        ),
      );
      for (final fixture in kCarouselBannerImages) {
        add(
          fixture.name,
          img(
            id: '${size.name}-${fixture.name}',
            src: 'data:image/png;base64,${fixture.png}',
            alt: fixture.name,
            width: fixture.width,
            height: fixture.height,
            attributes: const {'data-caller': 'preserved'},
          ),
          interactive: fixture.name == 'wide',
        );
      }
      final src = 'data:image/png;base64,${kCarouselBannerImages.first.png}';
      add('caller-root', _CallerImage(src, '${size.name}-caller-root'));
      add(
        'inline',
        img(
          id: '${size.name}-inline',
          src: src,
          styles: const Styles(
            raw: {'width': '14px', 'height': '12px', 'object-fit': 'contain'},
          ),
        ),
      );
      add(
        'class',
        img(id: '${size.name}-class', src: src, classes: 'caller-size'),
      );
      add(
        'nested',
        div([
          img(id: '${size.name}-nested', src: src),
        ], styles: const Styles(raw: {'width': '18px', 'height': '16px'})),
      );
      add('empty', null);
    }
    final html = buildOfflineTailwindHarnessHtml(
      bodyHtml: await renderComponentBodyHtml(
        Theme.defaults(child: div(content)),
      ),
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(
        repoRoot: Directory.current.path,
      ),
      additionalHeadHtml: '<style>.caller-size{width:18px;height:10px}</style>',
    );
    final file = File('${folder.path}/probe.html')..writeAsStringSync(html);
    browser = await launchCaptureBrowser(
      width: 800,
      height: 2400,
      executablePath: _chromePath(),
    );
    addTearDown(() async {
      await browser.close();
    });
    final page = await browser.newPage();
    await page.setOfflineMode(true);
    await page.goto(Uri.file(file.path).toString(), wait: pptr.Until.load);
    await page.evaluate<void>('''
async () => {
      await Promise.all([...document.images].map(i => i.decode()));
    }''');
    measured =
        jsonDecode(
              await page.evaluate<String>('''
() => {
      const out = {};
      for (const el of document.querySelectorAll('img[id],svg[id]')) {
        const r = el.getBoundingClientRect();
        const box = el.closest('.co-carousel-banner-thumbnail').getBoundingClientRect();
        const cs = getComputedStyle(el);
        out[el.id] = {width:r.width,height:r.height,x:r.x,y:r.y,
          cx:r.x+r.width/2,cy:r.y+r.height/2,
          boxWidth:box.width,boxHeight:box.height,
          boxCx:box.x+box.width/2,boxCy:box.y+box.height/2,
          naturalWidth:el.naturalWidth,naturalHeight:el.naturalHeight,
          alt:el.getAttribute('alt'),caller:el.getAttribute('data-caller'),
          colour:cs.color,objectFit:cs.objectFit};
      }
      out.emptyBoxes = ['sm','md'].map(s => document.getElementById(s+'-empty-banner')
        .querySelectorAll('.co-carousel-banner-thumbnail').length);
      out.interactive = ['sm','md'].map(s => document.getElementById(s+'-wide-banner').getAttribute('role'));
      return JSON.stringify(out);
    }'''),
            )
            as Map<String, dynamic>;
    final png = await page.screenshot(fullPage: true);
    screenshot = pixels.decodePng(png)!;
    if (Platform.environment['COUI_CAROUSEL_EVIDENCE'] case final String path) {
      final evidence = Directory(path)..createSync(recursive: true);
      File('${evidence.path}/browser.png').writeAsBytesSync(png);
      File(
        '${evidence.path}/browser.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(measured));
    }
  });
  tearDownAll(() => folder.deleteSync(recursive: true));

  for (final size in CoreCarouselBannerSize.values) {
    final side = size == CoreCarouselBannerSize.sm ? 56 : 72;
    test('${size.name}: icons are centred at 24, with caller overrides', () {
      for (final (name, expected) in [('icon', 24), ('override-icon', 20)]) {
        final row = measured['${size.name}-$name'] as Map;
        expect(row['width'], expected);
        expect(row['height'], expected);
        expect(row['boxWidth'], side);
        expect(row['boxHeight'], side);
        expect(row['cx'], closeTo(row['boxCx'] as num, 0.01));
        expect(row['cy'], closeTo(row['boxCy'] as num, 0.01));
      }
      expect(
        (measured['${size.name}-override-icon'] as Map)['colour'],
        'rgb(255, 0, 0)',
      );
    });
    test('${size.name}: real small/non-square direct images fill the cell', () {
      for (final fixture in kCarouselBannerImages) {
        final row = measured['${size.name}-${fixture.name}'] as Map;
        expect(row['naturalWidth'], fixture.width);
        expect(row['naturalHeight'], fixture.height);
        expect(row['width'], side);
        expect(row['height'], side);
        expect(row['cx'], row['boxCx']);
        expect(row['cy'], row['boxCy']);
        expect(row['alt'], fixture.name);
        expect(row['caller'], 'preserved');
        // Read pixels near each side, away from the round corner and seam.
        for (final (fraction, expected) in [
          (0.1, [255, 0, 0]),
          (0.9, [0, 0, 255]),
        ]) {
          final pixel = screenshot.getPixel(
            ((row['x'] as num) + side * fraction).floor(),
            ((row['y'] as num) + side / 2).floor(),
          );
          expect([pixel.r, pixel.g, pixel.b], expected);
        }
      }
      final caller = measured['${size.name}-caller-root'] as Map;
      expect(caller['width'], side);
      expect(caller['height'], side);
    });
    test(
      '${size.name}: caller sizing wins and nested images retain their layout',
      () {
        for (final (name, width, height) in [
          ('inline', 14, 12),
          ('class', 18, 10),
          ('nested', 8, 8),
        ]) {
          final row = measured['${size.name}-$name'] as Map;
          expect(row['width'], width);
          expect(row['height'], height);
        }
        expect(
          (measured['${size.name}-inline'] as Map)['objectFit'],
          'contain',
        );
      },
    );
  }
  test('optional thumbnail and interactive wrapper retain their behavior', () {
    expect(measured['emptyBoxes'], [0, 0]);
    expect(measured['interactive'], ['button', 'button']);
  });
}
