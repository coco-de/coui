// The clickable host receives caller layout constraints; its visual drop
// zone must occupy that same box, as the Flutter child does under SizedBox.
// Check the actual browser layout rather than a particular flex declaration.
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' show Browser, Page;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  late Browser browser;
  late Page page;
  late Directory directory;

  setUpAll(() async {
    browser = await launchCaptureBrowser(width: 800, height: 800);
    directory = Directory.systemTemp.createTempSync('file-input-constraints-');
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });
  setUp(() async => page = await browser.newPage());
  tearDown(() => page.close());

  Future<void> render(
    FileInput child,
    String theme, {
    double? width,
    CoreSurfaceStyleId? surfaceStyle,
  }) async {
    final body = await renderComponentBodyHtml(
      CoUIWeb(
        theme: .coui,
        child: Component.element(
          tag: 'div',
          attributes: {
            'style': width == null ? '' : 'width:${width}px',
          },
          children: [child],
        ),
      ),
    );
    final file = File('${directory.path}/fixture.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          theme: theme,
          surfaceStyleId: surfaceStyle?.name,
          additionalHeadHtml:
              '<style>${buildLocalFontFaceCss()}</style>'
              '${buildLocalIconifyHeadHtml()}',
        ),
      );
    await page.goto(file.uri.toString());
    await page.evaluate<void>('() => document.fonts.ready');
  }

  Future<Map<String, Object?>> geometry() =>
      page.evaluate<Map<String, Object?>>(
        '''
    () => {
      const host = document.querySelector('#zone');
      const zone = host.querySelector('.coui-file-input');
      const h = host.getBoundingClientRect(), z = zone.getBoundingClientRect();
      const edge = zone.querySelector('svg rect').getBoundingClientRect();
      return {hostWidth:h.width, zoneWidth:z.width,
        hostHeight:h.height, zoneHeight:z.height, left:z.left-h.left,
        borderWidth:edge.width, scrollWidth:host.scrollWidth};
    }'''
            .trim(),
      );

  for (final theme in ['light', 'dark']) {
    for (final (name, widget, width) in [
      (
        'explicit CSS width',
        const FileInput(
          id: 'zone',
          css: Styles(raw: {'width': '600px'}),
        ),
        600.0,
      ),
      (
        'full-width class',
        const FileInput(id: 'zone', classes: 'w-full'),
        280.0,
      ),
      (
        'disabled',
        const FileInput(
          id: 'zone',
          enabled: false,
          css: Styles(raw: {'width': '480px'}),
        ),
        480.0,
      ),
      (
        'selected files',
        const FileInput(
          id: 'zone',
          selectedFiles: ['report.pdf'],
          css: Styles(raw: {'width': '360px'}),
        ),
        360.0,
      ),
    ]) {
      test('$name ($theme): visual border fills its clickable host', () async {
        await render(widget, theme, width: width);
        final actual = await geometry();
        expect(actual['hostWidth'], closeTo(width, 0.01));
        expect(actual['zoneWidth'], closeTo(width, 0.01));
        expect(actual['zoneHeight'], actual['hostHeight']);
        expect(actual['left'], 0);
      });
    }

    test(
      'intrinsic ($theme): no width is forced on an unconstrained host',
      () async {
        await render(const FileInput(id: 'zone'), theme);
        final actual = await geometry();
        expect(actual['hostWidth'], lessThan(800));
        expect(actual['zoneWidth'], actual['hostWidth']);
        expect(actual['zoneHeight'], actual['hostHeight']);
      },
    );
  }

  for (final style in [
    CoreSurfaceStyleId.neoBrutalism,
    CoreSurfaceStyleId.claymorphism,
    CoreSurfaceStyleId.neumorphism,
    CoreSurfaceStyleId.liquidGlass,
  ]) {
    test('$style retains the caller width', () async {
      await render(
        const FileInput(id: 'zone', classes: 'w-full'),
        'light',
        width: 600,
        surfaceStyle: style,
      );
      final actual = await geometry();
      expect(actual['zoneWidth'], 600);
      expect(actual['hostWidth'], 600);
    });
  }

  test('a parent constrains an oversized caller width on both boxes', () async {
    await render(
      const FileInput(
        id: 'zone',
        css: Styles(raw: {'width': '600px'}),
      ),
      'light',
      width: 200,
    );
    final actual = await geometry();
    expect(actual['hostWidth'], 200);
    expect(actual['zoneWidth'], 200);
    expect(actual['left'], 0);
  });

  test(
    'a caller width change reaches the border without rebuilding content',
    () async {
      await render(
        const FileInput(
          id: 'zone',
          css: Styles(raw: {'width': '600px'}),
        ),
        'light',
      );
      for (final width in [600, 240, 480]) {
        await page.evaluate<void>(
          '''
        (width) => {
          document.querySelector('#zone').style.width = width + 'px';
        }
        '''
              .trim(),
          args: [width],
        );
        final actual = await geometry();
        expect(actual['zoneWidth'], closeTo(width, 0.01));
        expect(actual['hostWidth'], closeTo(width, 0.01));
        expect(actual['left'], 0);
      }
    },
  );
}
