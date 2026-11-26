// The floating glass bar grows a little while its lens is up — the capsule,
// the lens and the destinations together, about a point mirrored from the
// lens (`CoreGlassNavigationMotion.barSwell`, `barSwellOrigin`). The runtime
// that draws it runs only in a browser, so this reads it in Chrome: what the
// bar is drawn at, the point it grows from, and whether the lens still lands
// under the finger while the bar is drawn larger than it is laid out.
import 'dart:io';

import 'package:coui_web/coui_web.dart'
    show CoreGlassNavigationMotion, ThemeConfig;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// What a bar is drawn at, the point it grows from (computed, in px of its
/// own box), and where its lens is drawn across it as a fraction — a uniform
/// scale keeps every fraction across the bar.
const _kDrawn = '''
id => {
  const n = document.getElementById(id);
  const s = getComputedStyle(n);
  const r = n.getBoundingClientRect();
  const l = document.getElementById(id + '-lens').getBoundingClientRect();
  const o = s.transformOrigin.split(' ').map(parseFloat);
  return {scale: s.scale, width: n.offsetWidth, height: n.offsetHeight,
    drawnWidth: r.width, originX: o[0], originY: o[1],
    lensX: (l.x + l.width / 2 - r.x) / r.width,
    lensY: (l.y + l.height / 2 - r.y) / r.height,
    lensCentreX: l.x + l.width / 2};
}''';

/// The drawn centre of destination `i` of `id`.
const _kCentre = '''
(id, i) => {
  const b = document.querySelector(
    '#' + id + ' [data-coui-nav-index="' + i + '"]').getBoundingClientRect();
  return [b.x + b.width / 2, b.y + b.height / 2];
}''';

/// How far the bar's lens is drawn from destination `i`'s centre, in px.
const _kLensOffDestination = '''
i => {
  const l = document.getElementById('probe-nav-lens').getBoundingClientRect();
  const d = document.querySelector(
    '#probe-nav [data-coui-nav-index="' + i + '"]').getBoundingClientRect();
  return (l.x + l.width / 2) - (d.x + d.width / 2);
}''';

double _origin(num lens) =>
    CoreGlassNavigationMotion.barSwellOrigin(lens.toDouble());

