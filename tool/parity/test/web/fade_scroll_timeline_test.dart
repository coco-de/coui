@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:coui_web/coui_web.dart';
import 'package:image/image.dart' as img;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  late Directory directory;
  late File html;
  late File partialHtml;
  pptr.Browser? browser;
  late pptr.Page page;
  final errors = <Object>[];

  Future<void> settle() => page.evaluate<void>(
    '() => new Promise(done => requestAnimationFrame(() => '
    'requestAnimationFrame(done)))',
  );
  Future<void> click(String id) async {
    await page.evaluate<void>(
      'id => document.getElementById(id).click()',
      args: [id],
    );
    await settle();
  }

  Future<void> open(Map<String, String> query) async {
    await page.goto(html.uri.replace(queryParameters: query).toString());
    await page.waitForSelector('#solid, #raw-inline, #inner');
    await page.evaluate<void>('() => document.fonts.ready');
    await settle();
  }

  Future<Map<String, dynamic>> geometry() =>
      page.evaluate<Map<String, dynamic>>('''
() => {
  const root=document.getElementById('fade'), v=root.querySelector(':scope>div');
  const css=getComputedStyle(v), h=css.overflowX==='auto';
  return {client:h?v.clientWidth:v.clientHeight,
    max:h?v.scrollWidth-v.clientWidth:v.scrollHeight-v.clientHeight,
    position:h?v.scrollLeft:v.scrollTop, mask:css.maskImage,
    own:v.getAnimations().filter(a=>a.effect.getKeyframes().some(k=>
      Object.keys(k).some(p=>p.startsWith('--co-fade-timeline-')))).length};
}
''');

  Future<void> scroll(int position) async {
    await page.evaluate<void>(
      '''
position => {
  const v=document.querySelector('#fade>div');
  if(getComputedStyle(v).overflowX==='auto')v.scrollLeft=position;
  else v.scrollTop=position;
}
''',
      args: [position],
    );
    await settle();
  }

  Future<img.Image> pixels(String selector) async {
    final element = await page.$(selector);
    return img.decodePng(Uint8List.fromList(await element.screenshot()))!;
  }

  void expectSamePixels(img.Image actual, img.Image expected, String reason) {
    expect((actual.width, actual.height), (expected.width, expected.height));
    expect(
      actual.getBytes(order: img.ChannelOrder.rgba),
      expected.getBytes(order: img.ChannelOrder.rgba),
      reason: reason,
    );
  }

  Future<void> expectCorePixels({
    required bool horizontal,
    required num first,
    required num last,
    required num start,
    required num end,
    required num position,
    required num max,
    required String reason,
  }) async {
    await page.evaluate<void>(
      '''
(h, first, last, start, end, position, max) => {
  document.getElementById('expected')?.remove();
  const host=document.createElement('div'), v=document.createElement('div');
  host.id='expected';host.style.cssText=
    'width:'+(h?220:20)+'px;height:'+(h?20:220)+'px;background:#123456';
  v.style.cssText='width:'+(h?100:20)+'px;height:'+(h?20:100)+
    'px;background:red';
  const opaque='rgb(255 255 255 / '+first+')';
  const faded='rgb(255 255 255 / '+last+')';
  v.style.maskImage=max<=0?'none':
    'linear-gradient(to '+(h?'right':'bottom')+','+
    (position<=0?opaque:faded)+' 0,'+opaque+' '+start+'px,'+
    opaque+' calc(100% - '+end+'px),'+
    (position>=max?opaque:faded)+' 100%)';
  host.append(v);document.body.append(host);
}
''',
      args: [horizontal, first, last, start, end, position, max],
    );
    expectSamePixels(
      await pixels('#capture'),
      await pixels('#expected'),
      reason,
    );
  }

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-fade-timeline-');
    final entry = File('${directory.path}/client.dart')
      ..writeAsStringSync(_client);
    final js = File('${directory.path}/client.js');
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
              '<style>.solid{width:100px;height:100px;background:red}</style>'
              '<div id="app"></div><script>${js.readAsStringSync()}</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
        ),
      );
    final partialEntry = File('${directory.path}/partial_client.dart')
      ..writeAsStringSync(_partialClient);
    final partialJs = File('${directory.path}/partial_client.js');
    final partialCompiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '-Djaspr.flags.release=true',
      '--packages=${File('.dart_tool/package_config.json').absolute.path}',
      partialEntry.path,
      '-o',
      partialJs.path,
    ]);
    expect(
      partialCompiled.exitCode,
      0,
      reason: '${partialCompiled.stdout}\n${partialCompiled.stderr}',
    );
    final partialBody = await renderComponentBodyHtml(
      CoUIWeb(
        theme: ThemeData.coui,
        themeMode: CoreThemeMode.light,
        child: div([
          _partialOwner('a'),
          div(id: 'partial-app-b', [_partialOwner('b')]),
        ]),
      ),
    );
    partialHtml = File('${directory.path}/partial.html')
      ..writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml:
              '$partialBody<script>${partialJs.readAsStringSync()}</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
        ),
      );
    browser = await launchCaptureBrowser(width: 900, height: 800);
  });
  setUp(() async {
    errors.clear();
    page = await browser!.newPage();
    page.onError.listen(errors.add);
  });
  tearDown(() async {
    await page.close();
    expect(errors, isEmpty);
  });
  tearDownAll(() async {
    await browser?.close();
    directory.deleteSync(recursive: true);
  });

  test('hydrating B leaves a server-only FadeScroll A untouched', () async {
    await page.goto(partialHtml.uri.toString());
    await page.waitForFunction('() => typeof mountPartialFade === "function"');
    await page.evaluate<void>('() => document.fonts.ready');
    await settle();
    await page.evaluate<void>('''
() => {
  const root=document.getElementById('partial-fade-a');
  window.partialFadeRefs={root,viewport:root.querySelector(':scope>div')};
}
''');
    Future<Map<String, dynamic>> state() =>
        page.evaluate<Map<String, dynamic>>('''
() => {
  const r=partialFadeRefs,a=document.querySelector('#partial-fade-a>div'),
    b=document.querySelector('#partial-fade-b>div');
  return {sameRoot:document.getElementById('partial-fade-a')===r.root,
    sameViewport:a===r.viewport,mask:getComputedStyle(a).maskImage,
    effectsA:a.getAnimations().length,effectsB:b.getAnimations().length,
    bTargetsOwn:b.getAnimations().every(animation=>animation.effect.target===b),
    ids:[a.id,b.id],rootIds:[r.root.id,b.parentElement.id],
    publicAttribute:r.root.getAttribute('aria-label'),
    maxA:a.scrollWidth-a.clientWidth,maxB:b.scrollWidth-b.clientWidth};
}
''');
    final before = await state();
    final beforePixels = await pixels('#partial-capture-a');
    expect(before['effectsA'], 0);
    expect(before['effectsB'], 0);
    expect(before['mask'], isNot('none'));
    expect(before['maxA'], 0);
    expect(before['maxB'], 100);
    await page.evaluate<void>('() => mountPartialFade()');
    await settle();
    final after = await state();
    expectSamePixels(
      await pixels('#partial-capture-a'),
      beforePixels,
      'mounting B must not repaint a server-only A: $after',
    );
    expect(after['mask'], before['mask']);
    expect(after['sameRoot'], isTrue);
    expect(after['sameViewport'], isTrue);
    expect(after['effectsA'], 0);
    expect(after['effectsB'], 3);
    expect(after['bTargetsOwn'], isTrue);
    final ids = (after['ids'] as List<dynamic>).cast<String>();
    expect(ids[0], isNot(ids[1]));
    expect(after['rootIds'], ['partial-fade-a', 'partial-fade-b']);
    expect(after['publicAttribute'], 'Partial owner a');
    expect(after['maxA'], before['maxA']);
    expect(after['maxB'], before['maxB']);
  });

  test(
    'Core endpoints and live rebuilds match independent gradient pixels',
    () async {
      for (final theme in ['light', 'dark']) {
        for (final axis in ['h', 'v']) {
          for (final themed in [false, true]) {
            await open({
              'numeric': 'true',
              'kind': 'grow',
              'theme': theme,
              'axis': axis,
              'theme-style': '$themed',
            });
            for (final mode in ['default', 'last-half', 'both-alpha']) {
              await click('gradient-$mode');
              for (final position in [0, 50, 100]) {
                await scroll(position);
                final first =
                    mode == 'both-alpha' || (mode == 'default' && themed)
                    ? .6
                    : 1;
                final last = mode == 'default' && !themed ? 0 : 128 / 255;
                final startOffset = themed
                    ? 12
                    : CoreFadeScrollStyle.defaultStartOffset;
                final endOffset = themed
                    ? 27
                    : CoreFadeScrollStyle.defaultEndOffset;
                await expectCorePixels(
                  horizontal: axis == 'h',
                  first: first,
                  last: last,
                  start: startOffset,
                  end: endOffset,
                  position: position,
                  max: 100,
                  reason: '$theme/$axis/themed=$themed/$mode/$position',
                );
                expect((await geometry())['own'], 3);
              }
            }
          }
        }
      }
    },
  );

  test('Core small-overflow edges preserve actual fade pixels', () async {
    for (final axis in ['h', 'v']) {
      for (final mode in ['default', 'last-half', 'both-alpha']) {
        await open({
          'numeric': 'true',
          'kind': 'fit',
          'axis': axis,
          'gradient': mode,
        });
        final first = mode == 'both-alpha' ? .6 : 1;
        final last = mode == 'default' ? 0 : 128 / 255;
        await expectCorePixels(
          horizontal: axis == 'h',
          first: first,
          last: last,
          start: CoreFadeScrollStyle.defaultStartOffset,
          end: CoreFadeScrollStyle.defaultEndOffset,
          position: 0,
          max: 0,
          reason: '$axis/$mode/fitting unmasked',
        );
        for (final (stage, max) in [('max1', 1), ('max2', 2)]) {
          await click('stage-$stage');
          expect((await geometry())['max'], max);
          for (final position in [0, if (max == 2) 1, max]) {
            await scroll(position);
            final actual = await geometry();
            await expectCorePixels(
              horizontal: axis == 'h',
              first: first,
              last: last,
              start: CoreFadeScrollStyle.defaultStartOffset,
              end: CoreFadeScrollStyle.defaultEndOffset,
              position: actual['position'] as num,
              max: max,
              reason: '$axis/$mode/$stage/$position exact Core boundary',
            );
          }
        }
        await click('stage-zero');
        expect((await geometry())['client'], 0);
        final zero = await pixels('#capture');
        expect(
          zero.every(
            (pixel) => pixel.r == 18 && pixel.g == 52 && pixel.b == 86,
          ),
          isTrue,
        );
        await click('stage-restore');
        expect((await geometry())['max'], 100);
        expect((await geometry())['mask'], isNot('none'));
      }
    }
  });

  test(
    'quiet preloaded FontFace changes inline extent without parent rebuild',
    () async {
      final bytes = File(
        'docs_site/fonts/GeistMono-Regular.otf',
      ).readAsBytesSync();
      for (final axis in ['h', 'v']) {
        await open({'axis': axis, 'kind': 'late', 'gradient': 'both'});
        expect((await geometry())['mask'], 'none');
        await page.evaluate<void>(
          '''
async bytes => {
  const v=document.querySelector('#fade>div'), c=document.getElementById('raw-inline');
  window.notifications={ro:0,mo:0,font:0};
  new ResizeObserver(()=>notifications.ro++).observe(c);
  new MutationObserver(()=>notifications.mo++).observe(v,
    {attributes:true,characterData:true,childList:true,subtree:true});
  document.fonts.addEventListener('loadingdone',()=>notifications.font++);
  window.loadedFace=new FontFace('LateMono',new Uint8Array(bytes));
  await loadedFace.load();
}
''',
          args: [bytes],
        );
        await settle();
        await page.evaluate<void>('''
() => {
  notifications={ro:0,mo:0,font:0};
  document.fonts.add(loadedFace);
}
''');
        await settle();
        expect((await geometry())['max'], greaterThan(0));
        expect((await geometry())['mask'], isNot('none'));
        expect(
          await page.evaluate<Map<String, dynamic>>('''
() => ({...notifications,parent:parentBuilds,child:childBuilds,
  display:getComputedStyle(document.getElementById('raw-inline')).display})
'''),
          {
            'ro': 0,
            'mo': 0,
            'font': 0,
            'parent': 1,
            'child': 1,
            'display': 'inline',
          },
        );
        await page.evaluate<void>('() => {document.fonts.delete(loadedFace);}');
        await settle();
        expect((await geometry())['mask'], 'none');
      }
    },
  );

  test(
    'caller state, focus, selection and owned-effect disposal survive rebuilds',
    () async {
      await open({'axis': 'h', 'rich': 'true', 'kind': 'text'});
      await page.click('#caller-counter');
      await page.focus('#caller-input');
      await page.type('#caller-input', 'typed');
      await page.evaluate<void>('''
() => {
  window.savedCaller=document.getElementById('raw-inline');
  window.savedViewport=document.querySelector('#fade>div');
  const text=document.getElementById('selectable').firstChild;
  const range=document.createRange();range.setStart(text,1);range.setEnd(text,10);
  getSelection().removeAllRanges();getSelection().addRange(range);
}
''');
      await settle();
      await page.evaluate<void>(
        '() => {window.savedSelection=getSelection().toString();}',
      );
      await click('owner-counter');
      await click('toggle-bar');
      await click('toggle-bar');
      await click('toggle-axis');
      await click('toggle-axis');
      expect(
        await page.evaluate<bool>('''
() => savedCaller===document.getElementById('raw-inline') &&
  savedViewport===document.querySelector('#fade>div') &&
  document.getElementById('caller-counter').textContent==='1' &&
  document.activeElement===document.getElementById('caller-input') &&
  document.getElementById('caller-input').value.includes('typed') &&
  savedSelection.length>0 && getSelection().toString()===savedSelection &&
  fadeClickCount===1 && document.getElementById('fade').dataset.caller==='kept' &&
  document.getElementById('fade').getAttribute('aria-label')==='Fade content' &&
  getComputedStyle(document.getElementById('fade')).getPropertyValue('--caller-css')
    .trim()==='kept'
'''),
        isTrue,
      );
      expect((await geometry())['own'], 3);
      await click('toggle-model');
      expect(
        await page.evaluate<bool>('''
() => !document.getElementById('fade') && savedViewport.getAnimations().length===0 &&
 ['mask','gradient','start','end'].every(name=>
   savedViewport.style.getPropertyValue('--co-fade-timeline-'+name)==='')
'''),
        isTrue,
      );
      await click('toggle-model');
      expect((await geometry())['own'], 3);
    },
  );

  test(
    'equal local keys in separate owners keep independent timelines',
    () async {
      for (final theme in ['light', 'dark']) {
        for (final axis in ['h', 'v']) {
          await page.goto(
            html.uri
                .replace(
                  queryParameters: {
                    'local-keys': 'true',
                    'axis': axis,
                    'theme': theme,
                  },
                )
                .toString(),
          );
          await page.waitForSelector('#fade-a > div, #fade-b > div');
          await page.evaluate<void>('() => document.fonts.ready');
          await settle();
          final initial = await page.evaluate<Map<String, dynamic>>('''
() => {
  const rootA=document.getElementById('fade-a');
  const a=rootA.querySelector(':scope>div');
  const b=document.querySelector('#fade-b>div');
  window.keyOwnerRefs={rootA,a,b,caller:document.getElementById('key-caller-a'),
    input:document.getElementById('key-input-a')};
  return {ids:[a.id,b.id],effects:[a.getAnimations().length,b.getAnimations().length],
    builds:document.getElementById('key-owner-a').dataset.builds};
}
''');
          await click('key-count-a');
          await page.focus('#key-input-a');
          await page.type('#key-input-a', 'typed');
          await page.evaluate<void>('''
() => {
  keyOwnerRefs.input.setSelectionRange(1,4);
  const v=keyOwnerRefs.a;
  if(getComputedStyle(v).overflowX==='auto')
    v.scrollLeft=(v.scrollWidth-v.clientWidth)/2;
  else v.scrollTop=(v.scrollHeight-v.clientHeight)/2;
}
''');
          await settle();
          final beforeMask = await page.evaluate<String>(
            '() => getComputedStyle(keyOwnerRefs.a).maskImage',
          );
          final beforePixels = await pixels('#key-capture-a');
          // B alone rebuilds. A must keep its carriers without a refresh.
          await click('key-toggle-b');
          final disposed = await page.evaluate<Map<String, dynamic>>('''
() => {
  const r=keyOwnerRefs, v=document.querySelector('#fade-a>div');
  return {mask:getComputedStyle(v).maskImage,
    effects:v.getAnimations().length,removedEffects:r.b.getAnimations().length,
    removedCarriers:['mask','gradient','start','end'].map(name=>
      r.b.style.getPropertyValue('--co-fade-timeline-'+name)),
    builds:document.getElementById('key-owner-a').dataset.builds,
    sameRoot:document.getElementById('fade-a')===r.rootA,
    sameViewport:v===r.a,sameCaller:document.getElementById('key-caller-a')===r.caller,
    sameInput:document.getElementById('key-input-a')===r.input,
    focused:document.activeElement===r.input,value:r.input.value,
    selection:[r.input.selectionStart,r.input.selectionEnd],
    count:document.getElementById('key-count-a').textContent,
    rootId:r.rootA.id,label:r.rootA.getAttribute('aria-label'),
    callerAttribute:r.rootA.dataset.owner,
    gradientCarrier:v.style.getPropertyValue('--co-fade-timeline-gradient'),
    removedRoot:!document.getElementById('fade-b')};
}
''');
          expectSamePixels(
            await pixels('#key-capture-a'),
            beforePixels,
            '$theme/$axis: disposing B must not change A pixels; '
            'initial=$initial disposed=$disposed',
          );
          final ids = (initial['ids'] as List<dynamic>).cast<String>();
          expect(ids[0], isNot(ids[1]));
          expect(initial['effects'], [3, 3]);
          expect(disposed['mask'], beforeMask);
          expect(disposed['effects'], 3);
          expect(disposed['removedEffects'], 0);
          expect(disposed['removedCarriers'], ['', '', '', '']);
          expect(disposed['builds'], initial['builds']);
          for (final flag in [
            'sameRoot',
            'sameViewport',
            'sameCaller',
            'sameInput',
            'focused',
            'removedRoot',
          ]) {
            expect(disposed[flag], isTrue, reason: flag);
          }
          expect(disposed['value'], contains('typed'));
          expect(disposed['selection'], [1, 4]);
          expect(disposed['count'], '2');
          expect(disposed['rootId'], 'fade-a');
          expect(disposed['label'], 'Local owner a');
          expect(disposed['callerAttribute'], 'a');
          expect(disposed['gradientCarrier'], isNotEmpty);
          await click('key-toggle-b');
          await click('key-refresh-a');
          expect(
            await page.evaluate<bool>('''
() => {
  const a=document.querySelector('#fade-a>div'),b=document.querySelector('#fade-b>div');
  return a===keyOwnerRefs.a && a.id!==b.id &&
    a.getAnimations().length===3 && b.getAnimations().length===3 &&
    document.getElementById('key-input-a')===keyOwnerRefs.input &&
    document.getElementById('key-count-a').textContent==='2';
}
'''),
            isTrue,
          );
        }
      }
    },
  );
}

