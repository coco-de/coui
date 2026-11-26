/// Real Iconify 2.1.0 transport, shadow SVG and encoded SVG regression.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:puppeteer/puppeteer.dart';

import '../../../../packages/coui_web/test/browser/fixtures/icon_stroke_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/local_icons.dart';

const _kChrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const _kFixture =
    'packages/coui_web/test/browser/fixtures/icon_stroke_probe.client.dart';

// Synthetic controls deliberately share Lucide's authored width. A global
// stroke rewrite would break these non-Lucide/filled/multicolor bodies.
const _kControls = '''
const api = customElements.get('iconify-icon');
api.disableCache('all');
api.addCollection({prefix:'test-control',width:24,height:24,icons:{
  outline:{body:'<path fill="none" stroke="currentColor" stroke-width="2" d="M3 3h18v18H3z"/>'},
  filled:{body:'<path fill="currentColor" d="M3 3h18v18H3z"/>'},
  multi:{body:'<path fill="#f00" d="M0 0h12v24H0z"/><path fill="#00f" d="M12 0h12v24H12z"/>'}
}});
api.addIcon('lucide:custom-grid',{width:48,height:48,rotate:1,hFlip:true,
  body:"<g fill='none' stroke='currentColor' stroke-width='2' data-stroke-width='2'><path d='M3 3h40v40H3z'/><path stroke-width='3' d='M4 4h8'/></g>"});
''';

// Read the actual SVG used by the browser. mask/bg modes encode it in --svg;
// lay that exact SVG out at the real image box size to measure its glyph CTM.
const _kRead = '''
() => JSON.stringify([...document.querySelectorAll('svg[id],iconify-icon[id]')].map(host => {
  let svg = host.localName === 'svg' ? host : host.shadowRoot?.querySelector('svg');
  let decoded = null, holder = null;
  if (!svg) {
    const span = host.shadowRoot?.querySelector('span');
    const url = span?.style.getPropertyValue('--svg');
    const prefix = 'data:image/svg+xml,';
    const start = url?.indexOf(prefix) ?? -1;
    if (start < 0) return {id:host.id,pending:true};
    decoded = decodeURIComponent(url.slice(start + prefix.length, -2));
    holder = document.createElement('div');
    holder.style.cssText = 'position:absolute;visibility:hidden;';
    holder.innerHTML = decoded;
    document.body.append(holder);
    svg = holder.querySelector('svg');
    const box = span.getBoundingClientRect();
    svg.setAttribute('width',box.width);
    svg.setAttribute('height',box.height);
  }
  const path = svg.querySelector('path') ?? svg.querySelector('rect,circle');
  const cs = getComputedStyle(path), matrix = path.getScreenCTM();
  const row = {id:host.id,box:host.getBoundingClientRect().width,
    stroke:cs.strokeWidth,paint:cs.stroke,fill:cs.fill,color:cs.color,
    actual:parseFloat(cs.strokeWidth)*Math.hypot(matrix.a,matrix.b),
    viewBox:svg.getAttribute('viewBox'),svg:svg.outerHTML,decoded,
    attrs:Object.fromEntries([...host.attributes].map(a=>[a.name,a.value])),
    fills:[...svg.querySelectorAll('[fill]')].map(e=>e.getAttribute('fill'))};
  holder?.remove();
  return row;
}))
''';

Future<Map<String, Map<String, Object?>>> _read(Page page) async {
  final value =
      jsonDecode(await page.evaluate<String>(_kRead)) as List<Object?>;
  return {
    for (final row in value.cast<Map<String, Object?>>())
      row['id']! as String: row,
  };
}

void _expectStroke(
  Map<String, Map<String, Object?>> rows,
  String id,
  double size, {
  double scale = 1,
}) {
  final row = rows[id]!;
  expect(row['pending'], isNull, reason: id);
  expect(row['box'], closeTo(size * scale, 0.001), reason: id);
  expect(
    row['actual'],
    closeTo(CoreIconStroke.renderedWidth(size) * scale, 0.0001),
    reason: '$id must measure the Core rule in the actual glyph',
  );
}

