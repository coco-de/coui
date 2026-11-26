// The navigation bar that follows scrolling content (`NavigationBar.compact`)
// — the listener that hears the content, the transform the compact form is
// drawn through, and the glass lens under a bar drawn smaller than it is laid
// out all run only in a browser, so this reads them in Chrome. The rule that
// turns scrolling into "compact or not" is Core's and its table is replayed
// DOM-free by the package tests; what is checked here is that a real scroll
// reaches it and that what Chrome draws is the form the Flutter twin draws.
import 'dart:io';

import 'package:coui_web/coui_web.dart'
    show CoreGlassNavigationMotion, CoreNavigationBarStyle, ThemeConfig;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

const double _compact = CoreNavigationBarStyle.glassCompactScale;

/// The bar as it is laid out and as it is drawn: the compact marker, the
/// factor of its transform, the swell (`scale`) and its origin, and both
/// boxes.
const _kBar = '''
() => {
  const n = document.getElementById('probe-nav');
  const s = getComputedStyle(n);
  const r = n.getBoundingClientRect();
  const m = s.transform === 'none'
    ? [1] : s.transform.slice(7, -1).split(',').map(parseFloat);
  return {compact: n.hasAttribute('data-coui-navigation-compact'),
    factor: m[0], swell: s.scale === 'none' ? 1 : Number(s.scale),
    originX: parseFloat(s.transformOrigin.split(' ')[0]),
    duration: s.transitionDuration,
    width: n.offsetWidth, height: n.offsetHeight,
    left: r.left, right: r.right, top: r.top, bottom: r.bottom};
}''';

/// Each caption's fold as it is laid out — its height and opacity — and the
/// caption it still holds.
const _kFolds = r'''
() => [...document.querySelectorAll('#probe-nav [id$="-label"]')].map(l => {
  const f = l.parentElement.parentElement;
  return {height: f.offsetHeight, opacity: Number(getComputedStyle(f).opacity),
    caption: l.textContent};
})''';

/// How far the lens is drawn from destination `i`'s centre down the bar,
/// and how tall each is drawn.
const _kLensOnDestination = '''
i => {
  const l = document.getElementById('probe-nav-lens').getBoundingClientRect();
  const d = document.querySelector(
    '#probe-nav [data-coui-nav-index="' + i + '"]').getBoundingClientRect();
  return {dy: (l.y + l.height / 2) - (d.y + d.height / 2),
    lens: l.height, destination: d.height};
}''';

/// Every refracting surface of the bar: its box as it is laid out, and the
/// box its displacement map was built for.
const _kRefractionMaps = r'''
() => [document.getElementById('probe-nav'),
    ...document.querySelectorAll('#probe-nav *')].flatMap(e => {
  const m = /url\(["']?#([^"')]+)/.exec(
    e.style.getPropertyValue('backdrop-filter'));
  if (!m) return [];
  const map = document.getElementById(m[1]).querySelector('feImage');
  return [{width: e.offsetWidth, height: e.offsetHeight,
    mapWidth: Number(map.getAttribute('width')),
    mapHeight: Number(map.getAttribute('height'))}];
})''';

/// Bar `id` at rest: its box, and where each caption and each icon's box
/// sit in it.
const _kResting = r'''
id => {
  const n = document.getElementById(id);
  const o = n.getBoundingClientRect();
  const box = e => {
    const r = e.getBoundingClientRect();
    return [r.x - o.x, r.y - o.y, r.width, r.height];
  };
  return {width: n.offsetWidth, height: n.offsetHeight,
    folds: n.querySelectorAll('[style*="0fr"], [style*="1fr 0"]').length,
    captions: [...n.querySelectorAll('[id$="-label"]')].map(box),
    destinations: [...n.querySelectorAll('[data-coui-nav-chrome]')].map(box)};
}''';

/// The drawn centre of destination `i`.
const _kCentre = '''
i => {
  const b = document.querySelector(
    '#probe-nav [data-coui-nav-index="' + i + '"]').getBoundingClientRect();
  return [b.x + b.width / 2, b.y + b.height / 2];
}''';

