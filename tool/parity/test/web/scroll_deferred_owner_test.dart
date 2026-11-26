@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/scroll_deferred_owner_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  final evidence = Platform.environment['COUI_SCROLL_OWNER_EVIDENCE'];
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
    work = Directory.systemTemp.createTempSync('coui-scroll-owner-');
    addTearDown(() async {
      if (work.existsSync()) await work.delete(recursive: true);
    });
    ssr = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        div([scrollDeferredOwnerProbe('A')], id: 'scroll-owner-app'),
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
      '$fixtures/scroll_deferred_owner_probe.client.dart',
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

  test(
    'SSR emits the public viewport and child before browser measurement',
    () {
      record('SSR', {'html': ssr, 'observations': readScrollDeferredOwner()});
      expect(ssr, contains('Scroll A 0'));
      final samples = readScrollDeferredOwner()['samples']! as Map;
      final first = (samples['A'] as List).first as Map;
      expect(first['width'], 0);
      expect(first['height'], 0);
    },
  );

  for (final mode in ['stable', 'remove', 'replace']) {
    test('public initial measurement owner $mode', () async {
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
      await page.evaluate<void>(
        '''
mode => {
 window.scrollOwnerMode=mode;window.scrollOwnerTrace=[];
 window.readScrollDOM=()=>{let e=document.getElementById('deferred-real-viewport');
 return {state:JSON.parse(window.readScrollOwner()),
 count:document.querySelectorAll('#deferred-real-viewport').length,
 root:e?{owner:e.dataset.owner,width:e.clientWidth,height:e.clientHeight,
 scrollWidth:e.scrollWidth,scrollHeight:e.scrollHeight,dx:e.scrollLeft,dy:e.scrollTop,
 color:getComputedStyle(e).color,label:e.getAttribute('aria-label'),
 caller:e.classList.contains('viewport-caller'),sameA:e===window.scrollANode,
 sameB:e===window.scrollBNode}:null,
 aConnected:window.scrollANode?.isConnected??false};};
 window.recordScrollOwner=phase=>{let e=document.getElementById('deferred-real-viewport');
 if(phase==='first-A')window.scrollANode=e;
 if(phase==='first-B')window.scrollBNode=e;
 window.scrollOwnerTrace.push({phase,...window.readScrollDOM()});};
}
''',
        args: [mode],
      );
      await page.addScriptTag(
        url: Uri.file('${work.path}/client.js').toString(),
      );
      await page.waitForFunction(
        'document.documentElement.dataset.scrollReady==="true"',
      );
      record(
        '$mode-first',
        await page.evaluate<Map<String, dynamic>>('''
()=>({trace:window.scrollOwnerTrace,after:window.readScrollDOM()})
'''),
      );
      final targetOwner = mode == 'replace' ? 'B' : 'A';
      if (mode != 'remove') {
        await page.waitForFunction(
          '''
name => {let rows=JSON.parse(window.readScrollOwner()).samples[name];
 return rows?.length&&rows.at(-1).width>0&&rows.at(-1).height>0;}
''',
          args: [targetOwner],
        );
      }
      await page.evaluate<void>('''
()=>new Promise(resolve=>requestAnimationFrame(()=>resolve()))
''');
      final observed = await page.evaluate<Map<String, dynamic>>('''
()=>({trace:window.scrollOwnerTrace,after:window.readScrollDOM()})
''');
      record(mode, {
        'observations': observed,
        'errors': errors,
        'externalRequests': requests,
      });
      final trace = observed['trace'] as List;
      expect(
        trace.map((e) => (e as Map)['count']),
        everyElement(lessThanOrEqualTo(1)),
      );
      final after = observed['after'] as Map;
      if (mode == 'remove') {
        expect(after['count'], 0);
        expect((after['state'] as Map)['currentMounted'], {
          'A': null,
          'B': null,
        });
        expect(((after['state'] as Map)['retainedMounted'] as Map)['A'], false);
      } else {
        final name = mode == 'replace' ? 'B' : 'A';
        final root = after['root'] as Map;
        final state = after['state'] as Map;
        final last = ((state['samples'] as Map)[name] as List).last as Map;
        expect(root['owner'], name);
        expect(root['width'], greaterThan(0));
        expect(root['height'], greaterThan(0));
        expect(root['scrollWidth'], greaterThan(root['width'] as num));
        expect(root['scrollHeight'], greaterThan(root['height'] as num));
        expect(last['width'], root['width']);
        expect(last['height'], root['height']);
        expect(last['sameChild'], true);
        expect(root['dx'], mode == 'replace' ? 45 : 15);
        expect(root['dy'], mode == 'replace' ? 65 : 25);
        expect(last['dx'], root['dx']);
        expect(last['dy'], root['dy']);
        expect(root['color'], 'rgb(18, 52, 86)');
        expect(root['caller'], true);
        expect(root['label'], 'Caller viewport $name');
        if (mode == 'replace') {
          expect((state['retainedMounted'] as Map)['A'], false);
          expect((state['currentMounted'] as Map)['B'], true);
          expect(state['sameRetainedState'], false);
          expect(after['aConnected'], false);
          expect(root['sameB'], true);
          expect(root['sameA'], false);
        }
      }
      expect(requests, isEmpty);
      expect(errors, isEmpty);
    });
  }
}
