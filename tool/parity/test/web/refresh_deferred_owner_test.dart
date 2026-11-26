@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/refresh_deferred_owner_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  final evidence = Platform.environment['COUI_REFRESH_OWNER_EVIDENCE'];
  late Directory work;
  late pptr.Browser browser;
  late String ssr;

  void record(String name, Object? value) {
    if (evidence == null) return;
    Directory(evidence).createSync(recursive: true);
    File('$evidence/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(value),
    );
  }

  setUpAll(() async {
    work = Directory.systemTemp.createTempSync('coui-refresh-owner-');
    addTearDown(() async {
      if (work.existsSync()) await work.delete(recursive: true);
    });
    ssr = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        div([refreshDeferredOwnerProbe()], id: 'refresh-owner-app'),
      ]),
    );
    File('${work.path}/index.html').writeAsStringSync(
      buildOfflineTailwindHarnessHtml(
        bodyHtml: ssr,
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        animationFreezeCss: '',
        additionalHeadHtml:
            '<link rel="icon" href="data:,">\n'
            '<style>${buildLocalFontFaceCss()}</style>\n'
            '${buildLocalIconifyHeadHtml()}',
      ),
    );
    final config =
        Platform.environment['COUI_OWNER_PACKAGE_CONFIG'] ??
        '.dart_tool/package_config.json';
    const fixtures = 'packages/coui_web/test/browser/fixtures';
    final compile = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--packages=$config',
      '$fixtures/refresh_deferred_owner_probe.client.dart',
      '-o',
      '${work.path}/client.js',
    ]);
    record('compile', {
      'exitCode': compile.exitCode,
      'stdout': '${compile.stdout}',
      'stderr': '${compile.stderr}',
    });
    expect(compile.exitCode, 0, reason: '${compile.stdout}\n${compile.stderr}');
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

  test('SSR keeps refresh idle and does not invoke the callback', () {
    final state = readRefreshDeferredOwner!.call();
    record('SSR', {'html': ssr, 'state': state});
    expect(ssr, contains('Refresh child 0'));
    expect(state['callbackCount'], 0);
    expect(state['results'], isEmpty);
  });

  for (final scenario in [
    'queued-dispose',
    'mounted-two',
    'single-dispose',
    'caller-error',
  ]) {
    test('public pending refresh $scenario', () async {
      final errors = <String>[];
      final requests = <String>[];
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
      await page.goto(Uri.file('${work.path}/index.html').toString());
      await page.evaluate<void>('async()=>{await document.fonts.ready}');
      await page.addScriptTag(
        url: Uri.file('${work.path}/client.js').toString(),
      );
      await page.waitForFunction(
        'document.documentElement.dataset.refreshReady==="true"',
      );
      final before = await page.evaluate<Map<String, dynamic>>(
        '()=>JSON.parse(window.readRefreshOwner())',
      );
      await page.evaluate<void>(
        '()=>window.refreshRoot=document.getElementById("refresh-real-root")',
      );
      final count = scenario == 'single-dispose' ? 1 : 2;
      await page.$eval<void>(
        '#refresh-start-${count == 1 ? 'one' : 'two'}',
        '(e)=>e.click()',
      );
      final pending = await page.evaluate<Map<String, dynamic>>(
        '()=>JSON.parse(window.readRefreshOwner())',
      );
      expect(pending['invocationMounted'], everyElement(true));
      expect(pending['callbackCount'], 1);
      expect((pending['results'] as Map)['first'], {'status': 'pending'});
      if (scenario.endsWith('dispose')) {
        await page.$eval<void>('#refresh-remove', '(e)=>e.click()');
        await page.waitForFunction(
          'JSON.parse(window.readRefreshOwner()).currentMounted===null',
        );
        final unmounted = await page.evaluate<Map<String, dynamic>>(
          '()=>JSON.parse(window.readRefreshOwner())',
        );
        record('$scenario-unmounted', unmounted);
        expect(unmounted['retainedMounted'], false);
        expect(
          await page.evaluate<bool>(
            '()=>document.getElementById("refresh-real-root")===null',
          ),
          true,
        );
      }
      if (scenario == 'caller-error') {
        await page.$eval<void>('#refresh-fail-first', '(e)=>e.click()');
      } else {
        await page.$eval<void>('#refresh-complete-first', '(e)=>e.click()');
      }
      if (scenario == 'mounted-two') {
        await page.waitForFunction(
          'JSON.parse(window.readRefreshOwner()).callbackCount===2',
        );
        await page.$eval<void>('#refresh-complete-second', '(e)=>e.click()');
      }
      await page.waitForFunction('''
() => Object.values(JSON.parse(window.readRefreshOwner()).results)
 .every(x=>x.status!=='pending')
''');
      final after = await page.evaluate<Map<String, dynamic>>(
        '()=>JSON.parse(window.readRefreshOwner())',
      );
      Map<String, dynamic>? root;
      if (scenario == 'mounted-two') {
        await page.$eval<void>('#refresh-real-child', '(e)=>e.click()');
        root = await page.$eval<Map<String, dynamic>>('#refresh-real-root', '''
e=>({same:e===window.refreshRoot,color:getComputedStyle(e).color,
 label:e.getAttribute('aria-label'),caller:e.classList.contains('refresh-caller'),
 child:document.getElementById('refresh-real-child').textContent})
''');
      }
      record(scenario, {
        'before': before,
        'pending': pending,
        'after': after,
        'root': root,
        'errors': errors,
        'externalRequests': requests,
      });
      final results = after['results'] as Map;
      if (scenario == 'caller-error') {
        expect(
          results.values.map((e) => (e as Map)['status']),
          everyElement('error'),
        );
        expect(
          results.values.map((e) => (e as Map)['isOwnedError']),
          everyElement(true),
        );
        expect(after['callbackCount'], 1);
      } else {
        expect(
          results.values.map((e) => (e as Map)['status']),
          everyElement('done'),
        );
        expect(after['callbackCount'], scenario == 'mounted-two' ? 2 : 1);
      }
      if (scenario == 'mounted-two') {
        expect(after['stateToken'], before['stateToken']);
        expect(after['childToken'], before['childToken']);
        expect(root, {
          'same': true,
          'color': 'rgb(18, 52, 86)',
          'label': 'Caller refresh region',
          'caller': true,
          'child': 'Refresh child 1',
        });
      }
      expect(errors, isEmpty);
      expect(requests, isEmpty);
    });
  }
}
