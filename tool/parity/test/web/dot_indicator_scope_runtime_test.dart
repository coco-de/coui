@Timeout(Duration(minutes: 4))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/protocol/emulation.dart' as cdp;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/dot_indicator_scope_cases.dart';

void main() {
  late Directory directory;
  late HttpServer http;
  late pptr.Browser browser;
  final errors = <Object>[];
  final records = <Map<String, dynamic>>[];
  const active = '[role="tab"][aria-current="true"] > div';
  const inactive = '[role="tab"]:not([aria-current]) > div';

  Future<void> frames(pptr.Page page) => page.evaluate<void>(
    '() => new Promise(done => requestAnimationFrame(() => '
    'requestAnimationFrame(done)))',
  );

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-dot-runtime-');
    final fixture = File(
      'tool/parity/test/fixtures/dot_indicator_scope_cases.dart',
    ).absolute.uri;
    final entry = File('${directory.path}/client.dart')
      ..writeAsStringSync('''
import 'package:coui_web/coui_web.dart';
import '$fixture';
void main()=>runApp(dotIndicatorScopeCases(dark:Uri.base.queryParameters['dark']=='true'),attachTo:'#dot-app');
''');
    final config = (await Isolate.packageConfig)!;
    final compile = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '-Djaspr.flags.release=true',
      '--packages=${config.toFilePath()}',
      entry.path,
      '-o',
      '${directory.path}/client.js',
    ]);
    expect(compile.exitCode, 0, reason: '${compile.stdout}\n${compile.stderr}');
    for (final theme in ['light', 'dark']) {
      final body = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          div(id: 'dot-app', [dotIndicatorScopeCases(dark: theme == 'dark')]),
        ]),
      );
      File('${directory.path}/$theme.html').writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          theme: theme,
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml:
              '<style>${buildLocalFontFaceCss()} .caller-shadow [aria-current="true"]>div{box-shadow:0 0 3px rgb(40,50,60);}</style>',
        ),
      );
    }
    http = (await HttpServer.bind(InternetAddress.loopbackIPv4, 0))
      ..listen((request) async {
        final file = File('${directory.path}/${request.uri.path.substring(1)}');
        request.response.headers.contentType = request.uri.path.endsWith('.js')
            ? ContentType('application', 'javascript')
            : ContentType.html;
        if (file.existsSync()) {
          request.response.add(file.readAsBytesSync());
        } else {
          request.response.statusCode = 404;
        }
        await request.response.close();
      });
    browser = await launchCaptureBrowser(
      width: 1000,
      height: 1000,
      executablePath: Platform.environment['PUPPETEER_EXECUTABLE_PATH'],
    );
  });
  tearDownAll(() async {
    await browser.close();
    await http.close(force: true);
    File('${directory.path}/observed.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'records': records,
        'errors': errors.map((e) => '$e').toList(),
        'browserCloseAwaited': true,
        'httpClosed': true,
      }),
    );
    stderr.writeln('Dot runtime proof: ${directory.path}');
    expect(errors, isEmpty);
  });

  Future<pptr.Page> open(String theme) async {
    final page = await browser.newPage();
    page.onError.listen(errors.add);
    await page.goto(
      'http://127.0.0.1:${http.port}/$theme.html?dark=${theme == 'dark'}',
    );
    await page.evaluate<void>('()=>document.fonts.ready');
    await page.addScriptTag(url: 'http://127.0.0.1:${http.port}/client.js');
    await page.click('#rebuild');
    await page.waitForFunction(
      "Number(document.querySelector('#scope-ready').dataset.builds)>1",
    );
    await frames(page);
    return page;
  }

  Future<Map<String, dynamic>> root(
    pptr.Page page,
    String name,
  ) async => (await page.$eval<Map<String, dynamic>>(
    '#$name [data-caller]',
    '''e=>({id:e.id,caller:e.dataset.caller,classes:e.className,cursor:getComputedStyle(e).cursor,tabIndex:e.tabIndex,focused:document.activeElement===e})''',
  ))!;
  Future<Map<String, dynamic>> paint(
    pptr.Page page,
    String selector,
  ) async => (await page.$eval<Map<String, dynamic>>(
    selector,
    '''e=>{const s=getComputedStyle(e);return {border:s.borderColor,borderStyle:s.borderStyle,borderWidth:s.borderWidth,outline:s.outlineColor,width:s.outlineWidth,offset:s.outlineOffset,style:s.outlineStyle,shadow:s.boxShadow,classes:e.className,declaredColor:s.getPropertyValue('--co-dot-focus-outline-color'),declaredWidth:s.getPropertyValue('--co-dot-focus-outline-width'),declaredOffset:s.getPropertyValue('--co-dot-focus-outline-offset')};}''',
  ))!;
  Future<void> keyboardFocus(pptr.Page page, String owner) async {
    // Explicit focus with a real key preserves the browser's focus-visible
    // path.
    await page.keyboard.press(pptr.Key.tab);
    await page.focus('#$owner [data-caller]');
    await page.waitForFunction(
      '''
(name)=>document.querySelector("#"+name+" [data-caller]")
  .matches(":focus-visible")
''',
      args: [owner],
    );
    await frames(page);
  }

  for (final theme in ['light', 'dark']) {
    test(
      '$theme client owners keep local hover through rebuild/reorder/remount',
      () async {
        final page = await open(theme);
        try {
          await page.evaluate<void>('''
()=>window.__dotInitialNode=document.querySelector('#shared-a [data-caller]')
''');
          Future<Map<String, dynamic>> lifetime() => page.evaluate('''
()=>{const e=document.querySelector('#shared-a [data-caller]');
const dot=e?.querySelector('[role=tab]:not([aria-current])>div');
return {present:!!e,oldConnected:window.__dotInitialNode.isConnected,
sameNode:e===window.__dotInitialNode,
legacyClass:dot&&[...dot.classList].find(x=>x.startsWith('co-dot-h-'))};}
''');
          final initial = await lifetime();
          var mountActions = 0;
          for (final action in [
            'initial',
            'rebuild',
            'reorder',
            'mount',
            'mount',
          ]) {
            final beforeBuilds = await page.evaluate<num>(
              "Number(document.querySelector('#scope-ready').dataset.builds)",
            );
            if (action != 'initial') {
              await page.click(action == 'mount' ? 'button#mount' : '#$action');
              await page.waitForFunction(
                '''
before=>Number(document.querySelector('#scope-ready').dataset.builds)>before
''',
                args: [beforeBuilds],
              );
            }
            await frames(page);
            if (action == 'mount') mountActions++;
            final observedLifetime = await lifetime();
            if (mountActions == 1) {
              expect(observedLifetime['present'], isFalse);
              expect(observedLifetime['oldConnected'], isFalse);
            } else {
              expect(observedLifetime['present'], isTrue);
              expect(observedLifetime['sameNode'], mountActions == 0);
              expect(observedLifetime['oldConnected'], mountActions == 0);
              expect(observedLifetime['legacyClass'], initial['legacyClass']);
            }
            records.add({
              'theme': theme,
              'action': action,
              'lifetime': observedLifetime,
              'beforeBuilds': beforeBuilds,
            });
            for (final name in ['equal-a', 'shared-a']) {
              if ((await page.$$('#$name')).isEmpty) continue;
              await page.hover('#$name $inactive');
              await frames(page);
              final observed = await paint(page, '#$name $inactive');
              expect(observed['border'], 'rgb(180, 20, 40)');
              expect(observed['borderStyle'], 'solid');
              expect(observed['borderWidth'], '2px');
              final owner = await root(page, name);
              expect(owner['caller'], 'kept');
              expect(owner['cursor'], 'crosshair');
              expect(owner['classes'], contains('caller-dot-root'));
              records.add({
                'theme': theme,
                'action': action,
                'owner': name,
                'paint': observed,
              });
            }
          }
          expect(mountActions, 2);
          await keyboardFocus(page, 'unique-a');
          final referenceRing = await paint(page, '#unique-a $active');
          await keyboardFocus(page, 'shared-a');
          final remountedRing = await paint(page, '#shared-a $active');
          for (final field in [
            'outline',
            'width',
            'offset',
            'declaredColor',
            'declaredWidth',
            'declaredOffset',
          ]) {
            expect(remountedRing[field], referenceRing[field]);
          }
          records.add({
            'theme': theme,
            'case': 'remounted-focus',
            'reference': referenceRing,
            'observed': remountedRing,
          });
          await page.click('#equal-a [role="tab"]:not([aria-current])');
          await page.waitForFunction(
            "document.querySelector('#scope-ready').dataset.lastIndex==='1'",
          );
          expect((await root(page, 'caller-special'))['id'], 'dot:user.a');
        } finally {
          await page.close();
        }
      },
    );

    test(
      '$theme raw ring geometry and caller shadow preserve the band boundary',
      () async {
        final page = await open(theme);
        try {
          await keyboardFocus(page, 'unique-a');
          final reference = await paint(page, '#unique-a $active');
          for (final name in [
            'unique-a',
            'shared-a',
            'equal-a',
            'band-a',
            'mixed-band-a',
            'mixed-plain-a',
          ]) {
            await keyboardFocus(page, name);
            final observed = await paint(page, '#$name $active');
            expect(observed['declaredWidth'], '2.5px');
            expect(observed['declaredOffset'], '3.75px');
            expect(observed['width'], reference['width']);
            expect(observed['offset'], reference['offset']);
            expect(observed['outline'], reference['outline']);
            expect(
              observed['declaredColor'],
              const CoreColor(0xffb41428).scaleAlpha(0.625).toValue(),
            );
            if (name == 'band-a' || name == 'mixed-band-a') {
              expect(observed['shadow'], contains('rgb(119, 136, 153)'));
            } else {
              expect(observed['shadow'], 'rgb(40, 50, 60) 0px 0px 3px 0px');
            }
            records.add({
              'theme': theme,
              'focusOwner': name,
              'paint': observed,
            });
          }
          await keyboardFocus(page, 'mixed-band-b');
          final mixedPlain = await paint(page, '#mixed-band-b $active');
          expect(mixedPlain['shadow'], 'rgb(40, 50, 60) 0px 0px 3px 0px');
          expect(
            mixedPlain['declaredColor'],
            const CoreColor(0xff1428b4).scaleAlpha(0.5).toValue(),
          );
          records.add({'theme': theme, 'mixedBandlessB': mixedPlain});
          await keyboardFocus(page, 'token');
          final token = await paint(page, '#token $active');
          expect(token['classes'], contains('group-focus-visible:outline-'));
          expect(token['classes'], isNot(contains('co-dot-raw-ring')));
          await page.devTools.emulation.setEmulatedMedia(
            features: [
              cdp.MediaFeature(name: 'forced-colors', value: 'active'),
            ],
          );
          await page.waitForFunction(
            "matchMedia('(forced-colors: active)').matches",
          );
          await keyboardFocus(page, 'equal-a');
          final forced = await paint(page, '#equal-a $active');
          expect(forced['style'], 'none');
          records.add({'theme': theme, 'forcedColors': true, 'paint': forced});
        } finally {
          await page.close();
        }
      },
    );

    test('$theme hit partition stays disjoint across axes and RTL', () async {
      final page = await open(theme);
      try {
        for (final dir in ['ltr', 'rtl']) {
          if (dir == 'rtl') await page.click('#rtl');
          await frames(page);
          for (final name in [
            'equal-a',
            'equal-b',
            'vertical-a',
            'vertical-b',
          ]) {
            await page.$eval<void>(
              '#$name',
              'e=>e.scrollIntoView({block:"center"})',
            );
            final hits = (await page.$eval<List<dynamic>>(
              '#$name',
              '''outer=>[...outer.querySelectorAll('[role="tab"]>div')].map((dot,i)=>{const r=dot.getBoundingClientRect(),hit=document.elementFromPoint(r.x+r.width/2,r.y+r.height/2);return {index:i,hit:hit===dot||dot.contains(hit),width:r.width,height:r.height,before:getComputedStyle(dot,'::after').content};})''',
            ))!;
            expect(hits.length, 3);
            for (final h in hits) {
              expect((h as Map<String, dynamic>)['hit'], true);
              expect(h['before'], '""');
            }
            final partitions = (await page.$eval<List<dynamic>>(
              '#$name',
              '''outer=>{const dots=[...outer.querySelectorAll('[role="tab"]>div')],vertical=outer.id.startsWith('vertical'),at=(x,y)=>{const hit=document.elementFromPoint(x,y);return dots.findIndex(e=>e===hit||e.contains(hit));};return dots.slice(0,-1).map((dot,i)=>{const a=dot.getBoundingClientRect(),b=dots[i+1].getBoundingClientRect(),forward=vertical||b.x>a.x,start=vertical?a.bottom:forward?a.right:a.left,end=vertical?b.top:forward?b.left:b.right,near=start+(end-start)/4,far=start+(end-start)*3/4,cross=vertical?a.x+a.width/2:a.y+a.height/2;return {index:i,near:vertical?at(cross,near):at(near,cross),far:vertical?at(cross,far):at(far,cross)};});}''',
            ))!;
            for (final p in partitions) {
              final part = p as Map<String, dynamic>;
              expect(part['near'], isIn([-1, part['index']]));
              expect(part['far'], isIn([-1, (part['index'] as int) + 1]));
            }
            records
              ..add({
                'theme': theme,
                'direction': dir,
                'partitionOwner': name,
                'partitions': partitions,
              })
              ..add({
                'theme': theme,
                'direction': dir,
                'hitOwner': name,
                'hits': hits,
              });
          }
        }
        expect(await page.$$('#passive .coui-touch-target'), isEmpty);
        expect(await page.$$('#empty [aria-hidden="true"]'), isNotEmpty);
      } finally {
        await page.close();
      }
    });
  }
}
