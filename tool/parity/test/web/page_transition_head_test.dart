@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show durationMsCss;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';

void main() {
  test('app roots keep host head assets and own their page motion', () async {
    final dir = Directory.systemTemp.createTempSync('coui-page-head-');
    HttpServer? server;
    pptr.Browser? browser;
    try {
      final root = _repositoryRoot();
      final packages = '${root.path}/.dart_tool/package_config.json';
      File('${dir.path}/fixture.dart').writeAsStringSync(_fixture);
      final entry = File('${dir.path}/entry.dart')..writeAsStringSync(_client);
      final renderer = File('${dir.path}/render.dart')
        ..writeAsStringSync(
          _renderer.replaceAll(
            '{{SSR_RENDER}}',
            '${root.path}/tool/parity/src/web/ssr_render.dart',
          ),
        );
      for (final args in [
        ['--packages=$packages', renderer.path, dir.path],
        [
          'compile',
          'js',
          '-O2',
          '-Djaspr.flags.release=true',
          '--packages=$packages',
          entry.path,
          '-o',
          '${dir.path}/app.js',
        ],
      ]) {
        final run = await Process.run(Platform.resolvedExecutable, args);
        expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
      }
      File('${dir.path}/host.css').writeAsStringSync(
        ':root{--host-linked:9}',
      );
      server = (await HttpServer.bind(InternetAddress.loopbackIPv4, 0))
        ..listen((request) async {
          final response = request.response;
          final name = request.uri.path.substring(1);
          final file = File('${dir.path}/$name');
          response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
          if (!file.existsSync()) {
            response.statusCode = HttpStatus.notFound;
          } else {
            response.headers.contentType = name.endsWith('.js')
                ? ContentType('application', 'javascript')
                : name.endsWith('.css')
                ? ContentType('text', 'css')
                : ContentType.html;
            response.add(await file.readAsBytes());
          }
          await response.close();
        });
      final origin = 'http://${server.address.address}:${server.port}';
      browser = await launchCaptureBrowser(width: 1200, height: 900);
      final page = await browser.newPage();
      final errors = <String>[];
      page.onError.listen((error) => errors.add('$error'));
      await page.setRequestInterception(true);
      page.onRequest.listen((request) {
        if (request.url == 'https://cdn.tailwindcss.com/3.4.17') {
          unawaited(
            request.respond(
              contentType: 'application/javascript',
              body: loadVendoredTailwindScript(),
            ),
          );
        } else if (request.url ==
            'https://cdn.jsdelivr.net/npm/'
                'iconify-icon@2.1.0/dist/iconify-icon.min.js') {
          unawaited(
            request.respond(
              contentType: 'application/javascript',
              body: loadVendoredIconifyScript(),
            ),
          );
        } else if (request.url.contains('pretendard.min.css')) {
          unawaited(
            request.respond(
              contentType: 'text/css',
              body: buildLocalFontFaceCss(),
            ),
          );
        } else {
          unawaited(request.continueRequest());
        }
      });
      Future<void> settle() async {
        await page.evaluate<void>(
          '()=>new Promise(r=>requestAnimationFrame( '
          '()=>requestAnimationFrame(r)))',
        );
      }

      Future<void> open(String name) async {
        final response = await page.goto('$origin/$name.html', wait: .load);
        expect(response.status, HttpStatus.ok);
        await page.waitForFunction(
          '()=>document.documentElement.dataset.probeReady==="true"',
        );
        await page.evaluate<void>('()=>document.fonts.ready');
        await settle();
      }

      Future<Map<String, dynamic>> read() async {
        await settle();
        return await page.evaluate<Map<String, dynamic>>(_read);
      }

      Future<void> keepHost() async {
        final state = await read();
        expect(state['hostSame'], everyElement(isTrue));
        expect(state['hostInline'], '137');
        expect(state['hostLinked'], '9');
        expect(state['hostRuns'], 1);
      }

      Future<int> revealListeners() async {
        final window = await page.devTools.runtime.evaluate('window');
        final listeners = await page.devTools.domDebugger.getEventListeners(
          window.result.objectId!,
        );
        return listeners
            .where((listener) => listener.type == 'pagereveal')
            .length;
      }

      Future<void> click(String id) async {
        await page.click('#$id');
        await settle();
        await keepHost();
      }

      await open('enabled');
      await keepHost();
      // One document direction listener and one passive test recorder.
      expect(await revealListeners(), 2);
      for (final mode in ['siblings', 'nested', 'single']) {
        await click(mode);
        final expected = mode == 'siblings'
            ? 333
            : mode == 'nested'
            ? 222
            : 111;
        expect(
          (await read())['css'],
          contains('coui-page-enter ${durationMsCss(expected)} '),
        );
        expect(await revealListeners(), 2);
      }
      await click('graft');
      expect((await read())['css'], contains(durationMsCss(333)));
      await page.click('#counter');
      await page.evaluate<void>(
        '()=>window.graftCounter=document.querySelector("#counter")',
      );
      for (var move = 0; move < 4; move++) {
        await click('move');
        // Jaspr retains Element.depth when a GlobalKey moves back up.
        expect((await read())['css'], contains(durationMsCss(222)));
        expect(
          await page.evaluate<bool>(
            '()=>document.querySelector("#counter")===window.graftCounter&&'
            'document.querySelector("#counter").textContent==="counter=1"',
          ),
          isTrue,
        );
        expect(await revealListeners(), 2);
      }
      await click('single');
      await click('dark');
      await page.waitForFunction(
        '()=>document.documentElement.dataset.theme==="dark"&&'
        'getComputedStyle(document.querySelector(".coui-root")).color==='
        '"rgb(244, 245, 246)"',
      );
      await click('light');
      await page.waitForFunction(
        '()=>document.documentElement.dataset.theme==="light"&&'
        'getComputedStyle(document.querySelector(".coui-root")).color==='
        '"rgb(31, 32, 33)"',
      );
      await click('off');
      expect((await read())['css'], isEmpty);
      for (var cycle = 0; cycle < 3; cycle++) {
        await click('unmount');
        expect((await read())['roots'], 0);
        await click('remount');
        expect((await read())['css'], isEmpty);
        await click('on');
        expect((await read())['css'], contains(durationMsCss(111)));
        await click('off');
        expect((await read())['css'], isEmpty);
        expect(await revealListeners(), 2);
      }
      // A real cross-document navigation must not revive the SSR motion
      // after a live zero-duration theme has turned it off.
      await Future.wait([page.waitForNavigation(), page.click('#next')]);
      await page.waitForFunction(
        '()=>typeof window.shownTransition==="boolean"',
      );
      expect(await page.evaluate<bool>('()=>window.shownTransition'), isFalse);

      await open('off');
      await keepHost();
      expect((await read())['css'], isEmpty);
      expect(await revealListeners(), 1);
      await click('on');
      expect(await revealListeners(), 2);
      await click('off');
      expect((await read())['css'], isEmpty);
      expect(await revealListeners(), 2);

      await open('foreign');
      await keepHost();
      await click('remount');
      final foreign = await read();
      expect(foreign['css'], ':root{--foreign-motion:1}');
      expect(foreign['styleCount'], 1);
      expect(foreign['scriptCount'], 1);
      expect(await revealListeners(), 1);
      await click('dark');
      await click('off');
      expect((await read())['css'], ':root{--foreign-motion:1}');

      await page.emulateMediaFeatures([
        pptr.MediaFeature.prefersReducedMotion('reduce'),
      ]);
      await open('enabled');
      await Future.wait([page.waitForNavigation(), page.click('#next')]);
      await page.waitForFunction(
        '()=>typeof window.shownTransition==="boolean"',
      );
      expect(await page.evaluate<bool>('()=>window.shownTransition'), isFalse);
      expect(errors, isEmpty);
    } finally {
      await browser?.close();
      await server?.close(force: true);
      dir.deleteSync(recursive: true);
    }
  });
}

