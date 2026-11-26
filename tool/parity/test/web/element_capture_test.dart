import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:puppeteer/puppeteer.dart' show Browser, Page;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/element_capture.dart';

void main() {
  late Browser browser;
  late Page page;
  setUpAll(() async {
    browser = await launchCaptureBrowser(width: 800, height: 1200);
  });
  tearDownAll(() => browser.close());
  setUp(() async => page = await browser.newPage());
  tearDown(() => page.close());

  Future<Map<String, Object?>> viewport() async =>
      (jsonDecode(
                await page.evaluate<String>(
                  '() => JSON.stringify({ '
                  'width: innerWidth, height: innerHeight, '
                  'x: scrollX, y: scrollY })',
                ),
              )
              as Map)
          .cast<String, Object?>();

  for (final (width, height, query) in [
    (1000, 40, '(min-width: 900px)'),
    (80, 1400, '(min-height: 1300px)'),
  ]) {
    test(
      '$width by $height capture keeps the actual media-query viewport',
      () async {
        await page.setContent('''
        <!doctype html><style>
        html,body { margin:0; }
        #root { width:${width}px; height:${height}px; background:rgb(0,128,0); }
        @media $query { #root { background:rgb(255,0,0); } }
      </style><div id="root"></div>''');
        final before = await viewport();
        final image = img.decodePng(
          await captureElementPng(page, await page.$('#root')),
        )!;
        expect((image.width, image.height), (width, height));
        for (final pixel in [
          image.getPixel(0, 0),
          image.getPixel(width - 1, height - 1),
        ]) {
          expect(
            [pixel.r, pixel.g, pixel.b],
            [0, 128, 0],
            reason:
                'Keep the 800x1200 media-query state, including pixels '
                'beyond the viewport.',
          );
        }
        expect(await viewport(), before);
      },
    );
  }

  test('document clip coordinates preserve scroll position', () async {
    await page.setContent('''
    <!doctype html><style>
      html,body { margin:0; }
      body { width:1600px; height:3000px; }
      #root { position:absolute; left:250px; top:1700px; width:80px; height:40px;
        background:rgb(0,128,0); }
    </style><div id="root"></div>''');
    await page.evaluate<void>('() => scrollTo(100, 1400)');
    final before = await viewport();
    expect(before['x'], 100);
    expect(before['y'], 1400);
    final image = img.decodePng(
      await captureElementPng(page, await page.$('#root')),
    )!;
    expect((image.width, image.height), (80, 40));
    for (final pixel in image) {
      expect([pixel.r, pixel.g, pixel.b], [0, 128, 0]);
    }
    expect(await viewport(), before);
  });

  test(
    'in-viewport fractional bounds retain existing pixels and raster rounding',
    () async {
      await page.setContent('''
      <!doctype html><style>
      html,body { margin:0; }
      #root { position:absolute; left:3.25px; top:2.25px;
        width:80.25px; height:40.25px; background:rgb(0,128,0); }
    </style><div id="root"></div>''');
      final root = await page.$('#root');
      final original = img.decodePng(
        Uint8List.fromList(await root.screenshot(format: .png)),
      )!;
      final captured = img.decodePng(await captureElementPng(page, root))!;
      expect(
        (captured.width, captured.height),
        (original.width, original.height),
      );
      expect(captured.getBytes(), original.getBytes());
    },
  );
}
