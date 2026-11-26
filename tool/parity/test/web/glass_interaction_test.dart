import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:puppeteer/puppeteer.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

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
    '() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)))',
  );
  Future<void> configure(String name, String value) async {
    await page.evaluate<void>(
      '(n,v) => couiProbeConfigure(n,v)',
      args: [name, value],
    );
    await settle();
  }

  Future<String> events() => page.evaluate<String>('() => couiProbeEvents()');
  Future<int> selected() => page.evaluate<int>(
    '() => Number(document.querySelector("#probe-nav [aria-current]").dataset.couiNavIndex)',
  );
  Future<Point<double>> center(int index) async {
    final value = await page.evaluate<List<dynamic>>(
      '''i => {
      const b = document.querySelector('#probe-nav [data-coui-nav-index="'+i+'"]').getBoundingClientRect();
      return [b.x+b.width/2, b.y+b.height/2];
    }''',
      args: [index],
    );
    return Point((value[0] as num).toDouble(), (value[1] as num).toDouble());
  }

  Future<void> drag(int from, int to, {bool release = true}) async {
    await page.mouse.move(await center(from));
    await page.mouse.down();
    await page.mouse.move(await center(to), steps: 12);
    await settle();
    if (release) await page.mouse.up();
  }

  group(
    'shipped Web glass interactions',
    () {
      setUpAll(() async {
        if (chrome == null) return;
        fixture = Directory.systemTemp.createTempSync(
          'coui-glass-interaction-',
        );
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
        // Interaction coverage must run with real motion; only the VRT harness
        // freezes transitions. No production stylesheet or CI baseline is changed.
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
          'typeof couiProbeConfigure === "function" && document.querySelector(".coui-navigation-glass-active") !== null',
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

      test(
        'drag previews through a refracting lens, commits once on release',
        () async {
          await drag(0, 3, release: false);
          expect(await events(), isEmpty);
          expect(await selected(), 0);
          final lens = await page.evaluate<Map<String, dynamic>>('''() => {
        const l = document.querySelector('#probe-nav-lens');
        return {opacity: Number(l.style.opacity), height: l.getBoundingClientRect().height,
          filter: getComputedStyle(l).backdropFilter};
      }''');
          expect(lens['opacity'], greaterThan(0));
          expect(lens['height'], greaterThan(48));
          expect(lens['filter'], contains('url('));
          await page.mouse.up();
          await settle();
          expect(await events(), 'nav:3');
          expect(await selected(), 3);
          await page.waitForFunction(
            'document.querySelector("#probe-nav-lens").style.opacity === "0"',
          );
          expect(
            await page.evaluate<String>(
              '() => document.querySelector("#probe-nav-selection").style.opacity',
            ),
            '1',
          );
        },
      );

      group('the rail', () {
        Future<Point<double>> railCenter(int index) async {
          final value = await page.evaluate<List<dynamic>>(
            '''
i => {
          const b = document.querySelector('#probe-rail [data-coui-nav-index="'+i+'"]').getBoundingClientRect();
          return [b.x+b.width/2, b.y+b.height/2];
        }''',
            args: [index],
          );
          return Point(
            (value[0] as num).toDouble(),
            (value[1] as num).toDouble(),
          );
        }

        Future<int> railSelected() => page.evaluate<int>(
          '() => { '
          'const current = '
          'document.querySelector("#probe-rail [aria-current]"); '
          'return Number(current.dataset.couiNavIndex); }',
        );

        setUp(() async {
          if (chrome == null) return;
          // The rail is the fixture's last block; the pointer needs it in
          // the viewport.
          await page.evaluate<void>(
            '() => document.querySelector("#probe-rail") '
            '.scrollIntoView({block: "center"})',
          );
          await page.waitForFunction(
            'document.querySelector("#probe-rail").classList '
            '.contains("coui-navigation-glass-vertical")',
          );
          await settle();
        });

        test('is the icon-only capsule: 48 across, 212 for four', () async {
          final box = await page.evaluate<List<dynamic>>('''
() => {
            const r = document.querySelector('#probe-rail').getBoundingClientRect();
            const cells = [...document.querySelectorAll('#probe-rail [data-coui-nav-chrome]')]
              .map(e => e.getBoundingClientRect());
            const rest = document.querySelector('#probe-rail-selection').getBoundingClientRect();
            return [r.width, r.height, cells[0].width, cells[0].height,
              cells[1].top - cells[0].top, cells[0].left - r.left,
              rest.width, rest.height, rest.left - cells[0].left, rest.top - cells[0].top];
          }''');
          expect(box.sublist(0, 2), [48, 212]);
          // Each destination is the 40×48 cell, 52 from the next and 4
          // inside the capsule.
          expect(box.sublist(2, 6), [40, 48, 52, 4]);
          // At rest the selection is the selected cell.
          expect(box.sublist(6, 8), [40, 48]);
          expect(box[8], closeTo(0, .5));
          expect(box[9], closeTo(0, .5));
        });

        test('a drag down the column previews through the lens and commits '
            'once on release', () async {
          await page.mouse.move(await railCenter(0));
          await page.mouse.down();
          await page.mouse.move(await railCenter(3), steps: 12);
          await settle();
          expect(await events(), isEmpty);
          expect(await railSelected(), 0);
          final lens = await page.evaluate<Map<String, dynamic>>('''
() => {
            const l = document.querySelector('#probe-rail-lens');
            const b = l.getBoundingClientRect();
            return {opacity: Number(l.style.opacity), width: b.width,
              x: b.x + b.width / 2, y: b.y + b.height / 2,
              filter: getComputedStyle(l).backdropFilter};
          }''');
          final first = await railCenter(0);
          expect(lens['opacity'], greaterThan(0));
          // Held, the lens swells across the column, past its 40-wide cell.
          expect(lens['width'], greaterThan(40));
          expect(lens['filter'], contains('url('));
          // Down the column, never sideways.
          expect(lens['x'], closeTo(first.x, 1));
          expect(lens['y'], greaterThan(first.y + 52));
          await page.mouse.up();
          await settle();
          expect(await events(), 'rail:3');
          expect(await railSelected(), 3);
          await page.waitForFunction(
            'document.querySelector("#probe-rail-lens").style.opacity === "0"',
          );
          final rest = await page.evaluate<List<dynamic>>('''
() => {
            const b = document.querySelector('#probe-rail-selection').getBoundingClientRect();
            return [b.x + b.width / 2, b.y + b.height / 2];
          }''');
          final last = await railCenter(3);
          expect(rest[0], closeTo(last.x, 1));
          expect(rest[1], closeTo(last.y, 1));
        });

        test('a drag across the column never commits', () async {
          final start = await railCenter(1);
          await page.mouse.move(start);
          await page.mouse.down();
          await page.mouse.move(Point(start.x + 90, start.y), steps: 8);
          await settle();
          await page.mouse.up();
          await settle();
          expect(await events(), isEmpty);
          expect(await railSelected(), 0);
        });

        test(
          'the column counts from the top in a right-to-left page',
          () async {
            await page.evaluate<void>(
              '() => document.documentElement.dir="rtl"',
            );
            await settle();
            await page.mouse.move(await railCenter(0));
            await page.mouse.down();
            await page.mouse.move(await railCenter(2), steps: 12);
            await settle();
            await page.mouse.up();
            await settle();
            expect(await events(), 'rail:2');
            expect(await railSelected(), 2);
          },
        );

        test('a tap moves the selection to the tapped destination', () async {
          await page.mouse.click(await railCenter(2));
          await settle();
          expect(await events(), 'rail:2');
          await page.waitForFunction('''
(() => {
            const s = document.querySelector('#probe-rail-selection').getBoundingClientRect();
            const c = document.querySelector('#probe-rail [data-coui-nav-index="2"]').getBoundingClientRect();
            return Math.abs(s.top - c.top) < 1;
          })()''');
        });

        test('a hovered destination names itself beside the column', () async {
          await page.mouse.move(await railCenter(1));
          await page.waitForFunction(
            'document.querySelector("[role=tooltip]") !== null',
          );
          await settle();
          final at = await page.evaluate<List<dynamic>>('''
() => {
            const t = document.querySelector('[role="tooltip"]');
            const b = t.getBoundingClientRect();
            const d = document.querySelector('#probe-rail [data-coui-nav-index="1"]').getBoundingClientRect();
            return [t.textContent.trim(), b.left >= d.right,
              Math.abs((b.top + b.height / 2) - (d.top + d.height / 2)) < 2];
          }''');
          // To the right of the destination and level with it — not over
          // the destination above.
          expect(at, ['Search', true, true]);
          await page.mouse.move(const Point(0, 0));
          await page.waitForFunction(
            'document.querySelector("[role=tooltip]") === null',
          );
        });

        test('the opaque rail is the docked rail, with no lens', () async {
          await configure('local', 'defaultStyle');
          final state = await page.evaluate<List<dynamic>>('''
() => {
            const r = document.querySelector('#probe-rail');
            return [r.classList.contains('coui-navigation-glass-active'),
              getComputedStyle(r).borderRadius,
              document.querySelector('#probe-rail-item-0-label').classList.contains('sr-only')];
          }''');
          expect(state, [false, '0px', false]);
        });
      });

      group('a column of toolbar actions', () {
        Future<List<dynamic>> measure() => page.evaluate<List<dynamic>>('''
() => {
          const g = document.querySelector('#probe-actions [role="group"]');
          const r = g.getBoundingClientRect();
          const b = [...g.querySelectorAll('[aria-label]')]
            .map(e => e.getBoundingClientRect());
          return [r.width, r.height, b[0].width, b[0].height,
            b[1].top - b[0].top, b[1].left - b[0].left,
            getComputedStyle(g).flexDirection];
        }''');

        setUp(() async {
          if (chrome == null) return;
          await page.evaluate<void>(
            '() => document.querySelector("#probe-actions") '
            '.scrollIntoView({block: "center"})',
          );
          await settle();
        });

        test('is a glass capsule 48 across with a 48 seat each', () async {
          expect(await measure(), [48, 96, 48, 48, 48, 0, 'column']);
          // As wide as the rail it stands beside.
          expect(
            await page.evaluate<num>(
              '() => document.querySelector("#probe-rail") '
              '.getBoundingClientRect().width',
            ),
            48,
          );
        });

        Future<List<dynamic>> glyphs() => page.evaluate<List<dynamic>>('''
() => [...document.querySelectorAll('#probe-actions [role="group"] svg')]
          .map(e => e.getBoundingClientRect().width)''');

        test("draws the rail's 24 glyph under glass", () async {
          expect(await glyphs(), [24, 24]);
          expect(
            await page.evaluate<num>(
              '() => document.querySelector("#probe-rail svg") '
              '.getBoundingClientRect().width',
            ),
            24,
          );
        });

        test('each action answers a press anywhere in its seat', () async {
          final box = await page.evaluate<List<dynamic>>('''
() => {
            const r = document
              .querySelector('#probe-actions [aria-label="Share"]')
              .getBoundingClientRect();
            return [r.x, r.y];
          }''');
          await page.mouse.click(
            Point((box[0] as num) + 3, (box[1] as num) + 3),
          );
          await page.click('#probe-actions [aria-label="Back"]');
          await settle();
          expect(await events(), 'action:share,action:back');
        });

        test(
          'the opaque column keeps its padding around smaller controls',
          () async {
            await configure('local', 'defaultStyle');
            final box = await measure();
            // 4 of padding around the controls' own 40.
            expect(box.sublist(0, 6), [48, 88, 40, 40, 40, 0]);
            expect(box[6], 'column');
            // And the button's own glyph.
            expect(await glyphs(), [18, 18]);
          },
        );
      });

      test('controlled refusal returns to the selected destination', () async {
        await configure('accept', 'false');
        await drag(0, 3);
        expect(await events(), 'nav:3');
        expect(await selected(), 0);
        await page.waitForFunction(
          'document.querySelector("#probe-nav-lens").style.opacity === "0"',
        );
        final left = await page.evaluate<num>(
          '() => document.querySelector("#probe-nav-selection").getBoundingClientRect().x',
        );
        expect(left, closeTo((await center(0)).x - 59, 1));
      });

      test(
        'disabled destination and pointer cancellation do not commit',
        () async {
          await drag(0, 1);
          expect(await events(), isEmpty);
          await drag(0, 3, release: false);
          await page.evaluate<void>(
            '''() => document.dispatchEvent(new PointerEvent('pointercancel', {pointerId:1,bubbles:true}))''',
          );
          await page.mouse.up();
          expect(await events(), isEmpty);
          expect(await selected(), 0);
        },
      );

      test(
        'local material overrides ambient and reactivates without remounting',
        () async {
          await configure('local', 'defaultStyle');
          expect(
            await page.evaluate<bool>(
              '() => document.querySelector("#probe-nav").classList.contains("coui-navigation-glass-active")',
            ),
            isFalse,
          );
          await configure('material', 'defaultStyle');
          await configure('local', 'liquidGlass');
          expect(
            await page.evaluate<bool>(
              '() => document.querySelector("#probe-nav").classList.contains("coui-navigation-glass-active")',
            ),
            isTrue,
          );
        },
      );

      test('live reduced motion settles a held lens immediately', () async {
        await drag(0, 3, release: false);
        await page.emulateMediaFeatures([
          MediaFeature.prefersReducedMotion('reduce'),
        ]);
        await settle();
        expect(
          await page.evaluate<String>(
            '() => document.querySelector("#probe-nav-lens").style.opacity',
          ),
          '0',
        );
        await page.emulateMediaFeatures([
          MediaFeature.prefersReducedMotion('no-preference'),
        ]);
        await page.waitForFunction(
          'Number(document.querySelector("#probe-nav-lens").style.opacity) > 0',
        );
        await page.mouse.up();
        expect(await events(), 'nav:3');
      });

      test('RTL drag commits the logical destination', () async {
        await page.evaluate<void>('() => document.documentElement.dir="rtl"');
        await settle();
        await drag(0, 3);
        expect(await selected(), 3);
        expect(await events(), 'nav:3');
      });

      test(
        'touch swipes skip disabled tabs, respect RTL, cancel vertical scroll',
        () async {
          Future<void> swipe(
            double dx,
            double dy, {
            bool cancel = false,
          }) async {
            await page.evaluate<void>(
              '''(dx,dy,cancel) => {
          const el=document.querySelector('#probe-tabs');
          const t=(x,y)=>new Touch({identifier:7,target:el,clientX:x,clientY:y});
          el.dispatchEvent(new TouchEvent('touchstart',{touches:[t(200.5,200.5)],bubbles:true}));
          el.dispatchEvent(new TouchEvent(cancel?'touchcancel':'touchend',{
            touches:[],changedTouches:[t(200.5+dx,200.5+dy)],bubbles:true}));
        }''',
              args: [dx, dy, cancel],
            );
            await settle();
          }

          await swipe(-100, 0);
          expect(await events(), 'tab:2');
          await configure('clear', '');
          await page.evaluate<void>('() => document.documentElement.dir="rtl"');
          await swipe(-100, 0);
          expect(await events(), 'tab:0');
          await configure('clear', '');
          await swipe(80, 120);
          await swipe(100, 0, cancel: true);
          expect(await events(), isEmpty);
        },
      );

      test(
        'slider previews without host echo and clears after cancel or disable',
        () async {
          final point = await page.evaluate<List<dynamic>>('''() => {
        const r=document.querySelector('#probe-slider').getBoundingClientRect();
        return [r.x+r.width*.8,r.y+r.height/2];
      }''');
          await page.mouse.move(
            Point((point[0] as num).toDouble(), (point[1] as num).toDouble()),
          );
          await page.mouse.down();
          await settle();
          expect(await events(), startsWith('start:20,slider:'));
          // root › interior › [track, thumb host] — the thumb host is the
          // interior's last child (the track's own last child is the fill).
          final thumbX = await page.evaluate<num>(
            '() => document.querySelector("#probe-slider").lastElementChild.lastElementChild.getBoundingClientRect().x',
          );
          expect(thumbX, greaterThan(350));
          await configure('enabled', 'false');
          await page.mouse.up();
          expect(await events(), isNot(contains('end:')));
        },
      );

      test(
        'toggle lens follows the composited thumb through rapid reversal',
        () async {
          Future<num> distance() => page.evaluate<num>('''() => {
        const thumb=document.querySelector('#probe-toggle [id^="co-toggle-thumb-"]');
        const lens=document.querySelector('#probe-toggle [id*="-lens-"]');
        if (!thumb || !lens) throw Error('missing thumb or lens');
        const a=thumb.getBoundingClientRect(), b=lens.getBoundingClientRect();
        return Math.abs(a.left+a.width/2-b.left-b.width/2);
      }''');
          final track = await page.evaluate<List<dynamic>>('''() => {
            const r=document.querySelector('#probe-toggle .co-toggle-track').getBoundingClientRect();
            return [r.width,r.height];
          }''');
          expect(track, [36, 20]);
          await page.click('#probe-toggle');
          await settle();
          expect(await distance(), lessThan(1));
          await page.click('#probe-toggle');
          await settle();
          expect(await distance(), lessThan(1));
          await page.click('#probe-toggle');
          await settle();
          expect(await distance(), lessThan(1));
          await page.waitForFunction(
            'document.querySelector(\'#probe-toggle [id*="-lens-"]\') === null',
          );
        },
      );

      test(
        'popover morph respects local material and live reduced motion',
        () async {
          await configure('local', 'defaultStyle');
          await page.click('#probe-popover > [id^=co-popover-trigger]');
          await settle();
          expect(
            await page.evaluate<int>(
              '''() => [...document.querySelectorAll('[id^="co-popover-panel-"]')]
                .filter(e => getComputedStyle(e).clipPath !== 'none').length''',
            ),
            0,
          );
          expect(
            await page.evaluate<String>(
              '() => document.querySelector(\'#probe-popover > [aria-expanded]\').getAttribute(\'aria-expanded\')',
            ),
            'true',
          );
          await page.keyboard.press(Key.escape);
          await configure('material', 'defaultStyle');
          await configure('local', 'liquidGlass');
          await page.waitForFunction(
            '!document.querySelector("[id^=co-popover-panel-]")',
          );
          await page.click('#probe-popover > [id^=co-popover-trigger]');
          await page.waitForFunction(
            '''[...document.querySelectorAll('[id^="co-popover-panel-"]')]
                .some(e => getComputedStyle(e).clipPath !== 'none')''',
          );
          expect(
            await page.evaluate<int>(
              '''() => [...document.querySelectorAll('[id^="co-popover-panel-"]')]
                .filter(e => getComputedStyle(e).clipPath !== 'none').length''',
            ),
            1,
          );
          await page.emulateMediaFeatures([
            MediaFeature.prefersReducedMotion('reduce'),
          ]);
          await settle();
          expect(
            await page.evaluate<int>(
              '''() => [...document.querySelectorAll('[id^="co-popover-panel-"]')]
                .filter(e => getComputedStyle(e).clipPath !== 'none').length''',
            ),
            0,
          );
        },
      );

      test('hidden labels retain equal full-width tooltip hit areas', () async {
        await configure('labels', 'false');
        final widths = await page.evaluate<List<dynamic>>('''() =>
          [...document.querySelectorAll('#probe-nav [data-coui-nav-index]')]
            .map(e => e.getBoundingClientRect().width)''');
        for (final width in widths) {
          expect(width, closeTo(118, 1));
        }
        await drag(0, 3);
        expect(await events(), 'nav:3');
      });

      test(
        'overflowing destinations keep their individual selection chrome',
        () async {
          await configure('width', '160');
          expect(
            await page.evaluate<bool>(
              '''() =>
          document.querySelector('#probe-nav').classList.contains('coui-navigation-glass-active')''',
            ),
            isFalse,
          );
          expect(await selected(), 0);
        },
      );

      test('external selection and unmount cancel a held gesture', () async {
        await drag(0, 3, release: false);
        await configure('selected', '2');
        await page.mouse.up();
        expect(await selected(), 2);
        expect(await events(), isEmpty);
        await drag(2, 3, release: false);
        await configure('visible', 'false');
        await page.mouse.up();
        await settle();
        expect(await events(), isEmpty);
        expect(
          await page.evaluate<bool>(
            '''() =>
          document.getElementById('coui-refraction-probe-nav-lens') === null''',
          ),
          isTrue,
        );
      });

      test('keyboard selection commits once with the same material', () async {
        await page.focus('#probe-nav [data-coui-nav-index="2"]');
        await page.keyboard.press(Key.enter);
        await settle();
        expect(await events(), 'nav:2');
        expect(await selected(), 2);
      });

      test('lens geometry follows a live root font-size change', () async {
        await page.evaluate<void>(
          '() => document.documentElement.style.fontSize="20px"',
        );
        await settle();
        final delta = await page.evaluate<List<dynamic>>('''() => {
          const a=document.querySelector('#probe-nav [data-coui-nav-index="0"]').getBoundingClientRect();
          const b=document.querySelector('#probe-nav-selection').getBoundingClientRect();
          return [Math.abs(a.width-b.width),Math.abs(a.height-b.height),Math.abs(a.x-b.x)];
        }''');
        for (final value in delta) {
          expect(value, lessThan(1));
        }
      });

      test(
        'lens retains the colored backdrop instead of an opaque white pane',
        () async {
          await page.evaluate<void>(
            '() => document.body.style.background="rgb(220,100,80)"',
          );
          await settle();
          await drag(0, 3, release: false);
          await page.waitForFunction('''(() => {
            const a=document.querySelector('#probe-nav-lens').getBoundingClientRect();
            const b=document.querySelector('#probe-nav [data-coui-nav-index="3"]').getBoundingClientRect();
            return Math.abs(a.x+a.width/2-b.x-b.width/2)<.5;
          })()''');
          final state = await page.evaluate<Map<String, dynamic>>('''() => {
          const root=document.querySelector('#probe-nav');
          const pane=document.querySelector('#probe-nav-pane');
          const lens=document.querySelector('#probe-nav-lens');
          const b=lens.getBoundingClientRect();
          return {rootFilter:getComputedStyle(root).backdropFilter,
            paneFilter:getComputedStyle(pane).backdropFilter,
            paneWidth:pane.getBoundingClientRect().width, rootWidth:root.getBoundingClientRect().width,
            x:Math.round(b.x+b.width/2), y:Math.round(b.y+b.height/2-14)};
        }''');
          expect(state['rootFilter'], 'none');
          expect(
            state['paneFilter'],
            allOf(contains('blur('), contains('url(')),
          );
          expect(state['paneWidth'], closeTo(state['rootWidth'] as num, 1));
          final pixels = img.decodePng(await page.screenshot())!;
          final color = pixels.getPixel(state['x'] as int, state['y'] as int);
          expect(color.r, greaterThan(color.b + 20));
          expect(color.b, lessThan(230));
          await page.mouse.up();
        },
      );

      test(
        'surface refraction survives an inline-style rewrite and keeps the new blur',
        () async {
          await page.evaluate<void>('''() => {
          const p=document.querySelector('#probe-nav-pane');
          p.setAttribute('style','position:absolute;inset:0;backdrop-filter:blur(7px)');
        }''');
          await settle();
          await page.waitForFunction(
            '''getComputedStyle(document.querySelector('#probe-nav-pane'))
          .backdropFilter.includes('url(')''',
          );
          expect(
            await page.evaluate<String>(
              '''() => getComputedStyle(document.querySelector('#probe-nav-pane'))
          .backdropFilter''',
            ),
            contains('blur(7px)'),
          );
        },
      );

      test('hidden glass surfaces stay idle and bind when shown', () async {
        final rebuilds = await page.evaluate<int>(
          '''() => new Promise(resolve => {
          let added=0;
          const observer=new MutationObserver(records => {
            for (const record of records) for (const node of record.addedNodes) {
              if (node.nodeName.toLowerCase()==='svg') added++;
            }
          });
          observer.observe(document.body,{childList:true,subtree:true});
          const el=document.createElement('div');
          el.id='probe-hidden-surface';
          el.className='coui-surface coui-surface-functional';
          el.style.cssText='display:none;width:100px;height:50px;--coui-surface-rgb:var(--coui-surface)';
          document.body.append(el);
          let frames=0;
          function tick(){ if(++frames<12)requestAnimationFrame(tick);
            else{observer.disconnect();resolve(added);} }
          requestAnimationFrame(tick);
        })''',
        );
        expect(rebuilds, lessThanOrEqualTo(2));
        await page.evaluate<void>(
          '() => document.querySelector("#probe-hidden-surface").style.backdropFilter="blur(7px)"',
        );
        await settle();
        await page.evaluate<void>(
          '() => document.querySelector("#probe-hidden-surface").style.display="block"',
        );
        await page.waitForFunction(
          'getComputedStyle(document.querySelector("#probe-hidden-surface")).backdropFilter.includes("url(")',
        );
        expect(
          await page.evaluate<String>(
            '() => getComputedStyle(document.querySelector("#probe-hidden-surface")).backdropFilter',
          ),
          contains('blur(7px)'),
        );
      });

      test('transparent app bar has no full-width material blur', () async {
        expect(
          await page.evaluate<String>(
            '() => getComputedStyle(document.querySelector("#probe-appbar")).backdropFilter',
          ),
          'none',
        );
      });
    },
    skip: chrome == null ? 'Chrome is unavailable' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
