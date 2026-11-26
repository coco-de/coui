@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/number_ticker_idle_builder_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/ssr_render.dart';

void main() {
  final evidence = Platform.environment['COUI_TICKER_IDLE_EVIDENCE'];
  late Directory work;
  late pptr.Browser browser;

  void record(String name, Object? value) {
    if (evidence == null) return;
    Directory(evidence).createSync(recursive: true);
    File('$evidence/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(value),
    );
  }

  setUpAll(() async {
    work = Directory.systemTemp.createTempSync('coui-ticker-idle-');
    addTearDown(() async {
      if (work.existsSync()) await work.delete(recursive: true);
    });
    File('${work.path}/index.html').writeAsStringSync(
      '''
<!doctype html><html><head><link rel="icon" href="data:,"></head>
<body><div id="number-ticker-idle-app"></div></body></html>
''',
    );
    final config =
        Platform.environment['COUI_TICKER_PACKAGE_CONFIG'] ??
        '.dart_tool/package_config.json';
    const fixtureDir = 'packages/coui_web/test/browser/fixtures';
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--packages=$config',
      '$fixtureDir/number_ticker_idle_builder_probe.client.dart',
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
      width: 800,
      height: 600,
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

  test('idle custom builder SSR renders without an unused theme', () async {
    String? html;
    Object? error;
    try {
      html = await renderComponentBodyHtml(numberTickerIdleBuilderProbe());
    } on Object catch (e) {
      error = '$e';
    }
    record('SSR', {
      'html': html,
      'error': error,
      'observations': readNumberTickerIdleBuilder?.call(),
    });
    expect(error, isNull);
    expect(html, contains('idle:100.0'));
    final values = readNumberTickerIdleBuilder!.call()['values']! as Map;
    expect(values.keys, unorderedEquals(['plain', 'zero']));
    expect(values.values, everyElement([100]));
  });

  test(
    'idle builder O2 mount and same-value parent refresh retain owners',
    () async {
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
      await page.evaluate<void>('''
() => {
 window.readIdleDOM=()=>({state:JSON.parse(window.readIdleBuilderProbe()),
  roots:['plain','zero'].map(n=>document.getElementById('idle-'+n)?.dataset.value),
  children:['plain','zero'].map(n=>document.getElementById('idle-child-'+n)?.textContent)});
 window.recordIdleBuilderFrame=()=>window.idleFirst=window.readIdleDOM();
}
''');
      await page.addScriptTag(
        url: Uri.file('${work.path}/client.js').toString(),
      );
      await page.waitForFunction(
        'document.documentElement.dataset.idleAttempted==="true"',
      );
      final mounted = await page.evaluate<Map<String, dynamic>>(
        '()=>window.readIdleDOM()',
      );
      record('mount', {
        'observations': mounted,
        'errors': errors,
        'externalRequests': requests,
      });
      expect(errors, isEmpty);
      expect(mounted['roots'], ['100', '100']);
      await page.evaluate<void>('''
() => {window.idleRoots=['plain','zero'].map(n=>document.getElementById('idle-'+n));
 window.idleChildren=['plain','zero'].map(n=>document.getElementById('idle-child-'+n));}
''');
      final refreshes = <Object?>[];
      for (var revision = 1; revision <= 2; revision++) {
        await page.$eval<void>('#idle-parent-refresh', '(e)=>e.click()');
        await page.waitForFunction(
          'n=>JSON.parse(window.readIdleBuilderProbe()).refreshes===n',
          args: [revision],
        );
        final after = await page.evaluate<Map<String, dynamic>>('''
() => ({...window.readIdleDOM(),
 sameRoots:['plain','zero'].map((n,i)=>window.idleRoots[i]===document.getElementById('idle-'+n)),
 sameChildren:['plain','zero'].map((n,i)=>window.idleChildren[i]===document.getElementById('idle-child-'+n))})
''');
        refreshes.add(after);
        record('refreshes', refreshes);
        expect(after['roots'], ['100', '100']);
        expect(after['sameRoots'], everyElement(true));
        expect(after['sameChildren'], everyElement(true));
        final state = after['state'] as Map;
        expect(state['stateTokens'], (mounted['state'] as Map)['stateTokens']);
        expect(state['childTokens'], (mounted['state'] as Map)['childTokens']);
      }
      await page.$eval<void>('#idle-child-plain', '(e)=>e.click()');
      await page.waitForFunction(
        'document.getElementById("idle-child-plain").textContent==="Child 1"',
      );
      record('final', {
        'observations': await page.evaluate<Map<String, dynamic>>(
          '()=>window.readIdleDOM()',
        ),
        'errors': errors,
        'externalRequests': requests,
      });
      expect(errors, isEmpty);
      expect(requests, isEmpty);
    },
  );
}
