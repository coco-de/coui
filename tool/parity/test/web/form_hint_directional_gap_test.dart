@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';

void main() {
  late Directory directory;
  late File html;
  pptr.Browser? browser;
  late pptr.Page page;
  final errors = <String>[];

  Future<void> open(String theme) async {
    await page.goto(
      html.uri.replace(queryParameters: {'theme': theme}).toString(),
    );
    await page.waitForSelector('#cases');
    await page.evaluate<void>('() => document.fonts.ready');
    await page.evaluate<void>(
      '() => new Promise(done => requestAnimationFrame(() => '
      'requestAnimationFrame(done)))',
    );
  }

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-form-hint-gap-');
    final entry = File('${directory.path}/entry.dart')
      ..writeAsStringSync(_client);
    final js = File('${directory.path}/entry.js');
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '-Djaspr.flags.release=true',
      '--packages=${File('.dart_tool/package_config.json').absolute.path}',
      entry.path,
      '-o',
      js.path,
    ]);
    expect(
      compiled.exitCode,
      0,
      reason: '${compiled.stdout}\n${compiled.stderr}',
    );
    html = File('${directory.path}/index.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml:
              '<div id="app"></div><script>${js.readAsStringSync()}</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
        ),
      );
    browser = await launchCaptureBrowser(width: 800, height: 1200);
  });
  setUp(() async {
    errors.clear();
    page = await browser!.newPage();
    page.onError.listen((error) => errors.add('$error'));
  });
  tearDown(() async {
    await page.close();
    expect(errors, isEmpty);
  });
  tearDownAll(() async {
    await browser?.close();
    directory.deleteSync(recursive: true);
  });

  for (final kind in ['form', 'hint']) {
    test(
      '$kind keeps the Core gap between its children in LTR and RTL',
      () async {
        for (final theme in ['light', 'dark']) {
          await open(theme);
          final rows = await page.evaluate<List<dynamic>>(
            _measure,
            args: [kind],
          );
          expect(rows, hasLength(8));
          for (final value in rows) {
            final row = value as Map<String, dynamic>;
            final reason = '$theme/$row';
            expect(row['theme'], theme, reason: reason);
            expect(row['direction'], row['requestedDirection'], reason: reason);
            // Measure the actual caller child and marker/icon edges. A
            // physical margin on the wrong edge yields zero in RTL.
            expect(row['gap'], row['requestedGap'], reason: reason);
            expect(row['childCount'], 2, reason: reason);
            expect(row['callerClass'], isTrue, reason: reason);
            expect(row['callerAttribute'], 'kept', reason: reason);
            expect(
              row['callerCss'],
              row['rawCss'] == true ? 'kept' : '',
              reason: reason,
            );
            expect(
              row['cursor'],
              row['rawCss'] == true
                  ? 'crosshair'
                  : kind == 'form'
                  ? 'default'
                  : 'auto',
              reason: reason,
            );
            expect(row['ariaHidden'], 'true', reason: reason);
            expect(row['tag'], kind == 'form' ? 'LABEL' : 'P', reason: reason);
            expect(
              row['role'],
              kind == 'hint' ? 'alert' : null,
              reason: reason,
            );
          }
        }
      },
    );
  }

  test('required, enabled and visible props retain their branches', () async {
    for (final theme in ['light', 'dark']) {
      await open(theme);
      for (final direction in ['ltr', 'rtl']) {
        final state = await page.evaluate<Map<String, dynamic>>(
          '''
direction => {
 const plain=document.getElementById('plain-'+direction);
 const disabled=document.getElementById('disabled-'+direction);
 const a=disabled.firstElementChild.getBoundingClientRect();
 const b=disabled.lastElementChild.getBoundingClientRect();
 return {plainChildren:plain.children.length,
  hidden:document.getElementById('hidden-'+direction)===null,
  disabledGap:direction==='rtl'?a.left-b.right:b.left-a.right,
  color:getComputedStyle(disabled).color,
  markerColor:getComputedStyle(disabled.lastElementChild).color};
}
''',
          args: [direction],
        );
        expect(state['plainChildren'], 1);
        expect(state['hidden'], isTrue);
        expect(state['disabledGap'], 4);
        expect(state['markerColor'], state['color']);
      }
    }
  });
}

const _measure = '''
kind => [...document.querySelectorAll('[data-case="'+kind+'"]')].map(root=>{
 const leading=document.getElementById('leading-'+root.id);
 const trailing=kind==='form'?root.lastElementChild:document.getElementById('trailing-'+root.id);
 const carrier=kind==='form'?trailing:leading.parentElement;
 const a=leading.getBoundingClientRect(), b=trailing.getBoundingClientRect();
 const s=getComputedStyle(root),rtl=s.direction==='rtl';
 return {theme:document.documentElement.dataset.theme,
  requestedDirection:root.dataset.direction,direction:s.direction,
  requestedGap:Number(root.dataset.gap),gap:rtl?a.left-b.right:b.left-a.right,
  childCount:root.children.length,tag:root.tagName,role:root.getAttribute('role'),
  callerClass:root.classList.contains('caller-gap'),callerAttribute:root.dataset.caller,
  rawCss:root.dataset.css==='true',callerCss:s.getPropertyValue('--caller-gap-control').trim(),
  cursor:s.cursor,ariaHidden:carrier.getAttribute('aria-hidden')};
})
''';

const _client = r'''
import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:jaspr/client.dart' as client;
Component box(String id,int width)=>span([],id:id,styles:Styles(raw:{
 'width':'${width}px','height':'10px','background':'#4080c0'}));
void main(){client.Jaspr.initializeApp();final theme=Uri.base.queryParameters['theme']??'light';
 CoUIThemeController.setTheme(theme);
 final cases=<Component>[];
 for(final direction in ['ltr','rtl'])for(final customGap in [false,true])
 for(final rawCss in [false,true])for(final kind in ['form','hint']){
  final name='$kind-$direction-$customGap-$rawCss';
  final gap=customGap?const CoreGapStyle(size:9.25):null;
  final css=rawCss?const Styles(raw:{'cursor':'crosshair','--caller-gap-control':'kept'}):null;
  final attrs={'dir':direction,'data-case':kind,'data-caller':'kept',
   'data-direction':direction,'data-gap':customGap?'9.25':'4','data-css':'$rawCss'};
  cases.add(div([kind=='form'
   ?FormLabel(id:name,classes:'caller-gap',css:css,attributes:attrs,
    label:box('leading-$name',20),isRequired:true,
    formLabelStyle:CoreFormLabelStyle(requiredIndicatorGapStyle:gap))
   :ValidatorHint(id:name,classes:'caller-gap',css:css,attributes:attrs,
    icon:box('leading-$name',8),message:box('trailing-$name',20),
    validatorHintStyle:CoreValidatorHintStyle(iconLabelGapStyle:gap))],
   styles:const Styles(raw:{'width':'400px'})));
 }
 for(final direction in ['ltr','rtl']){
  cases.add(div([
   FormLabel(id:'plain-$direction',attributes:{'dir':direction},label:box('plain-label-$direction',20)),
   FormLabel(id:'disabled-$direction',attributes:{'dir':direction},
    label:box('disabled-label-$direction',20),isRequired:true,enabled:false),
   ValidatorHint(id:'hidden-$direction',visible:false,message:box('hidden-message-$direction',20)),
  ]));
 }
 client.runApp(Component.fragment([
  Document.html(attributes:{'data-theme':theme}),Style(styles:docsContentTheme().styles),
  CoUIWeb(theme:ThemeData.coui,child:div(cases,id:'cases')),
 ]),attachTo:'#app');
}
''';
