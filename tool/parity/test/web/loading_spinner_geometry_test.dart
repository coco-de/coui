import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  test(
    'custom spinner paints noon to east with round caps and rotates',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'spinner-geometry-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final browser = await launchCaptureBrowser(width: 800, height: 1200);
      addTearDown(browser.close);
      final body = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          CoUIWeb(
            theme: .coui,
            child: const Loading(
              id: 'spinner',
              loadingStyle: CoreLoadingStyle(
                size: 32,
                strokeWidth: 4,
                duration: Duration(milliseconds: 700),
                color: CoreColor.token(CoreColors.primary),
                trackColor: CoreColor.token(CoreColors.surfaceContainerHigh),
              ),
            ),
          ),
        ]),
      );
      final html = File('${directory.path}/index.html')
        ..writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml: body,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            animationFreezeCss: kCaptureInitialAnimationCss,
          ),
        );
      final page = await browser.newPage();
      await page.goto(html.uri.toString());
      await page.waitForFunction('() => document.getAnimations().length > 0');
      final measured =
          jsonDecode(
                await page.evaluate<String>('''
() => {
 const root=document.getElementById('spinner'), sweep=root.querySelector('.co-loading-spinner');
 const circle=sweep.querySelector('circle'), s=getComputedStyle(circle);
 const a=document.getAnimations()[0]; a.pause(); a.currentTime=0;
 return JSON.stringify({width:root.getBoundingClientRect().width,
   radius:circle.getBBox().width/2,stroke:s.strokeWidth,cap:s.strokeLinecap,
   colour:s.stroke,track:getComputedStyle(root.querySelector('circle')).stroke,
   duration:a.effect.getTiming().duration});
}
'''),
              )
              as Map;
      expect(measured['width'], 32);
      expect(measured['radius'], 14);
      expect(measured['stroke'], '4px');
      expect(measured['cap'], 'round');
      expect(measured['duration'], 700);
      expect(measured['colour'], isNot(measured['track']));
      final root = await page.$('#spinner');
      final image = img.decodePng(
        Uint8List.fromList(await root.screenshot()),
      )!;
      int delta(img.Pixel a, img.Pixel b) =>
          (a.r - b.r).abs().toInt() +
          (a.g - b.g).abs().toInt() +
          (a.b - b.b).abs().toInt();
      // NE and east are swept; NW and west remain track. This catches the
      // old top-border arc even if its computed radius and dimensions agree.
      expect(
        delta(image.getPixel(26, 6), image.getPixel(30, 16)),
        lessThan(10),
      );
      expect(delta(image.getPixel(6, 6), image.getPixel(2, 16)), lessThan(10));
      expect(
        delta(image.getPixel(30, 16), image.getPixel(2, 16)),
        greaterThan(30),
      );
      await page.evaluate<void>(
        '() => {const a=document.getAnimations()[0];a.currentTime=175;}',
      );
      await page.evaluate<void>(
        '() => new Promise(r=>requestAnimationFrame(r))',
      );
      // At a quarter cycle the same sweep is now in the southeast quadrant.
      final rotated = img.decodePng(
        Uint8List.fromList(await root.screenshot()),
      )!;
      expect(
        delta(rotated.getPixel(26, 26), image.getPixel(26, 6)),
        lessThan(10),
      );
      expect(delta(rotated.getPixel(6, 6), image.getPixel(6, 6)), lessThan(10));
    },
  );
}