Directory _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (!File('${dir.path}/tool/browser_launch.dart').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) throw StateError('Repository root not found');
    dir = parent;
  }
  return dir;
}

const _read = '''
()=>({
 css:document.querySelector('#coui-page-transition')?.textContent.trim()??'',
 roots:document.querySelectorAll('.coui-root').length,
 hostSame:window.hostNodes.map(e=>document.head.contains(e.node)&&e.node.outerHTML===e.html),
 hostInline:getComputedStyle(document.documentElement).getPropertyValue('--host-inline').trim(),
 hostLinked:getComputedStyle(document.documentElement).getPropertyValue('--host-linked').trim(),
 hostRuns:window.hostRuns,
 styleCount:document.querySelectorAll('#coui-page-transition').length,
 scriptCount:document.querySelectorAll('#coui-page-transition-direction').length
})
''';

const _client = '''
import 'package:coui_web/coui_web.dart';
import 'package:universal_web/web.dart' as web;
import 'fixture.dart';
void main()=>runApp(Probe(
 off:web.document.documentElement!.getAttribute('data-fixture-off')=='true',
 show:web.document.documentElement!.getAttribute('data-fixture-show')!='false',
),attachTo:'#mount');
''';

const _renderer = r'''
import 'dart:io';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr/server.dart' as server;
import 'package:docs_core/site_head.dart';
import '{{SSR_RENDER}}';
import 'fixture.dart';
Future<void> main(List<String> args)async{
 for(final name in ['enabled','next','off','foreign']){
  final off=name=='off',show=name!='foreign';
  var html=await renderComponentToDocumentHtml(server.Document(
   head:[...docsSharedHead(),Component.element(tag:'script',children:[const RawText('addEventListener("pagereveal",e=>window.shownTransition=!!e.viewTransition);')])],
   styles:[...docsContentTheme().styles,...docsPreviewStyles()],
   body:div(id:'mount',[Probe(off:off,show:show,foreign:name=='foreign')]),
  ));
  html=html.replaceFirst('<html','<html data-fixture-off="$off" data-fixture-show="$show"');
  html=html.replaceFirst('</body>','<script>window.hostNodes=[...document.head.querySelectorAll("[data-host-probe]")].map(node=>({node,html:node.outerHTML}));</script><script src="/app.js"></script></body>');
  File('${args.single}/$name.html').writeAsStringSync(html);
 }
}
''';

