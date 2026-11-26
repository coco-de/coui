// Actual release CanvasKit pixels, not a CSS support query or a shader-free
// widget harness. Runs the shipped Flutter adapter and the DOM Web runtime.
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/panel_pixels.dart';

const _kRoot = '''() => document.querySelector('flt-glass-pane').shadowRoot''';
const _kPlanes = '''[...document.querySelector('flt-glass-pane').shadowRoot
  .querySelectorAll('[data-coui-flutter-refraction]')]''';
const _kPanel = Rectangle(120, 80, 240, 100);

void main() {
  late Directory fixture;
  late Directory proof;
  late HttpServer server;
  late Browser browser;
  late Page page;
  late String origin;
  final metrics = <String, Object>{};
  var serverStarted = false;
  var browserStarted = false;
  var pageOpen = false;

  Future<void> settle() => page.evaluate<void>(
    '() => new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))',
  );
  Future<void> configure(String key, Object value) async {
    await page.evaluate<void>(
      '(k,v)=>couiFlutterGlassConfigure(k,v)',
      args: [key, '$value'],
    );
    await settle();
  }

  Future<Map<String, dynamic>> state() => page.evaluate<Map<String, dynamic>>(
    '() => JSON.parse(couiFlutterGlassState())',
  );
  Future<img.Image> capture(String name, [Rectangle<num>? clip]) async {
    await settle();
    final bytes = await page.screenshot(clip: clip);
    File(p.join(proof.path, '$name.png')).writeAsBytesSync(bytes);
    return img.decodePng(bytes)!;
  }

  Future<void> drag(int from, int to, {bool rtl = false}) async {
    final nav = (await state())['nav'] as List<dynamic>;
    // The resolved pane has an 8px inset, four equal cells and no spacing.
    final cell = ((nav[2] as num) - 16) / 4;
    double x(int index) =>
        (nav[0] as num) + 8 + cell * ((rtl ? 3 - index : index) + .5);
    final y = (nav[1] as num).toDouble() + (nav[3] as num) / 2;
    await page.mouse.move(Point(x(from), y));
    await page.mouse.down();
    await page.mouse.move(Point(x(to), y), steps: 16);
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  setUpAll(() async {
    fixture = Directory.systemTemp.createTempSync('flutter-glass-release-');
    proof = Directory(
      Platform.environment['COUI_GLASS_ARTIFACTS'] ??
          '.dart_tool/flutter-web-glass-proof',
    )..createSync(recursive: true);
    final candidates = [
      if (Platform.environment['CHROME_EXECUTABLE'] case final String chrome)
        chrome,
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/usr/bin/google-chrome',
      '/usr/bin/google-chrome-stable',
      '/usr/bin/chromium-browser',
      '/usr/bin/chromium',
    ];
    final chrome = candidates.firstWhere(
      (candidate) => File(candidate).existsSync(),
      orElse: () => '',
    );
    expect(chrome, isNotEmpty, reason: 'Chrome is required.');
    final output = p.join(fixture.path, 'web');
    final builds = await Future.wait([
      Process.run('flutter', [
        'build',
        'web',
        '--release',
        '--no-pub',
        '--no-wasm-dry-run',
        '--no-web-resources-cdn',
        '--target',
        'test/fixtures/web_glass_probe.dart',
        '--output',
        output,
      ], workingDirectory: 'app/coui_widgetbook'),
      Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        'tool/parity/src/web/refraction_runtime_entry.dart',
        '-o',
        p.join(fixture.path, 'dom_probe.js'),
      ]),
    ]);
    for (final build in builds) {
      expect(build.exitCode, 0, reason: '${build.stdout}\n${build.stderr}');
    }
    // flutter build owns its output folder. Keep the independently compiled
    // DOM fixture outside it, then copy it in after the build has completed.
    File(p.join(fixture.path, 'dom_probe.js')).copySync(
      p.join(output, 'dom_probe.js'),
    );
    File(p.join(output, 'dom.html')).writeAsStringSync('''<!doctype html>
<style>
body{margin:0;width:640px;height:480px;background:
repeating-linear-gradient(180deg,#d93048 0 3px,transparent 3px 20px),
repeating-linear-gradient(90deg,#2369da 0 10px,#fff 10px 20px)}
#panel{position:absolute;left:120px;top:80px;width:240px;height:100px;
border-radius:20px;backdrop-filter:blur(1.5px) saturate(1.2) brightness(.9)}
</style><div id="panel"></div><script src="dom_probe.js"></script>''');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serverStarted = true;
    server.listen((request) async {
      final relative = request.uri.path == '/'
          ? 'index.html'
          : request.uri.path.substring(1);
      final file = File(p.normalize(p.join(output, relative)));
      if (!p.isWithin(output, file.path) || !file.existsSync()) {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        request.response.headers.contentType = switch (p.extension(file.path)) {
          '.html' => ContentType.html,
          '.js' => ContentType('application', 'javascript'),
          '.json' => ContentType.json,
          '.wasm' => ContentType('application', 'wasm'),
          '.css' => ContentType('text', 'css'),
          _ => ContentType.binary,
        };
        await request.response.addStream(file.openRead());
      }
      await request.response.close();
    });
    origin = 'http://127.0.0.1:${server.port}';
    browser = await launchCaptureBrowser(
      width: 640,
      height: 480,
      executablePath: chrome,
    );
    browserStarted = true;
  });
  setUp(() async {
    page = await browser.newPage();
    pageOpen = true;
    await page.goto(origin, wait: Until.networkIdle);
    await page.waitForFunction(
      '''typeof couiFlutterGlassState === 'function'
      && document.querySelector('[data-coui-flutter-refraction-anchor]') !== null''',
    );
    await page.waitForFunction('''$_kPlanes.length === 2 &&
      $_kPlanes.every(e=>getComputedStyle(e).visibility==='visible')''');
    await settle();
  });
  tearDown(() async {
    if (pageOpen) await page.close();
    pageOpen = false;
  });
  tearDownAll(() async {
    File(p.join(proof.path, 'metrics.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(metrics),
    );
    if (browserStarted) await browser.close();
    if (serverStarted) await server.close(force: true);
    fixture.deleteSync(recursive: true);
  });

  test(
    'real displacement, an unchanged interior, and a repeatable control',
    () async {
      await configure('bezel', .05);
      final narrow = await capture('flutter-narrow', _kPanel);
      final twin = await capture('flutter-narrow-twin', _kPanel);
      expect(diffRatio(narrow, twin), lessThan(kUnchangedRatioCeiling));
      await configure('bezel', .45);
      final wide = await capture('flutter-wide', _kPanel);
      final moved = diffRatio(narrow, wide);
      metrics['flutterDifferentBezelMovedRatio'] = moved;
      expect(moved, greaterThan(kMovedRatioFloor));
      expect(luminanceBuckets(wide), greaterThanOrEqualTo(kBlurBucketFloor));
      expect(
        diffRatio(
          img.copyCrop(narrow, x: 105, y: 45, width: 30, height: 10),
          img.copyCrop(wide, x: 105, y: 45, width: 30, height: 10),
        ),
        lessThan(kUnchangedRatioCeiling),
      );
    },
  );

  test(
    'Flutter Web and shipped DOM Web draw the same optical recipe',
    () async {
      final flutter = await capture('flutter-parity', _kPanel);
      await page.goto('$origin/dom.html', wait: Until.networkIdle);
      await page.waitForFunction('typeof couiAttachRefraction === "function"');
      await page.evaluate<void>('() => couiAttachRefraction("panel", .32)');
      final dom = await capture('dom-parity', _kPanel);
      final difference = diffRatio(flutter, dom);
      metrics['flutterDomSameRecipePixelDifference'] = difference;
      expect(difference, lessThan(kUnchangedRatioCeiling));
    },
  );

  test(
    'held lens bends icons, reuses maps, commits once and becomes idle',
    () async {
      await drag(0, 3);
      expect((await state())['events'], isEmpty);
      final lens = await page.evaluate<Map<String, dynamic>>('''() => {
      const e=$_kPlanes.at(-1),r=e.getBoundingClientRect();
      return {filter:e.style.backdropFilter,x:r.x,y:r.y,w:r.width,h:r.height,
      maps:[...e.parentNode.querySelectorAll('feImage')].map(n=>n.getAttribute('href'))};
    }''');
      expect(lens['filter'], contains('url('));
      final clip = Rectangle<num>(
        (lens['x'] as num).ceil(),
        (lens['y'] as num).ceil(),
        (lens['w'] as num).floor() - 1,
        (lens['h'] as num).floor() - 1,
      );
      final optical = await capture('flutter-lens-on', clip);
      // Keep this optical control independent of Flutter's live scene writes.
      // An inline edit can be legitimately replaced by the next retained-layer
      // update, leaving two identical captures and no actual control.
      await page.evaluate<void>('''() => {
        const root=($_kRoot)(),e=$_kPlanes.at(-1);
        const style=document.createElement('style');style.id='probe-optics-off';
        style.textContent='[data-coui-flutter-refraction="'+
          e.dataset.couiFlutterRefraction+'"]{backdrop-filter:none!important}';
        root.append(style);
      }''');
      final control = await capture('flutter-lens-off', clip);
      final moved = diffRatio(optical, control);
      metrics['heldLensDisplacementMovedRatio'] = moved;
      expect(moved, greaterThan(kMovedRatioFloor));
      expect(luminanceBuckets(optical), greaterThanOrEqualTo(kBlurBucketFloor));
      await page.evaluate<void>(
        '() => ($_kRoot)().getElementById("probe-optics-off").remove()',
      );
      await page.mouse.move(const Point(440, 301), steps: 8);
      await settle();
      expect(
        await page.evaluate<List<dynamic>>('''() =>
      [...$_kPlanes.at(-1).parentNode.querySelectorAll('feImage')]
      .map(n=>n.getAttribute('href'))'''),
        lens['maps'],
      );
      await page.mouse.up();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect((await state())['events'], [3]);
      expect((await state())['selected'], 3);
      expect(await page.evaluate<int>('() => $_kPlanes.length'), 2);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final writes = await page.evaluate<int>('''() => new Promise(resolve=>{
      let count=0,frames=0;const observer=new MutationObserver(r=>count+=r.length);
      observer.observe(($_kRoot)(),{subtree:true,attributes:true,childList:true});
      function tick(){if(++frames<12)requestAnimationFrame(tick);
        else{observer.disconnect();resolve(count);}}requestAnimationFrame(tick);
    })''');
      expect(writes, 0);
    },
  );

  test(
    'external clips intersect, and translated ancestors retain alignment',
    () async {
      await configure('clip', 50);
      final on = await capture('flutter-clipped');
      await page.evaluate<void>(
        '() => $_kPlanes[0].style.backdropFilter="none"',
      );
      final off = await capture('flutter-clipped-control');
      expect(
        diffRatio(
          img.copyCrop(on, x: 120, y: 135, width: 240, height: 45),
          img.copyCrop(off, x: 120, y: 135, width: 240, height: 45),
        ),
        lessThan(kUnchangedRatioCeiling),
      );
      await configure('offset', -45);
      final top = await page.evaluate<num>(
        '() => $_kPlanes[1].getBoundingClientRect().top',
      );
      expect(top, closeTo(223, .1));
      await configure('scale', .75);
      final scaled = await page.evaluate<List<dynamic>>('''() => {
        const anchors=[...document.querySelectorAll('[data-coui-flutter-refraction-anchor]')];
        const planes=$_kPlanes;
        return anchors.map(a=>{const p=planes.find(e=>
          e.dataset.couiFlutterRefraction===a.dataset.couiFlutterRefractionAnchor);
          const ar=a.getBoundingClientRect(),pr=p.getBoundingClientRect();
          return [ar.x-pr.x,ar.y-pr.y,ar.width-pr.width,ar.height-pr.height];});
      }''');
      for (final differences in scaled) {
        for (final delta in differences as List<dynamic>) {
          expect(delta, closeTo(0, .05));
        }
      }
    },
  );

  test('controlled refusal and RTL gestures keep the host selection', () async {
    await configure('accept', false);
    await drag(0, 3);
    await page.mouse.up();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect((await state())['selected'], 0);
    expect((await state())['events'], [3]);
    await configure('clear', '');
    await configure('accept', true);
    await configure('rtl', true);
    await drag(0, 2, rtl: true);
    await page.mouse.up();
    await settle();
    expect((await state())['events'], [2]);
    expect((await state())['selected'], 2);
  });

  test(
    'reduced motion, material changes and unmount release every plane',
    () async {
      await configure('reduced', true);
      await drag(0, 3);
      expect(await page.evaluate<int>('() => $_kPlanes.length'), 2);
      await page.mouse.up();
      await configure('material', 'defaultStyle');
      expect(await page.evaluate<int>('() => $_kPlanes.length'), 1);
      await configure('material', 'liquidGlass');
      await configure('transparent', true);
      await page.waitForFunction('$_kPlanes.length === 1');
      expect(await page.evaluate<int>('() => $_kPlanes.length'), 1);
      await configure('visible', false);
      expect(await page.evaluate<int>('() => $_kPlanes.length'), 0);
      expect(
        await page.evaluate<int>(
          '''() =>
      ($_kRoot)().querySelectorAll('[id^="coui-refraction-coui-flutter"]').length''',
        ),
        0,
      );
    },
  );
}