void main() {
  // The probe draws `lucide:a-arrow-down` through the Iconify adapter, which
  // is what this test measures. An icon the bundle gains is drawn as inline
  // SVG instead and leaves the adapter nothing to measure — say so here
  // rather than as a null `querySelector` deep inside the page.
  test('the probe icon is outside the bundle', () {
    expect(CoreBundledIcons.icons, isNot(contains('lucide:a-arrow-down')));
  });

  testServer(
    'unbundled Lucide normalizes copies in SVG/mask/bg, before/after '
    'construction and through release hydration',
    (tester) async {
      tester.pumpComponent(iconStrokeProbe());
      final response = await tester.request('/');
      final temp = Directory.systemTemp.createTempSync('coui-icon-stroke-');
      addTearDown(() => temp.deleteSync(recursive: true));
      final compilation = await Process.run('dart', [
        'compile',
        'js',
        '-O2',
        _kFixture,
        '-o',
        '${temp.path}/client.js',
      ]);
      expect(
        compilation.exitCode,
        0,
        reason: '${compilation.stdout}\n${compilation.stderr}',
      );
      final collection =
          jsonDecode(loadVendoredLucideCollectionJson())
              as Map<String, dynamic>;
      final iconify = loadVendoredIconifyScript();
      final normalizer = File(
        'packages/coui_web/lib/iconify_stroke.js',
      ).readAsStringSync();
      final browser = await launchCaptureBrowser(
        width: 1000,
        height: 400,
        executablePath: _kChrome,
      );
      addTearDown(browser.close);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final origin = 'http://127.0.0.1:${server.port}';
      Completer<void>? dataGate;
      var apiRequests = 0;
      server.listen((request) async {
        final path = request.uri.path;
        request.response.headers.set(
          'Content-Security-Policy',
          "default-src 'none'; script-src 'self'; "
              "style-src 'unsafe-inline'; connect-src 'self'; img-src data:",
        );
        request.response.headers.contentType = ContentType(
          'application',
          'javascript',
        );
        if (path == '/iconify.js') {
          request.response.write(iconify);
        } else if (path == '/normalizer.js') {
          request.response.write(normalizer);
        } else if (path == '/client.js') {
          request.response.write(
            File('${temp.path}/client.js').readAsStringSync(),
          );
        } else if (path == '/provider.js') {
          request.response.write(
            "window.IconifyProviders={'':{resources:['$origin'],path:'/api/'}};",
          );
        } else if (path == '/data.js') {
          request.response.write(_kControls);
          if (dataGate == null) {
            request.response.write(
              'api.addCollection(${jsonEncode(collection)});',
            );
          }
        } else if (path.startsWith('/api/')) {
          apiRequests++;
          if (dataGate != null) await dataGate.future;
          final names = request.uri.queryParameters['icons']!.split(',');
          final prefix = path.split('/').last.split('.').first;
          final icons = prefix == 'lucide'
              ? collection['icons'] as Map<String, dynamic>
              : <String, dynamic>{
                  'outline': {
                    'body':
                        '<path fill="none" stroke="currentColor" stroke-width="2" d="M3 3h18v18H3z"/>',
                  },
                  'filled': {
                    'body': '<path fill="currentColor" d="M3 3h18v18H3z"/>',
                  },
                  'multi': {
                    'body':
                        '<path fill="#f00" d="M0 0h12v24H0z"/><path fill="#00f" d="M12 0h12v24H12z"/>',
                  },
                };
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'prefix': prefix,
              'width': 24,
              'height': 24,
              'icons': {
                for (final name in names)
                  if (icons.containsKey(name)) name: icons[name],
              },
            }),
          );
        } else {
          request.response.headers.contentType = ContentType.html;
          final mode = request.uri.queryParameters['mode'];
          const scripts =
              '<script src="/iconify.js"></script><script src="/data.js"></script><script src="/normalizer.js"></script>';
          final html = response.body
              .replaceFirst(
                '</head>',
                '<script src="/provider.js"></script>${mode == 'early'
                    ? scripts
                    : mode == 'async'
                    ? '<script src="/normalizer.js"></script>'
                    : ''}</head>',
              )
              .replaceFirst(
                '</body>',
                '${mode == 'early' ? '' : scripts}</body>',
              );
          request.response.write(html);
        }
        await request.response.close();
      });

      final evidence = Platform.environment['COUI_ICON_STROKE_EVIDENCE'];
      if (evidence != null) Directory(evidence).createSync(recursive: true);
      for (final mode in ['early', 'late', 'async']) {
        dataGate = mode == 'async' ? Completer<void>() : null;
        final context = await browser.createIncognitoBrowserContext();
        final page = await context.newPage();
        try {
          await page.goto('$origin/?mode=$mode', wait: Until.domContentLoaded);
          if (dataGate != null) {
            expect(
              await page.evaluate<bool>(
                "() => !customElements.get('iconify-icon') "
                ".getIcon('lucide:a-arrow-down')",
              ),
              isTrue,
            );
            // A detached instance releases its pending Iconify subscription.
            // Repeated connection must not accumulate callbacks or observers.
            expect(
              await page.evaluate<int>(
                '''
                () => {
                  const api=customElements.get('iconify-icon');
                  const load=api.loadIcons;
                  let active=0;
                  api.loadIcons=(names,callback) => {
                    active++;
                    const abort=load(names,callback);
                    return () => { active--; abort(); };
                  };
                  const icon=document.querySelector('#dynamic').cloneNode(true);
                  icon.id='pending-detach';
                  for(let i=0;i<5;i++) {
                    document.body.append(icon);
                    icon.remove();
                  }
                  api.loadIcons=load;
                  return active;
                }
              '''
                    .trim(),
              ),
              0,
            );
            dataGate.complete();
          }
          try {
            await page.waitForFunction(
              '''
            () => [...document.querySelectorAll('iconify-icon')].every(e =>
              e.status === 'rendered' &&
              (e.querySelector('coui-iconify-stroke').getAttribute('prefix')
                !== 'lucide' || e.icon.body))'''
                  .trim(),
            );
          } on Object {
            stdout.writeln(
              await page.evaluate<String>(
                '''
            () => JSON.stringify(
                [...document.querySelectorAll('iconify-icon')].map(e => ({
                  id:e.id,status:e.status,icon:e.getAttribute('icon')
                })))'''
                    .trim(),
              ),
            );
            rethrow;
          }
          stdout.writeln('$mode: all Iconify glyphs ready');
          var rows = await _read(page);
          for (final size in [16.0, 20.0, 24.0, 28.0]) {
            for (final kind in ['bundled', 'svg', 'mask', 'bg']) {
              _expectStroke(rows, '$kind-${size.toInt()}', size);
            }
          }
          _expectStroke(rows, 'ambient', 28);
          _expectStroke(rows, 'override', 20);
          expect(rows['ambient']!['color'], 'rgb(18, 52, 86)');
          expect(rows['outline']!['actual'], 2);
          expect(rows['filled']!['paint'], 'none');
          expect(rows['multi']!['fills'], ['#f00', '#00f']);
          final custom = rows['customized']!['attrs']! as Map<String, dynamic>;
          expect(custom, containsPair('mode', 'mask'));
          expect(custom, containsPair('rotate', '90deg'));
          expect(custom, containsPair('flip', 'horizontal'));
          expect(custom, containsPair('aria-label', 'Picture'));
          expect(custom, containsPair('data-caller', 'retained'));
          expect(custom['class'], contains('caller-icon'));
          final grid = rows['custom-grid']!;
          _expectStroke(rows, 'custom-grid', 16);
          expect(grid['viewBox'], '0 0 48 48');
          expect(grid['svg'], contains('data-stroke-width="2"'));
          expect(grid['svg'], contains('stroke-width="3.75"'));
          expect(grid['svg'], contains('stroke-width="3"'));
          final gridData =
              jsonDecode((grid['attrs']! as Map)['icon']! as String) as Map;
          expect(gridData['rotate'], 1);
          expect(gridData['hFlip'], isTrue);
          expect(gridData['width'], 48);

          // Both glyph and stroke scale once through rem; no CSS border ramp.
          await page.evaluate<void>(
            "() => document.documentElement.style.fontSize='20px'",
          );
          rows = await _read(page);
          _expectStroke(rows, 'svg-16', 16, scale: 1.25);
          _expectStroke(rows, 'mask-28', 28, scale: 1.25);
          await page.evaluate<void>(
            "() => document.documentElement.style.fontSize='16px'",
          );

          // Replacing just the companion retains the parent's canonical
          // source, including when hydration reuses the normalized host.
          await page.evaluate<void>(
            '''
            () => {
              const host=document.querySelector('#svg-16');
              const child=host.firstElementChild;
              child.replaceWith(child.cloneNode(true));
              host.style.width=host.style.height=host.style.fontSize='20px';
              host.firstElementChild.setAttribute('ratio','0.0625');
            }
          '''
                .trim(),
          );
          await page.waitForFunction(
            '''
            () => document.querySelector('#svg-16')
              .shadowRoot.querySelector('[stroke-width]')
              .getAttribute('stroke-width') === '1.5'
          '''
                .trim(),
          );
          _expectStroke(await _read(page), 'svg-16', 20);
          await page.evaluate<void>(
            '''
            (ratio) => {
              const host=document.querySelector('#svg-16');
              host.style.width=host.style.height=host.style.fontSize='15px';
              host.firstElementChild.setAttribute('ratio',ratio);
            }
            '''
                .trim(),
            args: [
              CoreIconStroke.svgStrokeWidth(15, viewBox: 1).toString(),
            ],
          );
          await page.waitForFunction(
            '''
            () => document.querySelector('#svg-16')
              .shadowRoot.querySelector('[stroke-width]')
              .getAttribute('stroke-width') === '2'
          '''
                .trim(),
          );
          _expectStroke(await _read(page), 'svg-16', 15);

          // Hydrate the actual server tree with optimized Dart, then rebuild
          // size/source and disconnect/reconnect the per-instance companion.
          await page.evaluate<void>(
            '''
            () => new Promise((resolve,reject) => {
              const s=document.createElement('script');
              s.src='/client.js';s.onload=resolve;s.onerror=reject;
              document.head.append(s);
            })'''
                .trim(),
          );
          stdout.writeln('$mode: release client loaded');
          await page.click('#resize');
          await page.waitForFunction(
            '''
            () => document.querySelector('#dynamic')
              .shadowRoot?.querySelector('[stroke-width]')
              ?.getAttribute('stroke-width') === '1.5'
            '''
                .trim(),
          );
          _expectStroke(await _read(page), 'dynamic', 28);
          await page.click('#replace');
          await page.waitForFunction(
            '''
            () => document.querySelector('#dynamic')
              .shadowRoot?.querySelector('path')?.getAttribute('d')
              .startsWith('m2 2')'''
                .trim(),
          );
          await page.click('#customized');
          expect(
            await page.evaluate<String>(
              "() => document.querySelector('#clicks').textContent",
            ),
            '1',
          );
          await page.click('#toggle');
          expect(
            await page.evaluate<bool>(
              "() => !document.querySelector('#dynamic')",
            ),
            isTrue,
          );
          await page.click('#toggle');
          await page.waitForFunction(
            '''
            () => document.querySelector('#dynamic')
              ?.shadowRoot?.querySelector('[stroke-width]')
              ?.getAttribute('stroke-width') === '1.5'
            '''
                .trim(),
          );
          _expectStroke(await _read(page), 'dynamic', 28);
          expect(
            await page.evaluate<bool>(
              '''
            () => customElements.get('iconify-icon')
                .getIcon('lucide:a-arrow-down').body.includes('stroke-width="2"')'''
                  .trim(),
            ),
            isTrue,
          );
          if (mode == 'early') expect(apiRequests, 0);
          if (evidence != null) {
            rows = await _read(page);
            File('$evidence/$mode.json').writeAsStringSync(
              const JsonEncoder.withIndent('  ').convert(rows),
            );
            File(
              '$evidence/$mode-light.png',
            ).writeAsBytesSync(await page.screenshot());
            await page.evaluate<void>(
              '''
            () => {
                document.body.style.background='#111';
                document.body.style.color='#eee';
              }'''
                  .trim(),
            );
            File(
              '$evidence/$mode-dark.png',
            ).writeAsBytesSync(await page.screenshot());
          }
          stdout.writeln(
            '$mode: SVG/mask/bg16/20/24/28=1.25/1.25/1.5/1.75; '
            'ambient/override/scaling/hydration/events/canonical cache PASS',
          );
        } finally {
          await page.close();
          await context.close();
        }
      }
      expect(
        apiRequests,
        greaterThan(0),
        reason: 'async case must exercise the installed Iconify transport',
      );
    },
    skip: !File(_kChrome).existsSync(),
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