void main() {
  final chrome = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
  ].where((path) => File(path).existsSync()).firstOrNull;
  Browser? browser;
  late Page page;
  late Directory fixture;
  late File html;

  Future<void> settle() => page.evaluate<void>(
    '() => new Promise(r => '
    'requestAnimationFrame(() => requestAnimationFrame(r)))',
  );
  Future<Map<String, dynamic>> drawn(String bar) =>
      page.evaluate<Map<String, dynamic>>(_kDrawn, args: [bar]);
  Future<Point<double>> centre(String bar, int index) async {
    final value = await page.evaluate<List<dynamic>>(
      _kCentre,
      args: [bar, index],
    );

    return Point((value[0] as num).toDouble(), (value[1] as num).toDouble());
  }

  Future<void> swollen(String bar) => page.waitForFunction(
    'Number(getComputedStyle(document.getElementById("$bar")).scale) > '
    '${1 + CoreGlassNavigationMotion.barSwell / 2}',
  );
  Future<void> atRest(String bar) => page.waitForFunction(
    'getComputedStyle(document.getElementById("$bar")).scale === "none"',
  );

  group(
    'the glass bar swell in Chrome',
    () {
      setUpAll(() async {
        if (chrome == null) return;
        fixture = Directory.systemTemp.createTempSync('coui-glass-swell-');
        final js = '${fixture.path}/entry.js';
        final result = await Process.run(Platform.resolvedExecutable, [
          'compile',
          'js',
          '-O2',
          '-o',
          js,
          'tool/parity/src/web/glass_interaction_entry.dart',
        ]);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        // Real motion: only the VRT harness freezes transitions.
        final content = buildOfflineTailwindHarnessHtml(
          bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          surfaceStyleId: 'liquidGlass',
        ).replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
        html = File('${fixture.path}/index.html')..writeAsStringSync(content);
        browser = await launchCaptureBrowser(
          width: 800,
          height: 700,
          executablePath: chrome,
        );
      });
      setUp(() async {
        if (chrome == null) return;
        page = await browser!.newPage();
        await page.goto(Uri.file(html.path).toString(), wait: Until.load);
        await page.waitForFunction(
          'typeof couiProbeConfigure === "function" && '
          'document.querySelector(".coui-navigation-glass-active") !== null',
        );
        await settle();
      });
      tearDown(() async {
        if (chrome != null) await page.close();
      });
      tearDownAll(() async {
        if (chrome == null) return;
        await browser?.close();
        fixture.deleteSync(recursive: true);
      });

      test('the bar is at rest until it is held', () async {
        expect((await drawn('probe-nav'))['scale'], 'none');
      });

      test(
        'the whole bar grows about a point mirrored from the lens',
        () async {
          await page.mouse.move(await centre('probe-nav', 0));
          await page.mouse.down();
          await swollen('probe-nav');
          final held = await drawn('probe-nav');
          final width = (held['width'] as num).toDouble();
          // The capsule, the lens and the destinations are drawn together.
          expect(
            (held['drawnWidth'] as num) / width,
            greaterThan(1 + CoreGlassNavigationMotion.barSwell / 2),
          );
          expect(
            held['originX'] as num,
            closeTo(_origin(held['lensX'] as num) * width, 1),
          );
          // The first destination is on the left; the right side holds.
          expect(held['originX'] as num, greaterThan(width / 2));
          await page.mouse.up();
          await atRest('probe-nav');
        },
      );

      Future<double> lensOffDestination(int index) => page
          .evaluate<num>(_kLensOffDestination, args: [index])
          .then((value) => value.toDouble());

      test('the lens sits on its destination while the bar is grown', () async {
        // The runtime measures the bar as it is drawn and places the lens in
        // the bar as it is laid out. Reading the drawn boxes as laid-out ones
        // puts the lens off its destination by a share of its distance from
        // the bar's start.
        await page.mouse.move(await centre('probe-nav', 3));
        await page.mouse.down();
        await swollen('probe-nav');
        for (var frame = 0; frame < 30; frame++) {
          await settle();
        }
        expect((await drawn('probe-nav'))['scale'], isNot('none'));
        expect(await lensOffDestination(3), closeTo(0, .5));
        await page.mouse.up();
        await atRest('probe-nav');
      });

      test('a drag reads the finger on the bar as it is laid out', () async {
        // The swell is drawn only: a finger that goes to where a destination
        // is laid out puts the lens on it, while the bar is grown about a
        // point that follows the lens.
        final laidOut = await centre('probe-nav', 3);
        await page.mouse.move(await centre('probe-nav', 0));
        await page.mouse.down();
        await swollen('probe-nav');
        await page.mouse.move(laidOut, steps: 12);
        for (var frame = 0; frame < 30; frame++) {
          await settle();
        }
        expect((await drawn('probe-nav'))['scale'], isNot('none'));
        expect(await lensOffDestination(3), closeTo(0, .5));
        await page.mouse.up();
        await atRest('probe-nav');
      });

      test('a right-to-left row is measured from its right', () async {
        await page.evaluate<void>('() => document.documentElement.dir="rtl"');
        await settle();
        await page.mouse.move(await centre('probe-nav', 0));
        await page.mouse.down();
        await swollen('probe-nav');
        final held = await drawn('probe-nav');
        final width = (held['width'] as num).toDouble();
        expect(held['originX'] as num, lessThan(width / 2));
        expect(
          held['originX'] as num,
          closeTo(_origin(held['lensX'] as num) * width, 1),
        );
        await page.mouse.up();
        await atRest('probe-nav');
      });

      test('reduced motion never grows the bar', () async {
        await page.emulateMediaFeatures([
          MediaFeature.prefersReducedMotion('reduce'),
        ]);
        await settle();
        await page.mouse.move(await centre('probe-nav', 0));
        await page.mouse.down();
        for (var frame = 0; frame < 10; frame++) {
          await settle();
        }
        expect((await drawn('probe-nav'))['scale'], 'none');
        await page.mouse.up();
      });

      test('the rail grows down its column', () async {
        await page.evaluate<void>(
          '() => document.querySelector("#probe-rail") '
          '.scrollIntoView({block: "center"})',
        );
        await page.waitForFunction(
          'document.querySelector("#probe-rail").classList '
          '.contains("coui-navigation-glass-vertical")',
        );
        await settle();
        await page.mouse.move(await centre('probe-rail', 0));
        await page.mouse.down();
        await swollen('probe-rail');
        final held = await drawn('probe-rail');
        final height = (held['height'] as num).toDouble();
        expect(held['originX'] as num, closeTo((held['width'] as num) / 2, 1));
        expect(
          held['originY'] as num,
          closeTo(_origin(held['lensY'] as num) * height, 1),
        );
        expect(held['originY'] as num, greaterThan(height / 2));
        await page.mouse.up();
        await atRest('probe-rail');
      });
    },
    skip: chrome == null ? 'Chrome is unavailable' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
