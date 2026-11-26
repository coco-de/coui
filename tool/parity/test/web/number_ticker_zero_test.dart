@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/number_ticker_zero_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  final evidence = Platform.environment['COUI_TICKER_ZERO_EVIDENCE'];
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
    work = Directory.systemTemp.createTempSync('coui-ticker-zero-');
    addTearDown(() async {
      if (work.existsSync()) await work.delete(recursive: true);
    });
    ssr = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        div([numberTickerZeroProbe()], id: 'number-ticker-zero-app'),
      ]),
    );
    for (final theme in ['light', 'dark']) {
      File('${work.path}/$theme.html').writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: ssr,
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
    final packageConfig =
        Platform.environment['COUI_TICKER_PACKAGE_CONFIG'] ??
        '.dart_tool/package_config.json';
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--packages=$packageConfig',
      'packages/coui_web/test/browser/fixtures/number_ticker_zero_probe.client.dart',
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

  test('SSR zero duration resolves target before formatting and builder', () {
    record('SSR', {'html': ssr, 'state': readNumberTickerZero?.call()});
    final values = readNumberTickerZero!.call()['values']! as Map;
    for (final name in [
      'zero-formatted',
      'zero-builder',
      'zero-theme',
      'zero-chain',
    ]) {
      expect(values[name], [100], reason: '$name resolves explicit zero');
    }
  });

  for (final theme in ['light', 'dark']) {
    test('zero mount update retarget and live $theme', () async {
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
      await page.goto(Uri.file('${work.path}/$theme.html').toString());
      await page.evaluate<void>('async()=>{await document.fonts.ready}');
      await page.evaluate<void>('''
() => {
window.zeroNames=['zero-formatted','zero-builder','zero-theme','zero-chain','positive-150','positive-800','positive-subms','live-instance','live-theme'];
window.zeroBefore=Object.fromEntries(window.zeroNames.map(n=>[n,document.getElementById(n)]));
window.zeroBeforeChild=document.getElementById('zero-child');
window.zeroFrames={};
window.readZeroDOM=()=>({state:JSON.parse(window.readZeroProbe()),
 nodes:Object.fromEntries(window.zeroNames.map(n=>{let e=document.getElementById(n);return [n,{value:e.dataset.value??e.textContent,same:e===window.zeroBefore[n]}]})),
 childSame:window.zeroBeforeChild===document.getElementById('zero-child')});
window.recordZeroFrame=phase=>{window.zeroFrames[phase]=window.readZeroDOM();if(phase==='initial')requestAnimationFrame(()=>window.zeroFrames.firstRAF=window.readZeroDOM());};
}''');
      await page.addScriptTag(
        url: Uri.file('${work.path}/client.js').toString(),
      );
      await page.waitForFunction(
        'document.documentElement.dataset.zeroReady==="true"',
      );
      await page.waitForFunction(
        '''
() => {
 const value = Number(document.getElementById('positive-800').dataset.value);
 return value > 0 && value < 100;
}
''',
      );
      await page.$eval<void>('#zero-live', '(e)=>e.click()');
      await page.waitForFunction('!!window.zeroFrames["live-zero"]');
      await page.$eval<void>('#zero-update', '(e)=>e.click()');
      await page.waitForFunction('!!window.zeroFrames.update');
      await page.$eval<void>('#zero-retarget', '(e)=>e.click()');
      await page.waitForFunction('!!window.zeroFrames.retarget');
      await page.waitForFunction(
        'document.getElementById("positive-800").dataset.value==="300"',
      );
      await page.$eval<void>('#zero-child', '(e)=>e.click()');
      await page.$eval<void>('#zero-formatted', '(e)=>e.click()');
      final observations = await page.evaluate<Map<String, dynamic>>(
        '''
()=>({
 frames:window.zeroFrames,final:window.readZeroDOM(),childText:document.getElementById('zero-child').textContent,
 root:(()=>{let e=document.getElementById('zero-formatted'),s=getComputedStyle(e);return {color:s.color,spacing:s.letterSpacing,role:e.getAttribute('role'),label:e.getAttribute('aria-label'),caller:e.classList.contains('zero-caller')};})()})''',
      );
      record('$theme-original', {
        'observations': observations,
        'errors': errors,
        'externalRequests': requests,
      });
      final frames = observations['frames'] as Map;
      final failures = <String>[];
      for (final phase in ['initial', 'update', 'retarget']) {
        final target = phase == 'initial'
            ? 100
            : phase == 'update'
            ? 200
            : 300;
        final state = (frames[phase] as Map)['state'] as Map;
        final values = state['values'] as Map;
        for (final name in [
          'zero-formatted',
          'zero-builder',
          'zero-theme',
          'zero-chain',
        ]) {
          if ((values[name] as List).last != target) {
            failures.add(
              '$phase $name: ${(values[name] as List).last} != $target',
            );
          }
        }
      }
      final finalState = (observations['final'] as Map)['state'] as Map;
      final liveValues =
          ((frames['live-zero'] as Map)['state'] as Map)['values'] as Map;
      for (final name in ['live-instance', 'live-theme']) {
        if ((liveValues[name] as List).last != 100) {
          failures.add(
            'same-target live-zero $name: '
            '${(liveValues[name] as List).last} != 100',
          );
        }
      }
      record('$theme-failing-contracts', failures);
      // Curve invocations are observations, not a public call-count contract.
      expect(observations['root'] as Map, {
        'color': 'rgb(18, 52, 86)',
        'spacing': '2px',
        'role': 'status',
        'label': 'Public total',
        'caller': true,
      });
      expect(observations['childText'], 'Child 1');
      expect((observations['final'] as Map)['childSame'], true);
      expect(
        finalState['stateTokens'],
        ((frames['initial'] as Map)['state'] as Map)['stateTokens'],
      );
      for (final n in ['positive-150', 'positive-800']) {
        final values = ((finalState['values'] as Map)[n] as List).cast<num>();
        expect(values.any((v) => v > 0 && v < 100), true);
        expect(values.last, 300);
      }
      expect(
        ((finalState['values'] as Map)['positive-subms'] as List).last,
        300,
      );
      final initialValues =
          ((frames['initial'] as Map)['state'] as Map)['values'] as Map;
      for (final name in ['positive-subms', 'positive-150', 'positive-800']) {
        expect(
          (initialValues[name] as List).first,
          0,
          reason: 'positive duration keeps its initial builder value',
        );
      }
      for (final phase in ['initial', 'live-zero', 'update', 'retarget']) {
        final nodes = (frames[phase] as Map)['nodes'] as Map;
        expect(nodes.values.map((e) => (e as Map)['same']), everyElement(true));
      }
      expect(errors, isEmpty);
      expect(requests, isEmpty);
      expect(
        failures,
        isEmpty,
        reason: 'resolved zero renders target without interpolation',
      );
    });
  }
}
