@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/color_picker_disabled_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

const _eyeButton = 'button[aria-label="Pick colour from screen"]';

void main() {
  late Directory work;
  late pptr.Browser browser;
  final evidence = Platform.environment['COUI_COLOR_PICKER_DISABLED_EVIDENCE'];
  final errors = <String>[];
  final requests = <String>[];

  void record(String name, Object? value) {
    if (evidence == null) return;
    Directory(evidence).createSync(recursive: true);
    File('$evidence/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(value),
    );
  }

  setUpAll(() async {
    work = Directory.systemTemp.createTempSync('coui-color-picker-disabled-');
    record('work', {'path': work.path});
    addTearDown(() async {
      if (evidence == null && work.existsSync()) {
        await work.delete(recursive: true);
      }
    });
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        div([colorPickerDisabledProbe()], id: 'color-picker-disabled-app'),
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
      '$fixtureDirectory/color_picker_disabled_probe.client.dart',
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

  Future<void> frames(pptr.Page page) => page.evaluate<void>(
    '()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))',
  );

  Future<pptr.Page> open(String theme, {bool deferred = false}) async {
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
    await page.evaluateOnNewDocument(
      '''
deferred => {
      window.eyeCalls=0;window.eyePending=[];window.deferEye=deferred;
      Object.defineProperty(window,'EyeDropper',{configurable:true,value:class {
        open(){window.eyeCalls++;
          return window.deferEye ? new Promise(r=>window.eyePending.push(r))
            : Promise.resolve({sRGBHex:'#00FF00'});
        }
      }});
    }''',
      args: [deferred],
    );
    await page.goto(Uri.file('${work.path}/$theme.html').toString());
    await page.evaluate<void>('async()=>{await document.fonts.ready}');
    await page.addScriptTag(url: Uri.file('${work.path}/client.js').toString());
    await page.waitForFunction(
      'document.documentElement.dataset.disabledReady==="true"',
    );
    await frames(page);
    return page;
  }

  Future<void> control(pptr.Page page, String id) async {
    await page.$eval<void>('#$id', '(e)=>e.click()');
    await frames(page);
  }

  Future<Map<String, dynamic>> read(pptr.Page page, String id) =>
      page.evaluate<Map<String, dynamic>>(
        '''
id=>{
      const root=document.querySelector('#picker-'+id);
      const host=document.querySelector('[data-disabled-case="'+id+'"]');
      return {state:JSON.parse(window.readDisabledPickerStates())[id],
        changes:Number(host.dataset.commits),color:host.dataset.value,
        eyeCalls:window.eyeCalls,
        fields:[...root.querySelectorAll('input')].map(e=>({value:e.value,disabled:e.disabled})),
        buttons:[...root.querySelectorAll('button')].map(e=>({label:e.getAttribute('aria-label'),disabled:e.disabled})),
        radios:[...root.querySelectorAll('[role=radio]')].map(e=>({label:e.getAttribute('aria-label'),checked:e.getAttribute('aria-checked'),disabled:e.getAttribute('aria-disabled'),tabIndex:e.tabIndex})),
        recent:[...root.querySelectorAll('[role=button]')].map(e=>({label:e.getAttribute('aria-label'),disabled:e.getAttribute('aria-disabled'),tabIndex:e.tabIndex})),
        pointer:(()=>{const panel=root.querySelector('[role=menu]');
          if(!panel)return null;
          const area=panel.querySelector('[aria-label="Saturation and value"]');
          const r=area.getBoundingClientRect();
          const hit=document.elementFromPoint(r.left+r.width/2,r.top+r.height/2);
          return {events:getComputedStyle(panel).pointerEvents,
            opacity:getComputedStyle(panel).opacity,hitInside:panel.contains(hit)};
        })(),
        activeInside:root.contains(document.activeElement),
        rootRect:(()=>{const r=root.getBoundingClientRect();return[r.width,r.height]})(),
        inert:root.closest('[inert]')!==null||root.querySelector('[inert]')!==null};
    }''',
        args: [id],
      );

  List<Map<String, Object?>> flatten(pptr.AXNode node) => [
    {
      'role': node.role,
      'name': node.name,
      'value': node.value,
      'disabled': node.disabled,
    },
    for (final child in node.children) ...flatten(child),
  ];

  for (final theme in ['light', 'dark']) {
    test(
      'disabled inline keeps readable values without user actions $theme',
      () async {
        final page = await open(theme);
        final initial = await read(page, 'disabled');
        final ax = flatten(
          await page.accessibility.snapshot(
            root: await page.$('#picker-disabled'),
            interestingOnly: false,
          ),
        );
        await page.focus('#before-disabled');
        final stops = <Object?>[];
        for (var i = 0; i < 12; i++) {
          await page.keyboard.press(pptr.Key.tab);
          final stop = await page.evaluate<Map<String, dynamic>>(
            '''
()=>({
          id:document.activeElement?.id,
          inside:document.querySelector('#picker-disabled').contains(document.activeElement)})''',
          );
          stops.add(stop);
          if (stop['id'] == 'after-disabled') break;
        }
        final actions = <Object?>[];
        for (final selector in [
          '#picker-disabled $_eyeButton',
          '#picker-disabled [role=button]',
          '#picker-disabled [role=radio]:last-child',
        ]) {
          await page.focus(selector);
          for (final key in [pptr.Key.enter, pptr.Key.space]) {
            await page.keyboard.press(key);
            await frames(page);
            actions.add({
              'selector': selector,
              'key': '$key',
              'after': await read(page, 'disabled'),
            });
          }
        }
        for (final selector in [
          '#picker-disabled $_eyeButton',
          '#picker-disabled [role=button]',
          '#picker-disabled [role=radio]:last-child',
          '#picker-disabled [aria-label="Saturation and value"]',
          '#picker-disabled [role=slider]',
        ]) {
          await page.click(selector);
          await frames(page);
          actions.add({
            'pointer': selector,
            'after': await read(page, 'disabled'),
          });
        }
        await control(page, 'external-color');
        await control(page, 'external-mode');
        await control(page, 'external-history');
        final external = await read(page, 'disabled');
        for (final key in [pptr.Key.enter, pptr.Key.space]) {
          await page.focus('#picker-live $_eyeButton');
          await page.keyboard.press(key);
          await frames(page);
        }
        final positive = await read(page, 'live');
        final popover = await read(page, 'popover');
        record('$theme-disabled', {
          'initial': initial,
          'AX': ax,
          'tabStops': stops,
          'actions': actions,
          'external': external,
          'enabledPositive': positive,
          'disabledPopover': popover,
        });
        expect(initial['inert'], false);
        expect(initial['pointer'], {
          'events': 'none',
          'opacity': '1',
          'hitInside': false,
        });
        expect(
          ax.any((x) => x['role'] == 'textbox' && x['value'] == '#6750A4'),
          isTrue,
        );
        expect(
          ax.any((x) => x['role'] == 'radio' && x['name'] == 'RGB'),
          isTrue,
        );
        expect(stops.every((x) => (x! as Map)['inside'] == false), isTrue);
        expect(
          (initial['buttons'] as List).every(
            (x) => (x as Map)['disabled'] == true,
          ),
          isTrue,
        );
        expect(
          (initial['radios'] as List).every(
            (x) => (x as Map)['disabled'] == 'true',
          ),
          isTrue,
        );
        for (final action in actions) {
          final after = (action! as Map)['after'] as Map;
          expect(after['changes'], 0);
          expect(after['eyeCalls'], 0);
          expect(after['color'], '#6750A4');
          expect(((after['radios'] as List).first as Map)['checked'], 'true');
        }
        expect(((external['fields'] as List).first as Map)['value'], '#0000FF');
        expect(external['changes'], 0);
        expect(((external['radios'] as List).last as Map)['checked'], 'true');
        expect(
          ((external['recent'] as List).single as Map)['label'],
          'Recent color #00FF00',
        );
        expect(positive['changes'], 2);
        expect(positive['eyeCalls'], 2);
        expect(
          (popover['fields'] as List).every(
            (x) => (x as Map)['disabled'] == true,
          ),
          isTrue,
        );
        expect(errors, isEmpty);
        expect(requests, isEmpty);
      },
    );
  }

  test('enable transitions retain the actual input and picker State', () async {
    final page = await open('light');
    final before = await read(page, 'live');
    await page.evaluate<void>('''
()=>{
      window.liveRoot=document.querySelector('#picker-live');
      window.liveField=window.liveRoot.querySelector('input');
      window.liveField.focus();window.liveField.setSelectionRange(2,4);
    }''');
    await control(page, 'disable-live');
    final disabled = await read(page, 'live');
    await control(page, 'enable-live');
    final enabled = await read(page, 'live');
    final identity = await page.evaluate<Map<String, dynamic>>(
      '''
()=>({
      root:window.liveRoot===document.querySelector('#picker-live'),
      field:window.liveField===document.querySelector('#picker-live input'),
      selection:[window.liveField.selectionStart,window.liveField.selectionEnd]})''',
    );
    record('transitions', {
      'before': before,
      'disabled': disabled,
      'enabled': enabled,
      'identity': identity,
    });
    expect(disabled['state'], before['state']);
    expect(enabled['state'], before['state']);
    expect(disabled['activeInside'], false);
    expect(disabled['color'], before['color']);
    expect(enabled['color'], before['color']);
    expect(disabled['changes'], 0);
    expect(enabled['changes'], 0);
    expect(identity, {
      'root': true,
      'field': true,
      'selection': [2, 4],
    });
    await page.focus('#picker-live $_eyeButton');
    await page.keyboard.press(pptr.Key.enter);
    await frames(page);
    expect((await read(page, 'live'))['changes'], 1);
    expect(errors, isEmpty);
    expect(requests, isEmpty);
  });

  test('pending host result is ignored after disable or disposal', () async {
    final page = await open('light', deferred: true);
    await page.focus('#picker-live $_eyeButton');
    await page.keyboard.press(pptr.Key.enter);
    await frames(page);
    expect((await read(page, 'live'))['eyeCalls'], 1);
    await control(page, 'disable-live');
    await page.evaluate<void>(
      '''
()=>window.eyePending.shift()({sRGBHex:'#00FF00'})''',
    );
    await frames(page);
    final disabled = await read(page, 'live');
    await control(page, 'enable-live');
    await page.focus('#picker-live $_eyeButton');
    await page.keyboard.press(pptr.Key.enter);
    await frames(page);
    await control(page, 'remove-live');
    await page.evaluate<void>(
      '''
()=>window.eyePending.shift()({sRGBHex:'#FF0000'})''',
    );
    await frames(page);
    final disposed = await page.evaluate<Map<String, dynamic>>(
      '''
()=>({
      state:JSON.parse(window.readDisabledPickerStates()).live,
      remaining:document.querySelector('#picker-live')!==null,
      commits:Number(document.querySelector('[data-disabled-probe]').dataset.totalCommits)})''',
    );
    record('pending', {'disabledResult': disabled, 'disposed': disposed});
    expect(disabled['changes'], 0);
    expect(disabled['color'], '#6750A4');
    expect(disposed, {'state': null, 'remaining': false, 'commits': 0});
    expect(errors, isEmpty);
    expect(requests, isEmpty);
  });
}
