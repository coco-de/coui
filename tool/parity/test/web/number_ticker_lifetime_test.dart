@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/number_ticker_lifetime_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  late Directory work;
  late pptr.Browser browser;
  final evidence = Platform.environment['COUI_TICKER_LIFETIME_EVIDENCE'];

  void record(String name, Object? data) {
    if (evidence == null) return;
    Directory(evidence).createSync(recursive: true);
    File('$evidence/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  setUpAll(() async {
    work = Directory.systemTemp.createTempSync('coui-ticker-lifetime-');
    record('work', {'path': work.path});
    addTearDown(() async {
      if (evidence == null && work.existsSync()) {
        await work.delete(recursive: true);
      }
    });
    for (final withInitial in [true, false]) {
      final body = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          div([
            numberTickerLifetimeProbe(withInitialValues: withInitial),
          ], id: 'number-ticker-lifetime-app'),
        ]),
      );
      for (final theme in ['light', 'dark']) {
        File('${work.path}/$theme-$withInitial.html').writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml: body,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            theme: theme,
            animationFreezeCss: '',
            additionalHeadHtml:
                '<link rel="icon" href="data:,">\n'
                '<style>${buildLocalFontFaceCss()}</style>\n'
                '${buildLocalIconifyHeadHtml()}',
          ),
        );
      }
    }
    final config =
        Platform.environment['COUI_TICKER_PACKAGE_CONFIG'] ??
        '.dart_tool/package_config.json';
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--packages=$config',
      'packages/coui_web/test/browser/fixtures/number_ticker_lifetime_probe.client.dart',
      '-o',
      '${work.path}/client.js',
    ]);
    record('compile', {
      'exitCode': compiled.exitCode,
      'stdout': '${compiled.stdout}',
      'stderr': '${compiled.stderr}',
    });
    expect(
      compiled.exitCode,
      0,
      reason: '${compiled.stdout}\n${compiled.stderr}',
    );
    browser = await launchCaptureBrowser(
      width: 1000,
      height: 800,
      executablePath: Platform.environment['PUPPETEER_EXECUTABLE_PATH'],
    );
    record('browser', {
      'version': await browser.version,
      'pid': browser.process?.pid,
    });
    addTearDown(() async {
      await browser.close();
      if (browser.process case final process?) await process.exitCode;
      record('cleanup', {'browserClosed': true});
    });
  });

  Future<Map<String, dynamic>> read(pptr.Page page) =>
      page.evaluate<Map<String, dynamic>>('''
() => ({state:JSON.parse(window.readTickerProbe()),
 plain:document.querySelector('#ticker-plain')?.textContent, 
 builder:document.querySelector('#ticker-builder')?Number(document.querySelector('#ticker-builder').dataset.builderValue):null,
 same:document.querySelector('#ticker-same')?.textContent,
 noInitial:document.querySelector('#ticker-no-initial')?.textContent,
 child:document.querySelector('#ticker-child')?.textContent,
 rootConnected:document.querySelector('#ticker-plain')?.isConnected??false})
''');

  Future<pptr.Page> open(
    String theme,
    List<String> errors,
    List<String> requests, {
    bool withInitial = true,
  }) async {
    final page = await browser.newPage();
    addTearDown(page.close);
    page.onError.listen((e) => errors.add('$e'));
    page.onConsole.listen((e) {
      if (e.type == pptr.ConsoleMessageType.error) {
        errors.add(e.text ?? 'error');
      }
    });
    page.onRequest.listen((e) {
      if (!e.url.startsWith('file:') && !e.url.startsWith('data:')) {
        requests.add(e.url);
      }
    });
    await page.goto(
      Uri.file('${work.path}/$theme-$withInitial.html').toString(),
    );
    await page.evaluate<void>('async()=>{await document.fonts.ready}');
    return page;
  }

  Future<void> hydrate(
    pptr.Page page, {
    required bool dispose,
    bool withInitial = true,
  }) async {
    await page.evaluate<void>(
      '''
(dispose,withInitial)=>{
 window.beforePlain=document.querySelector('#ticker-plain');
 window.beforeChild=document.querySelector('#ticker-child');
 window.disposeTickerOnFirstFrame=dispose;
 window.tickerWithoutInitialValues=!withInitial;
 window.recordTickerFirstFrame=()=>{
  window.tickerFirstFrame={state:JSON.parse(window.readTickerProbe()),
   samePlain:window.beforePlain===document.querySelector('#ticker-plain'),
   sameChild:window.beforeChild===document.querySelector('#ticker-child')};
 };
}
''',
      args: [dispose, withInitial],
    );
    await page.addScriptTag(url: Uri.file('${work.path}/client.js').toString());
    await page.waitForFunction(
      'document.documentElement.dataset.tickerReady==="true"',
    );
  }

  for (final theme in ['light', 'dark']) {
    test(
      'pending initial animation tolerates public root dispose $theme',
      () async {
        final errors = <String>[];
        final requests = <String>[];
        final page = await open(theme, errors, requests);
        final ssr = await page.$eval<String>(
          '#ticker-plain',
          '(e)=>e.textContent',
        );
        await hydrate(page, dispose: true);
        await Future<void>.delayed(const Duration(milliseconds: 120));
        final first = await page.evaluate<Map<String, dynamic>>(
          '()=>window.tickerFirstFrame',
        );
        final after = await read(page);
        record('$theme-dispose', {
          'SSRPlain': ssr,
          'firstFrame': first,
          'after': after,
          'errors': errors,
          'externalRequests': requests,
        });
        expect(ssr, 'v=0.0');
        expect(first['samePlain'], true);
        expect(first['sameChild'], true);
        expect(
          ((first['state'] as Map)['mounted'] as Map).values,
          everyElement(true),
        );
        expect(
          ((after['state'] as Map)['mounted'] as Map).values,
          everyElement(isNull),
        );
        expect(
          ((after['state'] as Map)['retainedMounted'] as Map).values,
          everyElement(false),
        );
        expect((after['state'] as Map)['hostDisposed'], true);
        // Retained DOM is observed separately: unmount need not delete nodes.
        expect(errors, isEmpty);
        expect(requests, isEmpty);
      },
    );

    test(
      'mounted interpolation keeps builder child formatter and root $theme',
      () async {
        final errors = <String>[];
        final requests = <String>[];
        final page = await open(theme, errors, requests);
        await hydrate(page, dispose: false);
        final first = await page.evaluate<Map<String, dynamic>>(
          '()=>window.tickerFirstFrame',
        );
        await page.waitForFunction(
          'document.querySelector("#ticker-plain").textContent==="v=100.0"',
        );
        final before = await read(page);
        await page.click('#ticker-child');
        await page.click('#ticker-plain');
        await page.$eval<void>('#ticker-change', '(e)=>e.click()');
        await page.waitForFunction(
          'document.querySelector("#ticker-plain").textContent==="v=200.0"',
        );
        final after = await read(page);
        final root = await page.$eval<Map<String, dynamic>>('#ticker-plain', '''
e=>({id:e.id,label:e.getAttribute('aria-label'),role:e.getAttribute('role'),
 callerClass:e.classList.contains('ticker-caller'),color:getComputedStyle(e).color,
 spacing:getComputedStyle(e).letterSpacing,sameRoot:e===window.beforePlain,
 sameChild:document.querySelector('#ticker-child')===window.beforeChild})
''');
        await page.$eval<void>('#ticker-change', '(e)=>e.click()');
        await page.waitForFunction(
          'document.querySelector("#ticker-plain").textContent!=="v=200.0"',
        );
        await page.evaluate<void>('()=>window.disposeTickerRoot()');
        final cancelled = await read(page);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final settled = await read(page);
        record('$theme-positive', {
          'firstFrame': first,
          'before': before,
          'after': after,
          'root': root,
          'cancelled': cancelled,
          'settled': settled,
          'errors': errors,
          'externalRequests': requests,
        });
        final values = ((after['state'] as Map)['builderValues'] as List)
            .cast<num>();
        expect(values.any((x) => x > 0 && x < 100), true);
        expect(values, contains(100));
        expect(values, contains(200));
        expect((after['state'] as Map)['childIdentities'], everyElement(true));
        expect(
          (after['state'] as Map)['childToken'],
          (before['state'] as Map)['childToken'],
        );
        expect(
          (after['state'] as Map)['stateTokens'],
          (before['state'] as Map)['stateTokens'],
        );
        expect(after['child'], 'Child 1');
        expect(after['same'], '42');
        expect(after['noInitial'], '42');
        expect((after['state'] as Map)['rootClicks'], 1);
        expect(root, {
          'id': 'ticker-plain',
          'label': 'Formatted total',
          'role': 'status',
          'callerClass': true,
          'color': 'rgb(18, 52, 86)',
          'spacing': '2px',
          'sameRoot': true,
          'sameChild': true,
        });
        expect(settled['plain'], cancelled['plain']);
        expect(
          (settled['state'] as Map)['builderValues'],
          (cancelled['state'] as Map)['builderValues'],
        );
        expect(errors, isEmpty);
        expect(requests, isEmpty);
      },
    );
  }

  test(
    'public root dispose without initialValue is a healthy host control',
    () async {
      final errors = <String>[];
      final requests = <String>[];
      final page = await open('light', errors, requests, withInitial: false);
      final ssr = await page.$eval<String>(
        '#ticker-plain',
        '(e)=>e.textContent',
      );
      await hydrate(page, dispose: true, withInitial: false);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final after = await read(page);
      record('no-initial-dispose', {
        'after': after,
        'errors': errors,
        'externalRequests': requests,
      });
      expect(ssr, 'v=100.0');
      expect(
        ((after['state'] as Map)['retainedMounted'] as Map).values,
        everyElement(false),
      );
      expect(errors, isEmpty);
      expect(requests, isEmpty);
    },
  );
}
