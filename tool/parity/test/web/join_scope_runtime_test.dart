@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:image/image.dart' as image;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/join_scope_cases.dart';

List<Map<String, dynamic>> items(Map<String, dynamic> row) =>
    (row['items'] as List<dynamic>).cast<Map<String, dynamic>>();

void main() {
  late Directory directory;
  late HttpServer http;
  late pptr.Browser browser;
  final records = <Map<String, dynamic>>[];
  final errors = <Object>[];
  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-join-runtime-');
    final fixture = File(
      'tool/parity/test/fixtures/join_scope_cases.dart',
    ).absolute.uri;
    final entry = File('${directory.path}/client.dart')
      ..writeAsStringSync('''
import 'package:coui_web/coui_web.dart';
import '$fixture';
void main()=>runApp(joinScopeCases(),attachTo:'#join-app');''');
    final config = (await Isolate.packageConfig)!;
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '-Djaspr.flags.release=true',
      '--packages=${config.toFilePath()}',
      entry.path,
      '-o',
      '${directory.path}/client.js',
    ]);
    expect(
      compiled.exitCode,
      0,
      reason: '${compiled.stdout}\n${compiled.stderr}',
    );
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        div(id: 'join-app', [joinScopeCases()]),
      ]),
    );
    for (final theme in ['light', 'dark']) {
      File('${directory.path}/$theme.html').writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          theme: theme,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
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
    stderr.writeln('Join runtime proof: ${directory.path}');
    expect(errors, isEmpty);
  });
  Future<pptr.Page> open(String theme) async {
    final page = await browser.newPage();
    page.onError.listen(errors.add);
    await page.goto('http://127.0.0.1:${http.port}/$theme.html');
    await page.evaluate<void>('()=>document.fonts.ready');
    await page.addScriptTag(url: 'http://127.0.0.1:${http.port}/client.js');
    await page.click('#rebuild');
    await page.waitForFunction(
      "Number(document.querySelector('#join-ready').dataset.builds)>1",
    );
    return page;
  }

  Future<Map<String, dynamic>> read(pptr.Page page, String owner) =>
      page.evaluate(
        '''
owner=>{
const root=document.querySelector('#'+owner+' > [data-join-case]');
const wrappers=[...root.children].filter(e=>e.tagName==='DIV');
return {id:root.id,
scope:[...root.classList].find(x=>x.startsWith('co-join-rule-')),

classes:root.className,
cursor:getComputedStyle(root).cursor,
caller:root.dataset.joinCase,

firstTag:root.firstElementChild.tagName,
childNodes:root.children.length,
items:wrappers.map(w=>{
 const e=w.firstElementChild,
s=getComputedStyle(e),
ws=getComputedStyle(w);
return {
 radius:[s.borderTopLeftRadius,
s.borderTopRightRadius,
s.borderBottomRightRadius,
s.borderBottomLeftRadius],

 minWidth:s.minWidth,
minHeight:s.minHeight,
overflow:ws.overflow,
zIndex:ws.zIndex,

 position:ws.position,outlineColor:s.outlineColor,outlineWidth:s.outlineWidth,
 focused:e.matches(':focus-visible'),boxSizing:s.boxSizing};})};}''',
        args: [owner],
      );

  for (final theme in ['light', 'dark']) {
    test(
      '$theme O2 owners survive rebuild/reorder/remount independently',
      () async {
        final page = await open(theme);
        try {
          final initialA = await read(page, 'shared-a');
          var remounted = false;
          var mountActions = 0;
          for (final action in [
            'initial',
            'rebuild',
            'reorder',
            'mount',
            'mount',
          ]) {
            final beforeBuilds = await page.evaluate<num>(
              "Number(document.querySelector('#join-ready').dataset.builds)",
            );
            if (action != 'initial') {
              await page.click(action == 'mount' ? 'button#mount' : '#$action');
              await page.waitForFunction(
                '''
before=>Number(document.querySelector('#join-ready').dataset.builds)>before
''',
                args: [beforeBuilds],
              );
            }
            if (action == 'mount') mountActions++;
            final present = (await page.$$('#shared-a')).isNotEmpty;
            if (mountActions == 1) {
              expect(present, isFalse, reason: 'the first toggle removes A');
              remounted = true;
              records.add({
                'theme': theme,
                'action': action,
                'present': false,
                'beforeBuilds': beforeBuilds,
                'b': await read(page, 'shared-b'),
              });
              continue;
            }
            expect(present, isTrue);
            final a = await read(page, 'shared-a');
            final b = await read(page, 'shared-b');
            final uniqueA = await read(page, 'unique-a');
            final uniqueB = await read(page, 'unique-b');
            expect(a['items'], uniqueA['items']);
            expect(b['items'], uniqueB['items']);
            expect(a['id'], b['id']);
            expect(a['id'], initialA['id']);
            expect(a['scope'], isNot(b['scope']));
            expect(
              a['scope'],
              remounted ? isNot(initialA['scope']) : initialA['scope'],
            );
            records.add({
              'theme': theme,
              'action': action,
              'present': true,
              'beforeBuilds': beforeBuilds,
              'a': a,
              'b': b,
            });
          }
          expect(mountActions, 2);
          expect(remounted, isTrue);
        } finally {
          await page.close();
        }
      },
    );
    test(
      '$theme counts/cross-axis/nesting/caller contracts stay intact',
      () async {
        final page = await open(theme);
        try {
          for (final direction in ['h', 'v']) {
            for (final count in [0, 1, 2, 3]) {
              final row = await read(page, 'count-$direction-$count');
              expect(row['firstTag'], 'STYLE');
              expect(row['childNodes'], count + 1);
              expect(row['items'], hasLength(count));
              records.add({
                'theme': theme,
                'case': 'count-$direction-$count',
                'observed': row,
              });
            }
          }
          final h = await read(page, 'minimum-h');
          final v = await read(page, 'minimum-v');
          for (final e in items(h)) {
            expect(e['minWidth'], '73px');
            expect(e['minHeight'], '100%');
          }
          for (final e in items(v)) {
            expect(e['minHeight'], '27px');
            expect(e['minWidth'], '100%');
          }
          final caller = await read(page, 'caller');
          expect(caller['id'], 'caller-join');
          expect(caller['cursor'], 'crosshair');
          expect(caller['classes'], contains('caller-join-root'));
          expect(caller['caller'], 'kept');
          expect(
            (items(caller).first['radius'] as List<dynamic>)[0],
            '${CoreRadius.radius20.toInt()}px',
            reason:
                'same-specificity authored rule after Join must retain '
                'its priority',
          );
          await page.click('#caller-join > div:first-of-type > *');
          await page.waitForFunction(
            '''
()=>{const ready=document.querySelector('#join-ready');
return Number(ready.dataset.presses)>0&&
  Number(ready.dataset.rootClicks)>0;}''',
          );
          final nested = await page.evaluate<Map<String, dynamic>>(
            '''
()=>{
 const e=document.getElementById('nested-inner');
return {radius:getComputedStyle(e).borderRadius,

 children:[...e.children].filter(x=>x.tagName==='DIV').map(w=>{const s=getComputedStyle(w.firstElementChild);
return [s.borderTopLeftRadius,
s.borderTopRightRadius,
s.borderBottomRightRadius,
s.borderBottomLeftRadius]})};
}''',
          );
          final large = '${CoreRadius.radius16.toInt()}px';
          expect(nested['children'], [
            [large, large, '0px', '0px'],
            ['0px', '0px', large, large],
          ]);
          final special = await read(page, 'special');
          expect(special['id'], 'join:user.a');
          expect(
            (items(special).first['radius'] as List<dynamic>)[1],
            isNot('0px'),
            reason:
                'existing unescaped punctuation ID selector '
                'remains unsupported',
          );
          records.add({
            'theme': theme,
            'case': 'caller-and-nested',
            'h': h,
            'v': v,
            'caller': caller,
            'nested': nested,
            'specialKnownNegative': special,
          });
        } finally {
          await page.close();
        }
      },
    );
    test(
      '$theme focused middle outline actually paints outside its wrapper',
      () async {
        final page = await open(theme);
        try {
          const selector =
              '#focus-probe [data-join-case] > div:nth-of-type(2) > *';
          await page.evaluate<void>(
            '''
()=>document.getElementById('focus-probe')
  .scrollIntoView({block:'center'})''',
          );
          await page.keyboard.press(pptr.Key.tab);
          await page.focus(selector);
          await page.waitForFunction(
            '(s)=>document.querySelector(s).matches(":focus-visible")',
            args: [selector],
          );
          await page.waitForFunction(
            '''
(s,
color)=>{const e=document.querySelector(s);
return getComputedStyle(e).outlineColor===color&&!e.getAnimations().some(a=>a.constructor.name==='CSSTransition'&&a.playState==='running');
}''',
            args: [selector, const CoreColor(0xffb41428).toValue()],
          );
          final row = await read(page, 'focus-probe');
          final middle = items(row)[1];
          expect(middle['radius'], ['0px', '0px', '0px', '0px']);
          expect(middle['overflow'], 'visible');
          expect(middle['position'], 'relative');
          expect(middle['zIndex'], '1');
          final geometry = await page.evaluate<Map<String, dynamic>>(
            '''
s=>{const e=document.querySelector(s),
r=e.getBoundingClientRect(),
host=document.getElementById('focus-probe').getBoundingClientRect(),
cs=getComputedStyle(e),
width=parseFloat(cs.outlineWidth),
offset=parseFloat(cs.outlineOffset);
return {clip:{x:host.x+scrollX,
y:host.y+scrollY,
width:host.width,
height:host.height},
sample:{x:r.x-host.x-offset-width/2,
y:r.y-host.y+r.height/2},
color:cs.outlineColor,
width,
offset};
}''',
            args: [selector],
          );
          final c = geometry['clip'] as Map;
          final bytes = await page.screenshot(
            clip: Rectangle(
              c['x'] as num,
              c['y'] as num,
              c['width'] as num,
              c['height'] as num,
            ),
          );
          File('${directory.path}/focus-$theme.png').writeAsBytesSync(bytes);
          final decoded = image.decodePng(bytes)!;
          final point = geometry['sample'] as Map<String, dynamic>;
          final pixel = decoded.getPixel(
            (point['x'] as num).floor(),
            (point['y'] as num).floor(),
          );
          final expected = RegExp(r'\d+')
              .allMatches(geometry['color'] as String)
              .map((m) => int.parse(m.group(0)!))
              .toList();
          records.add({
            'theme': theme,
            'case': 'actual-outline-paint',
            'observed': row,
            'geometry': geometry,
            'sampleRGBA': [
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              pixel.a.toInt(),
            ],
          });
          expect([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()], expected);
        } finally {
          await page.close();
        }
      },
    );
  }
}
