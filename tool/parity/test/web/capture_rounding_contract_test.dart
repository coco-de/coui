import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:puppeteer/puppeteer.dart' show Browser;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/element_capture.dart';

void main() {
  late Browser browser;
  setUpAll(() async {
    browser = await launchCaptureBrowser(width: 800, height: 1200);
  });
  tearDownAll(() => browser.close());

  test(
    'Chrome captures the laid-out size without nearest-grid inflation',
    () async {
      final vectors =
          jsonDecode(
                File(
                  'tool/parity/fixtures/clip_rounding_vectors.json',
                ).readAsStringSync(),
              )
              as List;
      final page = await browser.newPage();
      try {
        for (final vector in vectors.cast<Map<String, dynamic>>()) {
          final requested = (vector['requested'] as List).cast<num>();
          await page.setContent(
            '<style>body{margin:0}#box{width:${requested[0]}px;'
            'height:${requested[1]}px;background:red}</style>'
            '<div id="box"></div>',
          );
          expect(await page.evaluate<num>('() => devicePixelRatio'), 1);
          final png = await captureElementPng(page, await page.$('#box'));
          final bytes = ByteData.sublistView(png);
          expect(
            [bytes.getUint32(16), bytes.getUint32(20)],
            vector['png'],
            reason: 'requested CSS size $requested',
          );
        }
      } finally {
        await page.close();
      }
    },
  );
}