Component _partialOwner(String name) => div(
  id: 'partial-capture-$name',
  styles: const Styles(
    raw: {'width': '100px', 'height': '20px', 'background': '#123456'},
  ),
  [
    FadeScroll(
      id: 'partial-fade-$name',
      key: ValueKey(name),
      attributes: {'aria-label': 'Partial owner $name'},
      direction: CoreFadeScrollDirection.horizontal,
      child: div(
        const [],
        styles: Styles(
          raw: {
            'width': name == 'a' ? '100px' : '200px',
            'height': '20px',
            'background': 'red',
          },
        ),
      ),
    ),
  ],
);

// A normal client island attaches only B. A remains server-owned markup.
const _partialClient = '''
import 'dart:js_interop';
import 'package:coui_web/coui_web.dart' hide runApp;
import 'package:jaspr/client.dart' as client;
@JS('globalThis.mountPartialFade') external set mountPartialFade(JSFunction value);
void main() {
 client.Jaspr.initializeApp();
 mountPartialFade=((){client.runApp(CoUIWeb(theme:ThemeData.coui,
  themeMode:CoreThemeMode.light,child:div(id:'partial-capture-b',
  styles:const Styles(raw:{'width':'100px','height':'20px','background':'#123456'}),[
   FadeScroll(id:'partial-fade-b',key:const ValueKey('b'),
    attributes:const{'aria-label':'Partial owner b'},
    direction:CoreFadeScrollDirection.horizontal,
    child:div(const[],styles:const Styles(raw:{'width':'200px','height':'20px','background':'red'}))),
  ])),attachTo:'#partial-app-b');}).toJS;
}
''';