const _fixture = r'''
import 'package:coui_web/coui_web.dart';
import 'package:universal_web/web.dart' as web;
class Probe extends StatefulComponent{
 const Probe({this.off=false,this.show=true,this.foreign=false,super.key});
 final bool off,show,foreign;
 @override State<Probe> createState()=>ProbeState();
}
class ProbeState extends State<Probe>{
 late bool off=component.off,show=component.show;
 bool dark=false,ready=false,graftDeep=false;
 final movingKey=GlobalKey(debugLabel:'moving-page-root');
 late final Component movingApp=app(222,const Counter(),key:movingKey);
 late final Component stationaryApp=app(333,const Text('stationary'));
 int mode=0;
 ThemeData theme(int ms,{required bool dark})=>(dark?ThemeData.dark:ThemeData.light).copyWith(coreComponentTheme:CoreComponentTheme(pageTransition:CorePageTransitionTheme(style:CorePageTransitionStyle(enterDuration:Duration(milliseconds:off?0:ms),exitDuration:Duration(milliseconds:off?0:99)))));
 Component app(int ms,Component child,{Key? key})=>CoUIWeb(key:key??ValueKey('$ms'),theme:theme(ms,dark:false),darkTheme:theme(ms,dark:true),themeMode:dark?CoreThemeMode.dark:CoreThemeMode.light,child:child);
 @override Component build(BuildContext context){
  if(kIsWeb&&!ready){ready=true;context.binding.addPostFrameCallback(()=>web.document.documentElement!.setAttribute('data-probe-ready','true'));}
  return div([
   Document.html(attributes:{'data-theme':dark?'dark':'light'}),
   if(!kIsWeb)Document.head(children:[
    Component.element(tag:'style',attributes:const{'data-host-probe':'inline'},children:[const RawText(':root{--host-inline:137}')]),
    link(rel:'stylesheet',href:'/host.css',attributes:const{'data-host-probe':'link'}),
    Component.element(tag:'script',attributes:const{'data-host-probe':'script'},children:[const RawText('window.hostRuns=(window.hostRuns||0)+1;')]),
    if(component.foreign)...[
     Component.element(tag:'style',id:'coui-page-transition',attributes:const{'data-host-probe':'foreign-style'},children:[const RawText(':root{--foreign-motion:1}')]),
     Component.element(tag:'script',id:'coui-page-transition-direction',attributes:const{'data-host-probe':'foreign-script'},children:[const RawText('window.foreignDirection=true;')]),
    ],
   ]),
   for(final entry in <String,void Function()>{
    'off':()=>setState(()=>off=true),'on':()=>setState(()=>off=false),
    'unmount':()=>setState(()=>show=false),'remount':()=>setState(()=>show=true),
    'dark':()=>setState(()=>dark=true),'light':()=>setState(()=>dark=false),
    'siblings':()=>setState(()=>mode=1),'nested':()=>setState(()=>mode=2),'single':()=>setState(()=>mode=0),
    'graft':()=>setState(()=>mode=3),'move':()=>setState(()=>graftDeep=!graftDeep),
   }.entries)button(id:entry.key,onClick:entry.value,[Text(entry.key)]),
   a(id:'next',href:'/next.html',[const Text('next')]),
   if(show)...[
    if(mode==0)app(111,const Text('single')),
    if(mode==1)...[app(111,const Text('earlier')),app(333,const Text('later'))],
    if(mode==2)...[app(111,app(222,const Text('deep')),key:const ValueKey('outer')),app(333,const Text('later'))],
    if(mode==3)...[
     if(graftDeep)div([div([movingApp])])else movingApp,
     div([stationaryApp]),
    ],
   ],
  ]);
 }
}
class Counter extends StatefulComponent{
 const Counter({super.key});
 @override State<Counter> createState()=>CounterState();
}
class CounterState extends State<Counter>{
 int count=0;
 @override Component build(BuildContext context)=>button(id:'counter',onClick:()=>setState(()=>count++),[Text('counter=$count')]);
}

''';
