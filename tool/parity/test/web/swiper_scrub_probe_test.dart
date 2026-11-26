@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:puppeteer/protocol/input.dart' show TouchPoint;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

void main() {
  late Directory directory;
  late pptr.Browser browser;
  late pptr.Page page;

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('swiper-scrub-');
    final result = await Process.run('dart', [
      'compile',
      'js',
      '-O2',
      'tool/parity/src/web/swiper_scrub_entry.dart',
      '-o',
      '${directory.path}/client.js',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    browser = await launchCaptureBrowser(width: 800, height: 700);
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });
  tearDown(() => page.close());

  Future<void> frame() => page.evaluate<void>(
    '() => new Promise(r => requestAnimationFrame(r))',
  );
  Future<void> load({
    String side = 'left',
    String variant = 'drawer',
    String theme = 'light',
    bool controller = false,
  }) async {
    final file = File('${directory.path}/$theme.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: '<script src="client.js"></script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          theme: theme,
          animationFreezeCss: '',
        ),
      );
    page = await browser.newPage();
    await page.goto(
      file.uri
          .replace(
            fragment: jsonEncode({
              'side': side,
              'variant': variant,
              'controller': controller,
            }),
          )
          .toString(),
    );
    await page.waitForSelector('#child-button');
    await frame();
  }

  Future<void> command(String value) => page.evaluate<void>('''
() => document.querySelector('[data-command="$value"]').click()
''');
  Future<int> count(String name) => page.evaluate<int>(
    '() => Number(document.getElementById("stats").dataset.$name)',
  );
  Future<void> gone() => page.waitForFunction(
    '() => !document.querySelector("[role=dialog]") && '
    '!document.querySelector("[inert]")',
  );
  Future<void> start(Point<double> p) async {
    await page.mouse.move(p);
    await page.mouse.down();
  }

  Future<void> move(Point<double> p) async {
    await frame();
    await page.mouse.move(p);
    await frame();
  }

  Future<void> mounted() async {
    await page.waitForSelector('[role="dialog"]');
    await frame();
    expect(
      await page.evaluate<bool>('''
() => !!(document.querySelector('[data-swiper-enabled]') ?? document.getElementById('controller-stats')).closest('[inert]')
'''),
      isTrue,
    );
  }

  Future<void> docked(String side) => page.waitForFunction('''
() => {
const e=document.querySelector('[role=dialog]'); if(!e) return false;
const r=e.getBoundingClientRect();
return ${switch (side) {
    'left' => 'Math.abs(r.left)<0.5',
    'right' => 'Math.abs(r.right-800)<0.5',
    'top' => 'Math.abs(r.top)<0.5',
    _ => 'Math.abs(r.bottom-700)<0.5',
  }};
}
''');
  Future<void> longLeft() async {
    await start(const Point<double>(520, 250));
    await move(const Point<double>(544, 250));
    await mounted();
    await move(const Point<double>(760, 250));
  }

  for (final variant in ['drawer', 'sheet']) {
    for (final side in ['left', 'right', 'top', 'bottom']) {
      test(
        '$variant/$side: a trusted mouse scrubs through inert and opens once',
        () async {
          await load(
            side: side,
            variant: variant,
            theme: variant == 'sheet' ? 'dark' : 'light',
          );
          final (origin, slop, end) = switch (side) {
            'left' => (
              const Point<double>(520, 250),
              const Point<double>(544, 250),
              const Point<double>(760, 250),
            ),
            'right' => (
              const Point<double>(280, 250),
              const Point<double>(256, 250),
              const Point<double>(40, 250),
            ),
            'top' => (
              const Point<double>(400, 140),
              const Point<double>(400, 164),
              const Point<double>(400, 500),
            ),
            _ => (
              const Point<double>(400, 480),
              const Point<double>(400, 456),
              const Point<double>(400, 120),
            ),
          };
          await start(origin);
          await move(slop);
          await mounted();
          await move(end);
          final progress = await page.evaluate<num>('''
() => {const r=document.querySelector('[role=dialog]').getBoundingClientRect();return ${switch (side) {
            'left' => 'r.right/r.width',
            'right' => '(800-r.left)/r.width',
            'top' => 'r.bottom/r.height',
            _ => '(700-r.top)/r.height',
          }};}
''');
          expect(
            progress,
            greaterThan(0.5),
            reason: 'the panel must follow before release',
          );
          await page.mouse.up();
          await docked(side);
          expect(await count('opens'), 1);
          await page.keyboard.press(pptr.Key.escape);
          await gone();
          expect(await count('closes'), 1);
        },
      );
    }
  }

  test(
    'a short scrub aborts and an ordinary child click still works',
    () async {
      await load();
      await page.click('#child-button');
      expect(await count('clicks'), 1);
      await start(const Point<double>(520, 250));
      await move(const Point<double>(544, 250));
      await mounted();
      await move(const Point<double>(600, 250));
      await page.mouse.up();
      await gone();
      expect(await count('opens'), 0);
      expect(await count('closes'), 0);
      await longLeft();
      await page.mouse.up();
      await docked('left');
      expect(await count('opens'), 1);
    },
  );

  test('a foreign pointer cannot replace or release an active drag', () async {
    await load();
    await start(const Point<double>(520, 250));
    await move(const Point<double>(544, 250));
    await mounted();
    await page.evaluate<void>('''
() => {for(const type of ['pointerdown','pointermove','pointerup'])
document.dispatchEvent(new PointerEvent(type,{pointerId:99,pointerType:'touch',isPrimary:false,clientX:0,clientY:250,bubbles:true}));}
''');
    await move(const Point<double>(760, 250));
    await page.mouse.up();
    await docked('left');
    expect(await count('opens'), 1);
  });

  test(
    'disabling gestures keeps a committed Drawer and preserves zoom policy',
    () async {
      await load();
      expect(
        await page.evaluate<String>('''
() => getComputedStyle(document.querySelector('[data-swiper-enabled]')).touchAction
'''),
        contains('pinch-zoom'),
      );
      await longLeft();
      await page.mouse.up();
      await docked('left');
      await command('disable');
      await frame();
      await docked('left');
      expect(await count('opens'), 1);
      expect(await count('closes'), 0);
      expect(
        await page.evaluate<String>('''
() => getComputedStyle(document.querySelector('[data-swiper-position]')).touchAction
'''),
        'auto',
      );
      await page.keyboard.press(pptr.Key.escape);
      await gone();
      expect(await count('closes'), 1);
    },
  );

  for (final action in [
    'cancel',
    'blur',
    'hidden',
    'disable',
    'remove',
    'escape',
    'controlled-close',
    'rotate',
  ]) {
    test(
      '$action aborts beyond the threshold without a late-up reopen',
      () async {
        await load();
        await longLeft();
        switch (action) {
          case 'cancel':
            await page.evaluate<void>('''
() => document.dispatchEvent(new PointerEvent('pointercancel',{pointerId:1,pointerType:'mouse',isPrimary:true,bubbles:true}))
''');
          case 'blur':
            await page.evaluate<void>(
              "() => window.dispatchEvent(new Event('blur'))",
            );
          case 'hidden':
            await page.evaluate<void>('''
() => {Object.defineProperty(document,'visibilityState',{value:'hidden',configurable:true});
document.dispatchEvent(new Event('visibilitychange'));}
''');
          case 'disable':
            await command('disable');
          case 'remove':
            await command('remove');
          case 'rotate':
            await command('rotate');
          case 'escape':
            await page.keyboard.press(pptr.Key.escape);
          case 'controlled-close':
            await command('open');
            await frame();
            await command('close');
        }
        await frame();
        await move(const Point<double>(780, 250));
        await page.mouse.up();
        await gone();
        expect(await count('opens'), 0);
        expect(await count('closes'), 0);
        if (action == 'disable') await command('enable');
        if (action == 'remove') await command('restore');
        if (action == 'rotate') await command('left');
        if (action == 'hidden') {
          await page.evaluate<void>('''
() => {delete document.visibilityState;document.dispatchEvent(new Event('visibilitychange'));}
''');
        }
        await frame();
        await longLeft();
        await page.mouse.up();
        await docked('left');
        expect(
          await count('opens'),
          1,
          reason: 'aborting must detach so the next gesture works',
        );
      },
    );
  }

  test('a real touch opens through inert and touchCancel aborts', () async {
    await load();
    await page.setViewport(
      const pptr.DeviceViewport(
        width: 800,
        height: 700,
        hasTouch: true,
        isMobile: true,
      ),
    );
    Future<void> touch(String type, double? x) =>
        page.devTools.input.dispatchTouchEvent(
          type,
          x == null ? [] : [TouchPoint(x: x, y: 250, id: 7)],
        );
    await touch('touchStart', 520);
    await frame();
    await touch('touchMove', 544);
    await mounted();
    await touch('touchMove', 760);
    await frame();
    await touch('touchCancel', null);
    await gone();
    expect(await count('opens'), 0);
    await touch('touchStart', 520);
    await frame();
    await touch('touchMove', 544);
    await mounted();
    await touch('touchMove', 760);
    await frame();
    await touch('touchEnd', null);
    await docked('left');
    expect(await count('opens'), 1);
  });

  test(
    'release before entry mount replays panel and backdrop settlement',
    () async {
      await load();
      await page.evaluate<void>('''
() => {
const root=document.querySelector('[data-swiper-enabled]');
const event=(type,x)=>new PointerEvent(type,{pointerId:81,pointerType:'mouse',isPrimary:true,button:0,buttons:type==='pointerup'?0:1,clientX:x,clientY:250,bubbles:true});
root.firstElementChild.dispatchEvent(event('pointerdown',520));
document.dispatchEvent(event('pointermove',544));
document.dispatchEvent(event('pointermove',760));
document.dispatchEvent(event('pointerup',760));
}
''');
      await docked('left');
      expect(await count('opens'), 1);
      await page.waitForFunction('''
() => {const s=getComputedStyle(document.querySelector('[data-coui-backdrop]'));
return new DOMMatrix(s.transform).a<0.99 && parseFloat(s.borderTopLeftRadius)>0;}
''');
    },
  );

  test(
    'Escape before the initial frame cannot reopen a settled entry',
    () async {
      await load();
      await page.evaluate<void>('''
() => {
window.__swiperFrames=[];window.__swiperRaf=requestAnimationFrame;
window.requestAnimationFrame=callback=>{window.__swiperFrames.push(callback);return 0;};
const root=document.querySelector('[data-swiper-enabled]');
const event=(type,x)=>new PointerEvent(type,{pointerId:82,pointerType:'mouse',isPrimary:true,button:0,buttons:type==='pointerup'?0:1,clientX:x,clientY:250,bubbles:true});
root.firstElementChild.dispatchEvent(event('pointerdown',520));
document.dispatchEvent(event('pointermove',544));
document.dispatchEvent(event('pointermove',760));
document.dispatchEvent(event('pointerup',760));
}
''');
      await page.waitForSelector('[role=dialog]');
      await page.keyboard.press(pptr.Key.escape);
      await page.evaluate<void>('''
() => {window.requestAnimationFrame=window.__swiperRaf;
const callbacks=window.__swiperFrames;window.__swiperFrames=[];
callbacks.forEach(callback=>callback(performance.now()));}
''');
      await frame();
      expect(
        await page.evaluate<bool>('''
() => {const e=document.querySelector('[role=dialog]');
return !e || e.style.transform.includes('-100%');}
'''),
        isTrue,
      );
      await gone();
      expect(await count('opens'), 1);
      expect(await count('closes'), 1);
    },
  );

  Future<void> atProgress(double fraction) => page.waitForFunction('''
() => {const e=document.querySelector('[role=dialog]');if(!e)return false;
const r=e.getBoundingClientRect();return Math.abs(r.right/r.width-$fraction)<0.01;}
''');

  test('public update can re-scrub a settled mounted Drawer', () async {
    await load(controller: true);
    await command('open-controller');
    await mounted();
    await command('settle-open');
    await docked('left');
    await command('quarter');
    await atProgress(.25);
    await command('three-quarters');
    await atProgress(.75);
    await command('settle-close');
    await gone();
  });

  test('a later public settle-close still closes after settle-open', () async {
    await load(controller: true);
    await command('open-controller');
    await mounted();
    await command('settle-open');
    await docked('left');
    await command('settle-close');
    await gone();
    expect(
      await page.evaluate<String>(
        '() => document.getElementById("controller-stats").dataset.completed',
      ),
      '1',
    );
  });

  test(
    'one public controller can drive three successive Drawer mounts',
    () async {
      await load(controller: true);
      for (var i = 1; i <= 3; i++) {
        await command('open-controller');
        await mounted();
        await command('quarter');
        await atProgress(.25);
        await command('settle-open');
        await docked('left');
        await command('settle-close');
        await gone();
        expect(
          await page.evaluate<String>(
            '() => document.getElementById("controller-stats") '
            '.dataset.completed',
          ),
          '$i',
        );
      }
    },
  );
}