// The client fixture constructs the exported component; it has no replacement
// renderer, timeline bridge, global platform patch or test-mode product branch.
const _client = r'''
import 'dart:js_interop';
import 'package:coui_web/coui_web.dart' hide runApp;
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:jaspr/client.dart' as client;
@JS('globalThis.fadeClickCount') external JSNumber get _fadeClicks;
@JS('globalThis.fadeClickCount') external set _fadeClicks(JSNumber value);
@JS('globalThis.growChild') external set growChild(JSFunction value);
@JS('globalThis.shrinkChild') external set shrinkChild(JSFunction value);
@JS('globalThis.rebuildParent') external set rebuildParent(JSFunction value);
@JS('globalThis.parentBuilds') external set parentBuilds(JSNumber value);
@JS('globalThis.childBuilds') external set childBuilds(JSNumber value);
void main(){
 _fadeClicks=0.toJS;client.Jaspr.initializeApp();final q=Uri.base.queryParameters;final theme=q['theme']??'light';CoUIThemeController.setTheme(theme);
 client.runApp(Component.fragment([Document.html(attributes:{'data-theme':theme}),Style(styles:docsContentTheme().styles),CoUIWeb(theme:ThemeData.coui.copyWith(coreComponentTheme:q['theme-style']=='true'?const CoreComponentTheme(fadeScroll:CoreFadeScrollTheme(style:CoreFadeScrollStyle(gradient:[CoreColor(0x99ffffff),CoreColor(0x80ffffff)],startOffset:12,endOffset:27))):null),themeMode:theme=='dark'?CoreThemeMode.dark:CoreThemeMode.light,child:q['local-keys']=='true'?_LocalKeyOwners(horizontal:q['axis']=='h'):q['numeric']=='true'?_NumericOwner(q):_Owner(q))]),attachTo:'#app');
}
// Actual exported FadeScroll. No diagnostic renderer or runtime bridge.
Component _fade({required String id,required Component child,required bool horizontal,bool scrollbar=false,CoreFadeScrollStyle? style})=>FadeScroll(id:id,showScrollbar:scrollbar,attributes:const{'aria-label':'Fade content','data-caller':'kept'},css:const Styles(raw:{'--caller-css':'kept'}),onClick:(_)=>_fadeClicks=(_fadeClicks.toDartInt+1).toJS,direction:horizontal?CoreFadeScrollDirection.horizontal:CoreFadeScrollDirection.vertical,fadeScrollStyle:style,child:child);

class _Owner extends StatefulComponent {const _Owner(this.query);final Map<String,String> query;@override State<_Owner> createState()=>_OwnerState();}
class _OwnerState extends State<_Owner>{
 int builds=0,count=0;late final Component caller;bool outerOverflow=false,innerOverflow=true,mountedModel=true,flipped=false,bar=false;
 bool get h=>(component.query['axis']!='v')!=flipped;
 @override void initState(){super.initState();caller=_Content(horizontal:h,kind:component.query['kind']??'text',rich:component.query['rich']=='true',key:const ValueKey('caller'));rebuildParent=(()=>setState((){})).toJS;}
 CoreFadeScrollStyle? get style=>switch(component.query['gradient']){'both'=>const CoreFadeScrollStyle(gradient:[CoreColor(0x99ffffff),CoreColor(0x80ffffff)]),'last'=>const CoreFadeScrollStyle(gradient:[CoreColor(0xffffffff),CoreColor(0x80ffffff)]),'offset'=>const CoreFadeScrollStyle(startOffset:12,endOffset:27),_=>null};
 Component nested()=>_fade(id:'outer',horizontal:h,style:style,child:div([div([_fade(id:'inner',horizontal:h,style:style,child:div([],classes:'solid',styles:Styles(raw:{'width':'${h&&innerOverflow?200:100}px','height':'${!h&&innerOverflow?200:100}px'})))],styles:const Styles(raw:{'width':'100px','height':'100px'}))],styles:Styles(raw:{'width':'${h&&outerOverflow?200:100}px','height':'${!h&&outerOverflow?200:100}px'})));
 @override Component build(BuildContext context){parentBuilds=(++builds).toJS;return div([
  div([Component.text(CoUIThemeController.getCurrentTheme())],id:'controller-theme'),
  div([if(mountedModel)component.query['nested']=='true'?nested():component.query['fallback']=='true'?FadeScroll(id:'fade',direction:h?CoreFadeScrollDirection.horizontal:CoreFadeScrollDirection.vertical,fadeScrollStyle:style,child:caller):_fade(id:'fade',horizontal:h,style:style,scrollbar:bar,child:caller)],id:'host',styles:const Styles(raw:{'width':'100px','height':'100px','background':'#123456'})),
  if(component.query['nested']=='true')for(final state in ['outer-fit','outer-overflow','both-fit','both-overflow'])button([Component.text(state)],id:'nested-$state',onClick:()=>setState((){outerOverflow=state=='outer-overflow'||state=='both-overflow';innerOverflow=state=='outer-fit'||state=='both-overflow';})),
  button([Component.text('mount')],id:'toggle-model',onClick:()=>setState(()=>mountedModel=!mountedModel)),button([Component.text('bar')],id:'toggle-bar',onClick:()=>setState(()=>bar=!bar)),button([Component.text('axis')],id:'toggle-axis',onClick:()=>setState(()=>flipped=!flipped)),button([Component.text('$count')],id:'owner-counter',onClick:()=>setState(()=>count++)),
 ]);}
}
class _Content extends StatefulComponent {const _Content({required this.horizontal,required this.kind,required this.rich,super.key});final bool horizontal,rich;final String kind;@override State<_Content> createState()=>_ContentState();}
class _ContentState extends State<_Content>{bool grown=false;int builds=0,count=0;
 @override void initState(){super.initState();growChild=(()=>setState(()=>grown=true)).toJS;shrinkChild=(()=>setState(()=>grown=false)).toJS;}
 @override Component build(BuildContext context){childBuilds=(++builds).toJS;
  final short=component.horizontal?'iiiiiiiiiiiiiiiiiiii':List.filled(40,'i').join(' ');
  final text=component.kind=='font'||component.kind=='late'?short:grown?List.filled(24,'long content').join(' '):short;
  return span([
   if(component.rich)button([Component.text('$count')],id:'caller-counter',onClick:()=>setState(()=>count++)),
   span([Component.text(text)],id:'selectable'),
   if(component.rich)input(id:'caller-input',value:'caller-value'),
  ],id:'raw-inline',styles:Styles(raw:{'display':'inline','font-family':'LateMono, Arial','font-size':component.kind=='font'&&grown?'56px':'14px','line-height':component.horizontal?'100px':'20px','white-space':component.horizontal?'nowrap':'normal'}));
 }
}

class _NumericOwner extends StatefulComponent{const _NumericOwner(this.query);final Map<String,String> query;@override State<_NumericOwner>createState()=>_NumericOwnerState();}
class _NumericOwnerState extends State<_NumericOwner>{late double main,childMain;late bool horizontal,scrollbar;late String mode;
 @override void initState(){super.initState();final q=component.query;horizontal=q['axis']=='h';scrollbar=q['scrollbar']=='true';mode=q['gradient']??'default';main=q['kind']=='zero'?0:100;childMain=q['kind']=='fit'?100:q['kind']=='max1'?101:q['kind']=='max2'?102:200;}
 @override Component build(BuildContext context){final gradient=mode=='default'?null:CoreFadeScrollStyle(gradient:[CoreColor(mode=='last-half'?0xffffffff:0x99ffffff),const CoreColor(0x80ffffff)]);
 return div([for(final value in ['default','last-half','both-alpha'])button([Component.text(value)],id:'gradient-$value',onClick:()=>setState(()=>mode=value)),for(final stage in ['fit','grow','max1','max2','zero','restore'])button([Component.text(stage)],id:'stage-$stage',onClick:()=>setState((){main=stage=='zero'?0:100;childMain=stage=='fit'?100:stage=='max1'?101:stage=='max2'?102:200;})),
 div([div([FadeScroll(id:'fade',direction:horizontal?CoreFadeScrollDirection.horizontal:CoreFadeScrollDirection.vertical,showScrollbar:scrollbar,fadeScrollStyle:gradient,child:div(const[],id:'solid',styles:Styles(raw:{'width':'${horizontal?childMain:20}px','height':'${horizontal?20:childMain}px','background-color':'#ff0000'})))],id:'viewport-host',attributes:{'data-main':'$main','data-child':'$childMain'},styles:Styles(raw:{'width':'${horizontal?main:20}px','height':'${horizontal?20:main}px'}))],id:'capture',styles:Styles(raw:{'width':'${horizontal?220:20}px','height':'${horizontal?20:220}px','background-color':'#123456'}))]);}
}

class _LocalKeyOwners extends StatelessComponent {
 const _LocalKeyOwners({required this.horizontal});final bool horizontal;
 @override Component build(BuildContext context)=>div([
  _LocalKeyOwner(name:'a',horizontal:horizontal),
  _LocalKeyOwner(name:'b',horizontal:horizontal),
 ]);
}
class _LocalKeyOwner extends StatefulComponent {
 const _LocalKeyOwner({required this.name,required this.horizontal});
 final String name;final bool horizontal;
 @override State<_LocalKeyOwner> createState()=>_LocalKeyOwnerState();
}
class _LocalKeyOwnerState extends State<_LocalKeyOwner> {
 bool show=true;int builds=0;
 @override Component build(BuildContext context){final name=component.name;return div([
  button([Component.text('toggle')],id:'key-toggle-$name',onClick:()=>setState(()=>show=!show)),
  button([Component.text('refresh')],id:'key-refresh-$name',onClick:()=>setState((){})),
  div([if(show)FadeScroll(id:'fade-$name',key:const ValueKey('same-local-key'),
   attributes:{'aria-label':'Local owner $name','data-owner':name},
   direction:component.horizontal?CoreFadeScrollDirection.horizontal:CoreFadeScrollDirection.vertical,
   child:_LocalKeyCaller(name:name,horizontal:component.horizontal))],
   id:'key-capture-$name',styles:const Styles(raw:{'width':'100px','height':'100px','background':'#123456'})),
 ],id:'key-owner-$name',attributes:{'data-builds':'${++builds}'});}
}
class _LocalKeyCaller extends StatefulComponent {
 const _LocalKeyCaller({required this.name,required this.horizontal});
 final String name;final bool horizontal;
 @override State<_LocalKeyCaller>createState()=>_LocalKeyCallerState();
}
class _LocalKeyCallerState extends State<_LocalKeyCaller>{
 int count=1;
 @override Component build(BuildContext context){final name=component.name;return div([
  button([Component.text('$count')],id:'key-count-$name',onClick:()=>setState(()=>count++)),
  input(id:'key-input-$name',value:'caller-value'),
  Component.text('Caller payload'),
 ],id:'key-caller-$name',styles:Styles(raw:{'width':component.horizontal?'360px':'100px',
   'height':component.horizontal?'100px':'360px','background':'red'}));}
}

''';
