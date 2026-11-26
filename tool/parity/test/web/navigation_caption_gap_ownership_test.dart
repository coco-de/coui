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

  Future<void> settle() => page.evaluate<void>(
    '() => new Promise(done => requestAnimationFrame(() => '
    'requestAnimationFrame(() => requestAnimationFrame(done))))',
  );

  Future<void> open(Map<String, String> query) async {
    await page.goto(html.uri.replace(queryParameters: query).toString());
    await page.waitForSelector(r'#case-nav [id$="-label"]');
    await page.evaluate<void>('() => document.fonts.ready');
    await settle();
  }

  Future<Map<String, dynamic>> measure() =>
      page.evaluate<Map<String, dynamic>>(_measure);

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-caption-gap-');
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
              '<script>window.scopeEvents=[];window.recordSelection=i=>scopeEvents.push(i);</script>'
              '<div id="app"></div><script>${js.readAsStringSync()}</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
          animationFreezeCss: '',
        ),
      );
    browser = await launchCaptureBrowser(width: 900, height: 700);
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

  test(
    'the caption owns the requested gap on each side, open and folded',
    () async {
      for (final theme in ['light', 'dark']) {
        for (final position in ['bottom', 'top', 'start', 'end']) {
          for (final gap in [4, 11.25]) {
            for (final folded in [false, true]) {
              final reason = '$theme/$position/$gap/$folded';
              await open({
                'theme': theme,
                'position': position,
                'gap': '$gap',
                'folded': '$folded',
              });
              final actual = await measure();
              expect(actual['theme'], theme, reason: reason);
              expect(actual['callerClass'], isTrue, reason: reason);
              expect(actual['rootGap'], '37px', reason: reason);
              expect(actual['ancestorGap'], '39px', reason: reason);
              // Only the fold owns this spacing. The outer flex has no
              // second spacing declaration, including a zero-valued one.
              expect(actual['innerInlineGap'], isEmpty, reason: reason);
              if (folded) {
                expect(actual['foldExtent'], 0, reason: reason);
                expect(actual['foldOpacity'], '0', reason: reason);
              } else {
                expect(
                  (actual['foldExtent'] as num) -
                      (actual['labelExtent'] as num),
                  gap,
                  reason: reason,
                );
                expect(actual['foldOpacity'], '1', reason: reason);
              }
            }
          }
        }
      }
    },
  );

  test('onScroll folds and returns the same caption and destination', () async {
    for (final theme in ['light', 'dark']) {
      await open({'theme': theme, 'kind': 'scroll', 'gap': '11.25'});
      final initial = await measure();
      expect(initial['foldExtent'], greaterThan(initial['labelExtent'] as num));
      await page.evaluate<void>(r'''
() => {
 window.savedRoot=document.getElementById('case-nav');
 window.savedLabel=savedRoot.querySelector('[id$="-label"]');
 window.savedDestination=savedRoot.querySelector('[data-coui-nav-index="0"]');
}
''');
      for (final top in [6, 60]) {
        await page.evaluate<void>(
          'top => document.getElementById("viewport").scrollTop=top',
          args: [top],
        );
        await settle();
      }
      await page.waitForFunction(r'''
(() => {
 const n=document.getElementById('case-nav');
 const l=n.querySelector('[id$="-label"]');
 return n.hasAttribute('data-coui-navigation-compact')&&
  l.parentElement.parentElement.getBoundingClientRect().height===0&&
  getComputedStyle(l.parentElement.parentElement).opacity==='0';
})()
''');
      final compact = await measure();
      expect(compact['foldExtent'], 0);
      expect(compact['innerInlineGap'], isEmpty);
      expect(compact['rootGap'], '37px');
      await page.evaluate<void>(
        '() => document.getElementById("viewport").scrollTop=0',
      );
      await page.waitForFunction(r'''
(() => {
 const n=document.getElementById('case-nav');
 const l=n.querySelector('[id$="-label"]');
 const f=l.parentElement.parentElement;
 return !n.hasAttribute('data-coui-navigation-compact')&&
  getComputedStyle(f).opacity==='1';
})()
''');
      await settle();
      final returned = await measure();
      expect(returned['foldExtent'], initial['foldExtent']);
      expect(returned['labelExtent'], initial['labelExtent']);
      expect(returned['rootGap'], '37px');
      expect(returned['ancestorGap'], '39px');
      expect(
        await page.evaluate<bool>(r'''
() => savedRoot===document.getElementById('case-nav')&&
 savedLabel===savedRoot.querySelector('[id$="-label"]')&&
 savedDestination===savedRoot.querySelector('[data-coui-nav-index="0"]')
'''),
        isTrue,
      );
      await page.click('#case-nav [data-coui-nav-index="1"]');
      await settle();
      expect(await page.evaluate<List<dynamic>>('() => scopeEvents'), [1]);
    }
  });
}

