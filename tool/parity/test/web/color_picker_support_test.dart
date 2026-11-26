@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/color_picker_support_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/element_capture.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

const _eyeButton = 'button[aria-label="Pick colour from screen"]';
const _read = '''
() => JSON.stringify({
  cases:Object.fromEntries([...document.querySelectorAll('[data-picker-case]')]
    .map(e=>[e.dataset.pickerCase,{
      buttons:[...e.querySelectorAll('button[aria-label]')]
        .map(b=>b.getAttribute('aria-label')),
      value:e.dataset.value, commits:Number(e.dataset.commits),
      inputs:[...e.querySelectorAll('input')].map(i=>i.value),
      rect:(()=>{const r=e.firstElementChild.getBoundingClientRect();
        return [r.width,r.height]})()
    }])),
  capability:'EyeDropper' in window,
  states:window.readPickerStateTokens
    ?JSON.parse(window.readPickerStateTokens()):null
})
''';

void main() {
  late Directory work;
  late pptr.Browser browser;
  final evidence = Platform.environment['COUI_COLOR_PICKER_SUPPORT_EVIDENCE'];
  final errors = <String>[];
  final requests = <String>[];

  void record(String name, Object? value) {
    if (evidence == null) return;
    Directory(evidence).createSync(recursive: true);
    File('$evidence/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(value),
    );
  }

  Future<Map<String, dynamic>> read(pptr.Page page) async =>
      (jsonDecode(await page.evaluate<String>(_read)) as Map)
          .cast<String, dynamic>();

  int eyeCount(Map<String, dynamic> row, String id) =>
      (((row['cases'] as Map)[id] as Map)['buttons'] as List)
          .where((name) => name == 'Pick colour from screen')
          .length;

  setUpAll(() async {
    work = Directory.systemTemp.createTempSync('coui-color-picker-support-');
    record('work', {'path': work.path});
    addTearDown(() async {
      if (evidence == null && work.existsSync()) {
        await work.delete(recursive: true);
      }
    });
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        div([colorPickerSupportProbe()], id: 'color-picker-support-app'),
      ]),
    );
    for (final theme in ['light', 'dark']) {
      File('${work.path}/$theme.html').writeAsStringSync(
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
    final packageConfig =
        Platform.environment['COUI_COLOR_PICKER_PACKAGE_CONFIG'] ??
        '.dart_tool/package_config.json';
    const fixtureDirectory = 'packages/coui_web/test/browser/fixtures';
    final compile = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--packages=$packageConfig',
      '$fixtureDirectory/color_picker_support_probe.client.dart',
      '-o',
      '${work.path}/client.js',
    ]);
    record('compile', {
      'exit': compile.exitCode,
      'stdout': '${compile.stdout}',
      'stderr': '${compile.stderr}',
    });
    expect(compile.exitCode, 0, reason: '${compile.stdout}\n${compile.stderr}');
    browser = await launchCaptureBrowser(
      width: 1000,
      height: 1000,
      executablePath: Platform.environment['COUI_COLOR_PICKER_CHROME'],
    );
    record('browser', {
      'version': await browser.version,
      'pid': browser.process?.pid,
    });
    addTearDown(() async {
      final pid = browser.process?.pid;
      await browser.close();
      if (browser.process case final process?) await process.exitCode;
      record('cleanup', {
        'browserCloseAwaited': true,
        'pid': pid,
        'errors': errors,
        'externalRequests': requests,
      });
    });
  });

  Future<void> image(pptr.Page page, String id, String name) async {
    if (evidence == null) return;
    final element = await page.$('[data-picker-case="$id"] > *');
    expect(element, isNotNull);
    File('$evidence/$name.png').writeAsBytesSync(
      await captureElementPng(page, element),
    );
  }

  Future<pptr.Page> open(String theme, bool supported) async {
    final page = await browser.newPage();
    addTearDown(page.close);
    page.onError.listen((error) => errors.add('$error'));
    page.onConsole.listen((event) {
      if (event.type == pptr.ConsoleMessageType.error) {
        errors.add(event.text ?? 'console error');
      }
    });
    page.onRequest.listen((request) {
      if (!request.url.startsWith('file:') &&
          !request.url.startsWith('data:')) {
        requests.add(request.url);
      }
    });
    if (!supported) {
      await page.evaluateOnNewDocument('''
() => {
        if(!Reflect.deleteProperty(window,'EyeDropper') ||
          'EyeDropper' in window) throw Error('capability still present');
      }''');
    }
    await page.goto(Uri.file('${work.path}/$theme.html').toString());
    await page.evaluate<bool>('''
async () => {
      await document.fonts.ready; return true;
    }''');
    return page;
  }

  Future<void> hydrate(pptr.Page page, {bool dispose = false}) async {
    await page.evaluate<void>(
      '''
dispose => {
      window.beforeInputs=[...document.querySelectorAll('input')];
      window.beforeRoots=[...document.querySelectorAll('[data-picker-case]')]
        .map(e=>e.firstElementChild);
      window.disposePickerOnFirstFrame=dispose;
      window.recordPickerFirstFrame=()=>{
        window.firstFrame={
          eyeButtons:[...document.querySelectorAll('button[aria-label]')]
            .filter(e=>e.getAttribute('aria-label')===
              'Pick colour from screen').length,
          states:JSON.parse(window.readPickerStateTokens()),
          sameRoots:window.beforeRoots.every(n=>n.isConnected),
          sameInputs:window.beforeInputs.every(n=>n.isConnected &&
            [...document.querySelectorAll('input')].includes(n))};
      };
    }''',
      args: [dispose],
    );
    await page.addScriptTag(url: Uri.file('${work.path}/client.js').toString());
    await page.waitForFunction(
      'document.documentElement.dataset.pickerReady === "true"',
    );
    await page.evaluate<bool>('''
async () => {
      await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));
      return true;
    }''');
  }

  Future<void> input(pptr.Page page, String selector, String value) =>
      page.$eval<void>(
        selector,
        '''
(e,value)=>{
        e.value=value;e.dispatchEvent(new Event('input',{bubbles:true}));
      }''',
        args: [value],
      );

  Future<void> overlayAction(pptr.Page page, String label) async {
    // Wait for the real portal update after a draft input event, and select
    // the visible public action label rather than hidden layout-copy text.
    await page.waitForFunction(
      '''
label=>
      [...document.querySelectorAll('#coui-overlay-popover button')]
        .some(e=>e.innerText.trim()===label)''',
      args: [label],
    );
    await page.evaluate<void>(
      '''
label=>{
      const buttons=[
        ...document.querySelectorAll('#coui-overlay-popover button')];
      const button=buttons.find(e=>e.innerText.trim()===label);
      if(!button)throw Error('missing action '+label+': '+
        buttons.map(e=>e.textContent).join('|'));
      button.click();
    }''',
      args: [label],
    );
  }

  for (final theme in ['light', 'dark']) {
    for (final supported in [true, false]) {
      test(
        'SSR/O2 $theme supported=$supported retains inputs and commits',
        () async {
          final page = await open(theme, supported);
          final ssr = await read(page);
          expect(ssr['capability'], supported);
          for (final id in ['inline-null', 'inline-true', 'dynamic']) {
            expect(eyeCount(ssr, id), 1, reason: 'legacy SSR is preserved');
            expect(((ssr['cases'] as Map)[id] as Map)['rect'], [272, 472]);
          }
          expect(eyeCount(ssr, 'inline-false'), 0);
          expect(((ssr['cases'] as Map)['inline-false'] as Map)['rect'], [
            272,
            466,
          ]);
          await hydrate(page);
          final current = await read(page);
          await image(page, 'inline-null', '$theme-$supported-default');
          await image(page, 'inline-false', '$theme-$supported-explicit-false');
          final initial = await page.evaluate<Map<String, dynamic>>(
            '() => window.firstFrame',
          );
          expect(initial['eyeButtons'], 3);
          expect(initial['sameRoots'], isTrue);
          expect(initial['sameInputs'], isTrue);
          expect(current['states'], initial['states']);
          for (final id in ['inline-null', 'inline-true', 'dynamic']) {
            expect(
              eyeCount(current, id),
              supported ? 1 : 0,
              reason: 'unavailable EyeDropper must hide after hydration',
            );
            expect(((current['cases'] as Map)[id] as Map)['rect'], [
              272,
              if (supported) 472 else 466,
            ]);
          }
          expect(eyeCount(current, 'inline-false'), 0);
          record('$theme-$supported-first', {
            'ssr': ssr,
            'firstFrame': initial,
            'settled': current,
          });

          const dynamicInput = '[data-picker-case="dynamic"] input';
          await input(page, dynamicInput, '#123456');
          await page.waitForFunction('''
()=>{
          const e=document.querySelector('[data-picker-case="dynamic"]');
          return e.dataset.value==='#123456' && e.dataset.commits==='1';
        }''');
          await page.focus(dynamicInput);
          await page.evaluate<void>('''
()=>{
          const host=document.querySelector('[data-picker-case="dynamic"]');
          window.retainedRoot=host.firstElementChild;
          window.retainedInput=host.querySelector('input');
          window.retainedInput.setSelectionRange(2,4);
        }''');
          final retainedState =
              ((await read(page))['states'] as Map)['dynamic'];
          final lifetime = <Object?>[];
          for (final enable in ['false', 'true', 'null']) {
            // Change the public property without a pointer focus action.
            await page.$eval<void>(
              '[data-enable="$enable"]',
              '(e)=>e.click()',
            );
            await page.evaluate<bool>('''
async()=>{
            await new Promise(r=>requestAnimationFrame(r));return true;
          }''');
            final row = await read(page);
            final nodes = await page.evaluate<Map<String, dynamic>>('''
()=>{
            const host=document.querySelector('[data-picker-case="dynamic"]');
            const input=host.querySelector('input');return{
              root:host.firstElementChild===window.retainedRoot,
              input:input===window.retainedInput,
              focused:document.activeElement===input,value:input.value,
              selection:[input.selectionStart,input.selectionEnd]};
          }''');
            expect(nodes['root'], isTrue);
            expect(nodes['input'], isTrue);
            expect(nodes['focused'], isTrue);
            expect(nodes['value'], '#123456');
            expect(nodes['selection'], [2, 4]);
            expect((row['states'] as Map)['dynamic'], retainedState);
            expect(
              eyeCount(row, 'dynamic'),
              supported && enable != 'false' ? 1 : 0,
            );
            expect(((row['cases'] as Map)['dynamic'] as Map)['commits'], 1);
            lifetime.add({
              'enable': enable,
              'nodes': nodes,
              'state': retainedState,
              'case': (row['cases'] as Map)['dynamic'],
            });
          }
          record('$theme-$supported-lifetime', lifetime);
          // Disabled pointer handling and input enabled flags already exist.
          // This does not claim that all disabled keyboard paths are inert.
          await page.click('[data-toggle-enabled]');
          await page.waitForFunction('''
()=>
          [...document.querySelectorAll('[data-picker-case="dynamic"] input')]
            .every(e=>e.disabled)''');
          expect(
            await page.$eval<String>(
              '[data-picker-case="dynamic"] [aria-disabled="true"] > div',
              '(e)=>getComputedStyle(e).pointerEvents',
            ),
            'none',
          );
          await page.click('[data-toggle-enabled]');
          await page.waitForFunction('''
()=>
          [...document.querySelectorAll('[data-picker-case="dynamic"] input')]
            .every(e=>!e.disabled)''');
          expect(
            ((await read(page))['states'] as Map)['dynamic'],
            retainedState,
          );

          Future<void> openPopover() async {
            await page.click('[data-picker-case="popover"] button');
            await page.waitForSelector('#coui-overlay-popover input');
            final count = await page.$$eval<int>(
              '#coui-overlay-popover $_eyeButton',
              '(e)=>e.length',
            );
            expect(count, supported ? 1 : 0);
          }

          await openPopover();
          await input(page, '#coui-overlay-popover input', '#112233');
          await overlayAction(page, 'Cancel');
          await page.waitForFunction('''
()=>
          !document.querySelector('#coui-overlay-popover input')''');
          final cancelled = await read(page);
          expect(
            ((cancelled['cases'] as Map)['popover'] as Map)['value'],
            '#6750A4',
          );
          expect(((cancelled['cases'] as Map)['popover'] as Map)['commits'], 0);
          await openPopover();
          await input(page, '#coui-overlay-popover input', '#224466');
          await overlayAction(page, 'Save');
          await page.waitForFunction('''
()=>{
          const e=document.querySelector('[data-picker-case="popover"]');
          return e.dataset.value==='#224466' && e.dataset.commits==='1';
        }''');
          final saved = await read(page);
          record('$theme-$supported-draft', {
            'cancelled': cancelled,
            'saved': saved,
          });
          expect(saved['states'], current['states']);
          expect(errors, isEmpty);
          expect(requests, isEmpty);
        },
      );
    }
  }

  test(
    'queued capability checks tolerate a caller disposing the root',
    () async {
      final page = await open('light', false);
      await hydrate(page, dispose: true);
      final first = await page.evaluate<Map<String, dynamic>>(
        '()=>window.firstFrame',
      );
      final states = (await read(page))['states'] as Map;
      record('disposed-before-capability', {
        'firstFrame': first,
        'afterStates': states,
      });
      expect(first['eyeButtons'], 3);
      expect((first['states'] as Map).values, everyElement(isNotNull));
      expect(states.values, everyElement(isNull));
      // Jaspr detaches/disposes State but retains these DOM nodes.
      record('disposed-dom', {
        'remainingInputs': await page.$$eval<int>('input', '(e)=>e.length'),
      });
      expect(errors, isEmpty);
      expect(requests, isEmpty);
    },
  );
}