/// How far the lens is drawn from destination `i`'s centre, in px.
const _kLensOffDestination = '''
i => {
  const l = document.getElementById('probe-nav-lens').getBoundingClientRect();
  const d = document.querySelector(
    '#probe-nav [data-coui-nav-index="' + i + '"]').getBoundingClientRect();
  return (l.x + l.width / 2) - (d.x + d.width / 2);
}''';

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

  Future<void> settle([int frames = 2]) async {
    for (var frame = 0; frame < frames; frame += 2) {
      await page.evaluate<void>(
        '() => new Promise(r => '
        'requestAnimationFrame(() => requestAnimationFrame(r)))',
      );
    }
  }

  Future<Map<String, dynamic>> bar() =>
      page.evaluate<Map<String, dynamic>>(_kBar);
  Future<Point<double>> centre(int index) async {
    final value = await page.evaluate<List<dynamic>>(_kCentre, args: [index]);

    return Point((value[0] as num).toDouble(), (value[1] as num).toDouble());
  }

  /// Scrolls the content to [top], a step at a time as a finger would.
  Future<void> scrollContent(double top) async {
    await page.evaluate<void>(
      'top => { document.getElementById("probe-viewport").scrollTop = top; }',
      args: [top],
    );
    await settle();
  }

  /// Gives the scaffold its own vertical list inside a horizontal page.
  /// No ancestor scrolls vertically, isolating the visibility test below
  /// from the nested-scroll filter.
  Future<void> useInnerContent() async {
    await page.evaluate<void>('''
() => {
      const viewport = document.getElementById('probe-viewport');
      for (const sibling of [...viewport.parentElement.children]) {
        if (sibling !== viewport) sibling.remove();
      }
      viewport.style.height = 'auto';
      viewport.style.overflow = 'visible';
      const content = document.getElementById('probe-strip').parentElement;
      const horizontal = document.createElement('div');
      horizontal.style.cssText = 'width:200px;height:260px;overflow-x:auto';
      const vertical = document.createElement('div');
      vertical.id = 'probe-inner-content';
      vertical.style.cssText = 'width:400px;height:240px;overflow-y:auto';
      content.replaceWith(horizontal);
      horizontal.append(vertical);
      vertical.append(content);
    }''');
    await settle();
  }

  Future<void> scrollInnerContent(int top) async {
    await page.evaluate<void>(
      '''
top => {
      document.getElementById('probe-inner-content').scrollTop = top;
    }''',
      args: [top],
    );
    await settle();
  }

  /// Waits for the bar's transform to arrive at [factor].
  Future<void> drawnAt(double factor) => page.waitForFunction(
    '''
(() => {
  const t = getComputedStyle(document.getElementById('probe-nav')).transform;
  const a = t === 'none' ? 1 : parseFloat(t.slice(7));
  return Math.abs(a - $factor) < 1e-4;
})()''',
  );

  Future<List<Map<String, dynamic>>> folds() async =>
      (await page.evaluate<List<dynamic>>(
        _kFolds,
      )).cast<Map<String, dynamic>>();

  /// Waits for every caption's fold to be closed, or open.
  Future<void> captionsFolded({required bool folded}) => page.waitForFunction(
    '''
(() => {
  const all = [...document.querySelectorAll('#probe-nav [id\$="-label"]')]
    .map(l => l.parentElement.parentElement);
  return all.length > 0 && all.every(f => ${folded ? 'f.offsetHeight === 0' : "getComputedStyle(f).opacity === '1'"});
})()''',
  );

  Future<void> makeCompact() async {
    await scrollContent(6);
    await scrollContent(60);
    await drawnAt(_compact);
    await captionsFolded(folded: true);
  }

  Future<String> events() => page.evaluate<String>('() => couiProbeEvents()');

  group(
    'the bar that follows scrolling content, in Chrome',
    () {
      setUpAll(() async {
        if (chrome == null) return;
        fixture = Directory.systemTemp.createTempSync('coui-nav-compact-');
        final js = '${fixture.path}/entry.js';
        final result = await Process.run(Platform.resolvedExecutable, [
          'compile',
          'js',
          '-O2',
          '-o',
          js,
          'tool/parity/src/web/navigation_compact_entry.dart',
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

      test('a bar whose captions sit in a fold rests as one whose captions '
          'do not', () async {
        // The fold carries the gap the stack would have had, and at rest it
        // is the caption's own box — nothing about the bar says it can fold.
        Future<Map<String, dynamic>> resting(String id) =>
            page.evaluate<Map<String, dynamic>>(_kResting, args: [id]);
        final folding = await resting('probe-nav');
        final plain = await resting('probe-plain');
        expect(await folds(), hasLength(4));
        expect(plain['captions'], hasLength(4));

        expect(folding['width'], plain['width']);
        expect(folding['height'], plain['height']);
        for (final part in ['captions', 'destinations']) {
          final a = (folding[part] as List).cast<List<dynamic>>();
          final b = (plain[part] as List).cast<List<dynamic>>();
          for (var index = 0; index < b.length; index++) {
            for (var side = 0; side < 4; side++) {
              expect(
                a[index][side] as num,
                closeTo(b[index][side] as num, .01),
                reason: '$part $index, side $side',
              );
            }
          }
        }
      });

      test('the bar is in full until the content moves', () async {
        final rest = await bar();
        expect(rest['compact'], isFalse);
        expect(rest['factor'], 1);
        expect(
          (rest['right'] as num) - (rest['left'] as num),
          closeTo(rest['width'] as num, .01),
        );
      });

      test(
        'scrolling toward the end folds the captions away and draws the '
        'glyphs smaller, toward the bottom edge',
        () async {
          final rest = await bar();
          final open = await folds();
          expect(open, hasLength(4));
          final caption = (open.first['height'] as num).toDouble();
          expect(caption, greaterThan(0));
          // Under the travel: still in full.
          await scrollContent(6);
          expect((await bar())['compact'], isFalse);

          await scrollContent(60);
          expect((await bar())['compact'], isTrue);
          await drawnAt(_compact);
          await captionsFolded(folded: true);
          final drawn = await bar();
          for (final fold in await folds()) {
            expect(fold['height'], 0, reason: '${fold['caption']}');
            expect(
              fold['opacity'] as num,
              closeTo(0, 1e-3),
              reason: '${fold['caption']}',
            );
          }
          // The captions still name the destinations.
          expect(
            (await folds()).map((fold) => fold['caption']),
            ['Home', 'Search', 'Alerts', 'Profile'],
          );
          final width = (rest['width'] as num).toDouble();
          // Laid out without the captions and no narrower: the bar keeps
          // the row it has, and each destination the least height its style
          // states — the glyph bar the glass preset draws.
          const glass = CoreNavigationBarStyle.glassBarStyle;
          final glyphs =
              glass.itemMinHeight! + glass.padding!.top + glass.padding!.bottom;
          expect(glyphs, lessThan((rest['height'] as num) - caption / 2));
          expect(drawn['width'], rest['width']);
          expect(drawn['height'] as num, closeTo(glyphs, .01));
          // Then drawn at the compact size.
          expect(
            (drawn['right'] as num) - (drawn['left'] as num),
            closeTo(width * _compact, .05),
          );
          expect(
            (drawn['bottom'] as num) - (drawn['top'] as num),
            closeTo(glyphs * _compact, .05),
          );
          // About the middle of the bottom edge.
          expect(drawn['bottom'] as num, closeTo(rest['bottom'] as num, .05));
          expect(
            ((drawn['left'] as num) + (drawn['right'] as num)) / 2,
            closeTo(
              ((rest['left'] as num) + (rest['right'] as num)) / 2,
              .05,
            ),
          );
        },
      );

      test('the glass bends for the bar as it is laid out, not as it is '
          'drawn', () async {
        // Folding the captions resizes the bar while it is drawn smaller,
        // so its map is rebuilt under the compact scale. Built for the drawn
        // rectangle it would stop short of the bar's far edges.
        Future<List<Map<String, dynamic>>> maps() async =>
            (await page.evaluate<List<dynamic>>(
              _kRefractionMaps,
            )).cast<Map<String, dynamic>>();
        final rest = await maps();
        expect(rest, isNotEmpty);

        await makeCompact();
        await settle(8);
        final compact = await maps();
        expect(compact, hasLength(rest.length));
        for (final surface in compact) {
          expect(surface['mapWidth'], surface['width']);
          expect(surface['mapHeight'], surface['height']);
        }
        // And it was rebuilt: the bar it bends for is the shorter one.
        expect(
          compact.map((surface) => surface['mapHeight']),
          isNot(rest.map((surface) => surface['mapHeight'])),
        );
      });

      test(
        'the selection keeps to its destination as the captions fold',
        () async {
          // The lens is fitted to the destination it marks; the destination
          // gets shorter under it, and back.
          Future<Map<String, dynamic>> lens() => page
              .evaluate<Map<String, dynamic>>(_kLensOnDestination, args: [0]);
          final rest = await lens();
          expect(rest['dy'] as num, closeTo(0, .5));

          await makeCompact();
          await settle(30);
          final compact = await lens();
          expect(compact['dy'] as num, closeTo(0, .5));
          expect(
            compact['destination'] as num,
            lessThan(rest['destination'] as num),
          );
          expect(
            (compact['lens'] as num) / (compact['destination'] as num),
            closeTo((rest['lens'] as num) / (rest['destination'] as num), .02),
          );

          await scrollContent(0);
          await drawnAt(1);
          await captionsFolded(folded: false);
          await settle(30);
          final back = await lens();
          expect(back['dy'] as num, closeTo(0, .5));
          expect(back['lens'] as num, closeTo(rest['lens'] as num, .5));
        },
      );

      test('scrolling back returns it', () async {
        final rest = await bar();
        await makeCompact();
        await scrollContent(54);
        expect((await bar())['compact'], isTrue, reason: 'under the travel');
        await scrollContent(40);
        expect((await bar())['compact'], isFalse);
        await drawnAt(1);
        await captionsFolded(folded: false);
        final back = await bar();
        for (final edge in ['left', 'right', 'top', 'bottom']) {
          expect(back[edge] as num, closeTo(rest[edge] as num, .05));
        }
      });

      test('the content reaching its start returns it', () async {
        await makeCompact();
        await page.evaluate<void>(
          '() => { document.getElementById("probe-viewport").scrollTop = 0; }',
        );
        await settle();
        expect((await bar())['compact'], isFalse);
      });

      test('a sideways scroll in the content does not move it', () async {
        await page.evaluate<void>(
          '() => { document.getElementById("probe-strip").scrollLeft = 300; }',
        );
        await settle(4);
        expect(
          await page.evaluate<num>(
            '() => document.getElementById("probe-strip").scrollLeft',
          ),
          300,
          reason: 'the strip did scroll',
        );
        expect((await bar())['compact'], isFalse);
      });

      test(
        'a nested vertical list cannot compact or restore the bar',
        () async {
          await page.evaluate<void>('''
() => {
          const nested = document.createElement('div');
          nested.id = 'probe-nested';
          nested.style.cssText = 'height:120px;overflow-y:auto';
          nested.innerHTML = '<div style="height:1000px"></div>';
          document.getElementById('probe-strip').after(nested);
        }''');
          Future<void> scrollNested(int top) async {
            await page.evaluate<void>(
              '''
top => {
            document.getElementById('probe-nested').scrollTop = top;
          }''',
              args: [top],
            );
            await settle();
          }

          await scrollNested(6);
          await scrollNested(60);
          expect((await bar())['compact'], isFalse);
          expect(
            await page.evaluate<num>(
              '() => document.getElementById("probe-nested").scrollTop',
            ),
            60,
          );
          await makeCompact();
          await scrollNested(0);
          expect((await bar())['compact'], isTrue);
          await scrollContent(0);
          await drawnAt(1);
          expect((await bar())['compact'], isFalse);
        },
      );

      for (final hiddenStyle in ['display:none', 'visibility:hidden']) {
        test('a hidden tab cannot restore the bar ($hiddenStyle)', () async {
          await useInnerContent();
          await scrollInnerContent(6);
          await scrollInnerContent(60);
          await drawnAt(_compact);
          await page.evaluate<void>(
            '''
style => {
            const hidden = document.createElement('div');
            hidden.style.cssText = style + ';height:120px;overflow-y:auto';
            hidden.innerHTML = '<div style="height:1000px"></div>';
            document.getElementById('probe-inner-content').parentElement.after(hidden);
            hidden.dispatchEvent(new Event('scroll'));
          }''',
            args: [hiddenStyle],
          );
          await settle();
          expect((await bar())['compact'], isTrue);
        });
      }

      test('a vertical list inside a horizontal page is content', () async {
        await useInnerContent();
        await scrollInnerContent(6);
        await scrollInnerContent(60);
        await drawnAt(_compact);
        expect((await bar())['compact'], isTrue);
        await scrollInnerContent(0);
        await drawnAt(1);
        expect((await bar())['compact'], isFalse);
      });

      test(
        'the page scrolling the whole scrollport does not move it',
        () async {
          // The page is a scroller further out, with the content's own
          // scrollport between it and the bar.
          await page.evaluate<void>('() => window.scrollTo(0, 30)');
          await settle();
          await page.evaluate<void>('() => window.scrollTo(0, 200)');
          await settle(4);
          expect(await page.evaluate<num>('() => window.scrollY'), 200);
          expect((await bar())['compact'], isFalse);
        },
      );

      test('selecting another destination returns it', () async {
        await makeCompact();
        await page.evaluate<void>('() => couiProbeConfigure("selected", "2")');
        await settle();
        expect((await bar())['compact'], isFalse);
        // And the content moving on makes it compact again from there.
        await scrollContent(80);
        expect((await bar())['compact'], isTrue);
      });

      test(
        '`always` is compact and `never` is not, whatever scrolls',
        () async {
          await page.evaluate<void>(
            '() => couiProbeConfigure("compact", "always")',
          );
          await settle();
          expect((await bar())['compact'], isTrue);
          await drawnAt(_compact);

          await page.evaluate<void>(
            '() => couiProbeConfigure("compact", "never")',
          );
          await settle();
          expect((await bar())['compact'], isFalse);
          await scrollContent(6);
          await scrollContent(200);
          await settle(4);
          final never = await bar();
          expect(never['compact'], isFalse);
          expect(never['factor'], 1);
        },
      );

      test('the size is reached at once under reduced motion', () async {
        await page.emulateMediaFeatures([
          MediaFeature.prefersReducedMotion('reduce'),
        ]);
        await settle();
        expect((await bar())['duration'], '0s');
        await scrollContent(6);
        await scrollContent(60);
        final drawn = await bar();
        expect(drawn['compact'], isTrue);
        expect(drawn['factor'] as num, closeTo(_compact, 1e-4));
      });

      Future<double> lensOffDestination(int index) => page
          .evaluate<num>(_kLensOffDestination, args: [index])
          .then((value) => value.toDouble());

      test('the lens sits on its destination under a compact bar', () async {
        // The runtime measures the bar as it is drawn and places the lens in
        // the bar as it is laid out; the compact form is one more scale
        // between the two.
        await makeCompact();
        await page.mouse.move(await centre(3));
        await page.mouse.down();
        await page.waitForFunction(
          'Number(getComputedStyle(document.getElementById("probe-nav"))'
          '.scale) > ${1 + CoreGlassNavigationMotion.barSwell / 2}',
        );
        await settle(30);
        expect(await lensOffDestination(3), closeTo(0, .5));
        await page.mouse.up();
      });

      test(
        'the swell grows a compact bar about its own point, and the compact '
        'form stays about the bottom edge',
        () async {
          final rest = await bar();
          await makeCompact();
          await page.mouse.move(await centre(0));
          await page.mouse.down();
          await page.waitForFunction(
            'Number(getComputedStyle(document.getElementById("probe-nav"))'
            '.scale) > ${1 + CoreGlassNavigationMotion.barSwell / 2}',
          );
          await settle(30);
          final held = await bar();
          expect(held['factor'] as num, closeTo(_compact, 1e-4));
          final swell = (held['swell'] as num).toDouble();
          expect(swell, greaterThan(1));
          final left = (rest['left'] as num).toDouble();
          final bottom = (rest['bottom'] as num).toDouble();
          final width = (rest['width'] as num).toDouble();
          // As it is laid out now: the captions are folded, and the bar
          // stands on the bottom edge it had.
          final height = (held['height'] as num).toDouble();
          expect(height, lessThan(rest['height'] as num));
          final origin = (held['originX'] as num).toDouble();
          // The swell first, about its origin on the bar as laid out; then
          // the compact scale about the middle of the bottom edge — the
          // order the Flutter twin nests the two transforms in.
          double x(double laidOut) =>
              left +
              width / 2 +
              _compact * (origin + swell * (laidOut - origin) - width / 2);
          double y(double laidOut) =>
              bottom +
              _compact * (height / 2 + swell * (laidOut - height / 2) - height);
          expect(held['left'] as num, closeTo(x(0), .1));
          expect(held['right'] as num, closeTo(x(width), .1));
          expect(held['top'] as num, closeTo(y(0), .1));
          expect(held['bottom'] as num, closeTo(y(height), .1));
          await page.mouse.up();
        },
      );

      test('a drag on a compact bar selects where the finger goes', () async {
        await makeCompact();
        final to = await centre(3);
        await page.mouse.move(await centre(0));
        await page.mouse.down();
        await page.mouse.move(to, steps: 12);
        await settle(30);
        expect(await lensOffDestination(3), closeTo(0, .75));
        await page.mouse.up();
        await settle(4);
        expect(await events(), 'nav:3');
      });
    },
    skip: chrome == null ? 'Chrome is not installed' : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
