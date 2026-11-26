import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

void main() {
  final chrome = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
  ].where((path) => File(path).existsSync()).firstOrNull;
  test(
    'hydrated Command paints square Buttons with inherited glyphs '
    'and calls onDismiss',
    () async {
      final fixture = Directory.systemTemp.createTempSync(
        'coui-command-fullscreen-',
      );
      Browser? browser;
      try {
        final js = '${fixture.path}/entry.js';
        final compiled = await Process.run(Platform.resolvedExecutable, [
          'compile',
          'js',
          '-O2',
          '-o',
          js,
          'tool/parity/src/web/command_fullscreen_entry.dart',
        ]);
        expect(
          compiled.exitCode,
          0,
          reason: '${compiled.stdout}\n${compiled.stderr}',
        );
        final html = File('${fixture.path}/index.html')
          ..writeAsStringSync(
            buildOfflineTailwindHarnessHtml(
              bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
              themeConfig: ThemeConfig.defaults(),
              vendoredTailwindScript: loadVendoredTailwindScript(),
            ),
          );
        browser = await launchCaptureBrowser(
          width: 800,
          height: 720,
          executablePath: chrome,
        );
        final page = await browser.newPage();
        await page.goto(Uri.file(html.path).toString(), wait: Until.load);
        await page.waitForFunction(
          '() => document.querySelector("#dark-lg svg") !== null',
        );
        await page.evaluate<void>(
          '() => new Promise(r => requestAnimationFrame( '
          '() => requestAnimationFrame(r)))',
        );
        for (final brightness in ['light', 'dark']) {
          for (final size in ['sm', 'md', 'lg']) {
            final key = '$brightness-$size';
            final measured = await page.evaluate<Map<dynamic, dynamic>>(
              '''
          key => {
            const host = document.getElementById(key);
            const glyph = host.querySelector('svg');
            const button = glyph.closest('button,[role="button"]');
            const b = button.getBoundingClientRect(), g = glyph.getBoundingClientRect();
            const expected = document.createElement('span');
            expected.style.color = 'rgb(var(--coui-on-surface-variant))';
            host.append(expected);
            const ink = getComputedStyle(expected).color;
            expected.remove();
            return {width:b.width, height:b.height, glyphWidth:g.width, glyphHeight:g.height,
              color:getComputedStyle(glyph).color, expectedInk:ink,
              centerX: g.x + g.width/2 - b.x - b.width/2,
              centerY: g.y + g.height/2 - b.y - b.height/2,
              hitX:b.x+2, hitY:b.y+b.height/2, path:glyph.innerHTML};
          }''',
              args: [key],
            );
            final extent = {'sm': 32, 'md': 40, 'lg': 48}[size]!;
            final glyph = {'sm': 16, 'md': 18, 'lg': 20}[size]!;
            expect(measured['width'], extent, reason: key);
            expect(measured['height'], extent, reason: key);
            expect(measured['glyphWidth'], glyph, reason: key);
            expect(measured['glyphHeight'], glyph, reason: key);
            expect(measured['color'], measured['expectedInk'], reason: key);
            expect(measured['centerX'], closeTo(0, .1), reason: key);
            expect(measured['centerY'], closeTo(0, .1), reason: key);
            expect(
              measured['path'],
              contains('m12 19l-7-7l7-7m7 7H5'),
              reason: 'actual arrow-left SVG',
            );
            await page.mouse.click(
              Point(
                (measured['hitX'] as num).toDouble(),
                (measured['hitY'] as num).toDouble(),
              ),
            );
            expect(
              await page.evaluate<int>(
                'key => couiCommandDismissals(key)',
                args: [key],
              ),
              1,
              reason: key,
            );
            stdout.writeln(
              '$key: button $extent×$extent, glyph $glyph×$glyph, '
              '${measured['color']}, centred, edge click callback=1',
            );
          }
        }
        final override = await page.evaluate<List<dynamic>>(
          '''
        () => {
        const svg = document.querySelector('#override svg'), rect = svg.getBoundingClientRect();
        return [rect.width, rect.height, getComputedStyle(svg).color];
      }'''
              .trim(),
        );
        expect(override, [22, 22, 'rgb(18, 52, 86)']);
        final screenshot = Platform.environment['COMMAND_PROBE_SCREENSHOT'];
        if (screenshot != null) {
          final bytes = await page.screenshot(format: ScreenshotFormat.png);
          await File(screenshot).writeAsBytes(bytes);
        }
      } finally {
        await browser?.close();
        fixture.deleteSync(recursive: true);
      }
    },
    skip: chrome == null ? 'system Chromium unavailable' : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