const _measure = r'''
() => {
 const n=document.getElementById('case-nav');
 const l=n.querySelector('[id$="-label"]');
 const f=l.parentElement.parentElement,inner=f.parentElement;
 const horizontal=inner.style.flexDirection==='row';
 const extent=e=>e.getBoundingClientRect()[horizontal?'width':'height'];
 return {theme:document.documentElement.dataset.theme,
  callerClass:n.classList.contains('caller-nav'),rootGap:getComputedStyle(n).gap,
  ancestorGap:getComputedStyle(document.getElementById('ancestor')).gap,
  innerInlineGap:inner.style.gap,innerComputedGap:getComputedStyle(inner).gap,
  foldExtent:extent(f),labelExtent:extent(l),foldOpacity:getComputedStyle(f).opacity,
  foldRows:f.style.gridTemplateRows,foldColumns:f.style.gridTemplateColumns};
}
''';

const _client = '''
import 'dart:js_interop';
import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:jaspr/client.dart' as client;
@JS('globalThis.recordSelection')external void recordSelection(int value);
void main(){client.Jaspr.initializeApp();final q=Uri.base.queryParameters;
 CoUIThemeController.setTheme(q['theme']??'light');
 client.runApp(Component.fragment([
  Document.html(attributes:{'data-theme':q['theme']??'light'}),
  Style(styles:docsContentTheme().styles),
  CoUIWeb(theme:ThemeData.coui,child:_Case(q)),
 ]),attachTo:'#app');
}
class _Case extends StatefulComponent{
 const _Case(this.query);final Map<String,String> query;
 @override State<_Case> createState()=>_CaseState();
}
class _CaseState extends State<_Case>{
 int selected=0;
 @override Component build(BuildContext context){final q=component.query;
  final bar=NavigationBar(id:'case-nav',classes:'caller-nav',
   css:const Styles(raw:{'gap':'37px'}),mode:.bar,selectedIndex:selected,
   onSelected:(i){recordSelection(i);setState(()=>selected=i);},
   compact:q['kind']=='scroll' ? .onScroll : q['folded']=='true' ? .always : .never,
   labelPosition:CoreNavigationLabelPosition.values.byName(q['position']??'bottom'),
   navigationBarStyle:CoreNavigationBarStyle(surfaceStyle:.liquidGlass,labelSpacing:double.parse(q['gap']??'4')),
   items:[for(final label in ['Home','Search'])CoreNavigationBarItem<Component>.destination(
    label:label,icon:const div([],styles:Styles(raw:{'width':'24px','height':'24px','background':'currentColor'}))),
   ]);
  return div([
   if(q['kind']=='scroll')div([
    Scaffold(floatingFooter:true,footers:[bar],child:const div([],styles:Styles(raw:{'height':'2400px'}))),
   ],id:'viewport',styles:const Styles(raw:{'width':'400px','height':'480px','overflow-y':'auto','position':'relative'}))
   else div([bar],styles:const Styles(raw:{'width':'400px'})),
  ],id:'ancestor',styles:const Styles(raw:{'gap':'39px'}));
 }
}
''';
