@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';

// LocalKey equality is legal across different parents. These are public
// renderers with independent owners, not renderer or DOM-bridge substitutes.
void main() {
  late Directory directory;
  late File html;
  late File server;
  late String javascript;
  final packageConfig = File('.dart_tool/package_config.json').absolute.path;
  pptr.Browser? browser;
  late pptr.Page page;
  final runtimeErrors = <String>[];

  Future<void> settle() => page.evaluate<void>(
    '() => new Promise(done => requestAnimationFrame(() => '
    'requestAnimationFrame(() => requestAnimationFrame(done))))',
  );

  Future<void> click(String id) async {
    await page.evaluate<void>(
      'id => document.getElementById(id).click()',
      args: [id],
    );
    await settle();
  }

  String harness(String body) => buildOfflineTailwindHarnessHtml(
    bodyHtml:
        '<script>window.scopeEvents=[];window.recordScope=(owner,event,value)'
        '=>scopeEvents.push({owner,event,value});</script>'
        '$body<script>$javascript</script>',
    themeConfig: ThemeConfig.defaults(),
    vendoredTailwindScript: loadVendoredTailwindScript(),
    additionalHeadHtml:
        '<style>${buildLocalFontFaceCss()}</style>'
        '${buildLocalIconifyHeadHtml()}',
    animationFreezeCss: '',
  );

  Future<void> open(
    String type, {
    bool explicitIds = false,
    bool unseeded = false,
  }) async {
    await page.goto(
      html.uri
          .replace(
            queryParameters: {
              'type': type,
              'explicit': '$explicitIds',
              'unseeded': '$unseeded',
            },
          )
          .toString(),
    );
    await page.waitForSelector('#host-b>*');
    await page.evaluate<void>('() => document.fonts.ready');
    await settle();
  }

  Future<List<dynamic>> list(String expression) =>
      page.evaluate<List<dynamic>>('() => $expression');

  Future<void> replaceInput(String selector, String value) async {
    await page.evaluate<void>(
      'selector => document.querySelector(selector).select()',
      args: [selector],
    );
    await page.type(selector, value);
    await settle();
  }

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-stateful-scope-');
    File('${directory.path}/widgets.dart').writeAsStringSync(_widgets);
    final client = File('${directory.path}/client.dart')
      ..writeAsStringSync(_client);
    server = File('${directory.path}/server.dart')
      ..writeAsStringSync(
        _server.replaceAll('REPOSITORY_ROOT', Directory.current.path),
      );
    final js = File('${directory.path}/client.js');
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '-Djaspr.flags.release=true',
      '--packages=$packageConfig',
      client.path,
      '-o',
      js.path,
    ]);
    expect(
      compiled.exitCode,
      0,
      reason: '${compiled.stdout}\n${compiled.stderr}',
    );
    javascript = js.readAsStringSync();
    html = File('${directory.path}/index.html')
      ..writeAsStringSync(harness('<div id="app"></div>'));
    browser = await launchCaptureBrowser(width: 1200, height: 1000);
  });
  setUp(() async {
    runtimeErrors.clear();
    page = await browser!.newPage();
    page.onError.listen((error) => runtimeErrors.add('$error'));
  });
  tearDown(() async {
    await page.close();
    expect(runtimeErrors, isEmpty);
  });
  tearDownAll(() async {
    await browser?.close();
    directory.deleteSync(recursive: true);
  });

  test('RichEditor seeds and edits its own surface', () async {
    await open('rich');
    expect(
      await list(
        "['a','b'].map(o=>document.querySelector("
        "'#host-'+o+' [contenteditable]').textContent)",
      ),
      ['Alpha document', 'Beta document'],
    );
    await page.type('#host-b [contenteditable]', ' kept');
    await settle();
    expect(
      await page.evaluate<String>(
        "() => document.querySelector('#host-a [contenteditable]').textContent",
      ),
      'Alpha document',
    );
    expect(await list('scopeEvents.map(e=>e.owner)'), isNotEmpty);
    expect(await list('scopeEvents.map(e=>e.owner)'), everyElement('b'));
  });

  test(
    'FormField accessible labels and descriptions belong to each owner',
    () async {
      await open('field', explicitIds: true);
      for (final owner in ['a', 'b']) {
        final root = await page.$('#public-$owner');
        final ax = await page.accessibility.snapshot(
          root: root,
          interestingOnly: false,
        );
        expect(ax.name, owner == 'a' ? 'Alpha label' : 'Beta label');
        expect(
          ax.description,
          owner == 'a' ? 'Alpha description' : 'Beta description',
        );
      }
    },
  );

  for (final type in ['tree', 'picker']) {
    test('$type arrow navigation stays in its owner', () async {
      await open(type);
      final role = type == 'tree' ? 'treeitem' : 'option';
      await page.focus('#host-b [role=$role]');
      await page.keyboard.press(pptr.Key.arrowDown);
      await settle();
      expect(
        await page.evaluate<String>(
          "() => document.activeElement.closest('[data-owner]').dataset.owner",
        ),
        'b',
      );
      expect(
        await page.evaluate<String>('() => document.activeElement.textContent'),
        contains('b two'),
      );
      if (type == 'tree') {
        await click('rename-b');
        await page.waitForSelector('#host-b input');
        await replaceInput('#host-b input', 'Renamed B');
        await page.keyboard.press(pptr.Key.enter);
        await settle();
        expect(
          await list('scopeEvents.map(e=>[e.owner,e.event,e.value])'),
          contains(equals(['b', 'rename', 'Renamed B'])),
        );
        expect(
          await page.evaluate<String>(
            "() => document.getElementById('host-b').textContent",
          ),
          contains('Renamed B'),
        );
      }
    });
  }

  test(
    'Loading keeps distinct Core durations after another owner disposes',
    () async {
      await open('loading');
      const durations = """
['a','b'].map(o=>[...document.querySelectorAll('#host-'+o+' *')]
 .map(e=>getComputedStyle(e)).find(s=>s.animationName!=='none')
 .animationDuration)
""";
      expect(await list(durations), ['2s', '0.4s']);
      await click('toggle-b');
      expect(
        await page.evaluate<String>("""
() => [...document.querySelectorAll('#host-a *')]
 .map(e=>getComputedStyle(e)).find(s=>s.animationName!=='none')
 .animationDuration
"""),
        '2s',
      );
    },
  );

  test('OverflowMarquee measures its own overflowing track', () async {
    await open('marquee');
    const transforms =
        "['a','b'].map(o=>getComputedStyle(document.querySelector("
        "'#host-'+o+'>div>div')).transform)";
    final initial = await list(transforms);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final later = await list(transforms);
    expect(later[0], initial[0], reason: 'A fits its own viewport');
    expect(
      later[1],
      isNot(initial[1]),
      reason: 'B has an overflowing 360px track',
    );
    expect(
      await list(
        "['a','b'].map(o=>document.querySelector('#host-'+o+'>div>div')"
        '.getBoundingClientRect().width)',
      ),
      [100, 360],
    );
  });

  for (final type in ['formatted', 'object']) {
    test('$type CSS scope and value callback stay with their owner', () async {
      await open(type);
      final prefix = type == 'formatted'
          ? 'co-formatted-input-'
          : 'co-object-input-';
      await page.hover('#host-a [id^=$prefix]');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        await page.evaluate<String>("""
() => getComputedStyle(document.querySelector(
 '#host-a [id^="$prefix"]')).borderColor
"""),
        'rgb(255, 0, 0)',
      );
      await replaceInput(
        '#host-b input',
        type == 'formatted' ? '5554443333' : 'Kept B',
      );
      expect(await list('scopeEvents.map(e=>e.owner)'), isNotEmpty);
      expect(await list('scopeEvents.map(e=>e.owner)'), everyElement('b'));
      expect(
        await page.evaluate<String>(
          "() => document.querySelector('#host-a input').value",
        ),
        isNot(contains(type == 'formatted' ? '555' : 'Kept B')),
      );
    });
  }

  test('Scrollbar thumb geometry is based on its own scroll extent', () async {
    await open('scrollbar');
    expect(
      await list("""
['a','b'].map(o=>{const r=document.querySelector('#host-'+o+'>div');
 return[r.clientHeight,r.scrollHeight,r.querySelector(
 '.co-scrollbar-thumb.co-scrollbar-vertical').getBoundingClientRect().height]})
"""),
      [
        [300, 600, 152],
        [300, 1200, 78],
      ],
    );
  });

  test('TextArea B pointer is outside A and inside B', () async {
    await open('area');
    await page.click('#host-b textarea');
    await settle();
    expect(await list('scopeEvents.map(e=>[e.owner,e.event])'), [
      ['a', 'outside'],
    ]);
  });

  test(
    'unseeded fields preserve nodes, selection and values across rebuild/reorder',
    () async {
      for (final type in ['rich', 'formatted', 'object', 'area']) {
        await open(type, unseeded: true);
        final selector = type == 'rich'
            ? '#host-b [contenteditable]'
            : '#host-b input, #host-b textarea';
        if (type != 'rich') {
          await replaceInput(
            selector,
            type == 'formatted' ? '5554443333' : 'Kept value B',
          );
        }
        await page.evaluate<void>(
          '''
selector => {
 window.savedA=document.getElementById('host-a').firstElementChild;
 window.savedB=document.querySelector(selector);
 window.savedElementId=savedB.id;
 window.savedValue=savedB.value??savedB.textContent;
 if(savedB.setSelectionRange)savedB.setSelectionRange(2,5);
 window.aBuilds=document.getElementById('owner-a').dataset.builds;
}
''',
          args: [selector],
        );
        await click('rebuild-b');
        await click('reorder');
        expect(
          await page.evaluate<Map<String, dynamic>>(
            '''
selector => ({node:savedB===document.querySelector(selector),
 value:(savedB.value??savedB.textContent)===savedValue,
 elementId:savedB.id===savedElementId,
 selection:!savedB.setSelectionRange||(savedB.selectionStart===2&&savedB.selectionEnd===5)})
''',
            args: [selector],
          ),
          {'node': true, 'value': true, 'elementId': true, 'selection': true},
          reason: type,
        );
        // B's independent owner disposes/remounts its child without rebuilding A.
        await page.evaluate<void>(
          "() => window.aBuilds=document.getElementById('owner-a') "
          '.dataset.builds',
        );
        await click('toggle-b');
        await click('toggle-b');
        expect(
          await page.evaluate<bool>('''
() => savedA===document.getElementById('host-a').firstElementChild&&
 aBuilds===document.getElementById('owner-a').dataset.builds
'''),
          isTrue,
          reason: type,
        );
      }
    },
  );

  test(
    'explicit caller root IDs and supported attributes retain priority',
    () async {
      for (final type in _types) {
        await open(type, explicitIds: true);
        expect(
          await list(
            type == 'field'
                ? "['a','b'].map(o=>document.getElementById('public-'+o)?.id)"
                : "['a','b'].map(o=>document.getElementById('public-'+o)"
                      "?.getAttribute('data-caller'))",
          ),
          type == 'field' ? ['public-a', 'public-b'] : ['a', 'b'],
          reason: type,
        );
        await page.evaluate<void>(
          "() => window.savedRoot=document.getElementById('public-b')",
        );
        await click('rebuild-b');
        expect(
          await page.evaluate<bool>(
            "() => savedRoot===document.getElementById('public-b')",
          ),
          isTrue,
          reason: type,
        );
      }
    },
  );

  test('partial CSR preserves a separate static SSR owner', () async {
    for (final type in ['rich', 'field']) {
      final rendered = await Process.run(Platform.resolvedExecutable, [
        '--packages=$packageConfig',
        server.path,
        type,
      ]);
      expect(
        rendered.exitCode,
        0,
        reason: '${rendered.stdout}\n${rendered.stderr}',
      );
      final partial = File('${directory.path}/partial-$type.html')
        ..writeAsStringSync(harness(rendered.stdout as String));
      await page.goto(
        partial.uri
            .replace(
              queryParameters: {
                'type': type,
                'partial': 'true',
                'explicit': 'true',
              },
            )
            .toString(),
      );
      await page.waitForSelector('#host-a>*');
      await page.evaluate<void>(
        "() => window.staticA=document.getElementById('host-a') "
        '.firstElementChild',
      );
      await page.evaluate<void>('() => mountScopeClient()');
      await page.waitForSelector('#host-b[data-browser=true]');
      await settle();
      expect(
        await page.evaluate<bool>(
          "() => staticA===document.getElementById('host-a').firstElementChild",
        ),
        isTrue,
      );
      if (type == 'rich') {
        expect(
          await list(
            "['a','b'].map(o=>document.querySelector("
            "'#host-'+o+' [contenteditable]').textContent)",
          ),
          ['Alpha document', 'Beta document'],
        );
      } else {
        final ax = await page.accessibility.snapshot(
          root: await page.$('#public-b'),
          interestingOnly: false,
        );
        expect(ax.name, 'Beta label');
        expect(ax.description, 'Beta description');
      }
    }
  });
}

const _types = [
  'rich',
  'field',
  'tree',
  'picker',
  'loading',
  'marquee',
  'formatted',
  'object',
  'scrollbar',
  'area',
];

const _widgets = r'''
import 'dart:convert';
import 'package:coui_web/coui_web.dart';

typedef ScopeRecord = void Function(String owner,String event,String value);
class AuditOwners extends StatefulComponent {
 const AuditOwners(this.type,this.record,{this.explicitIds=false,this.unseeded=false});
 final String type; final ScopeRecord record; final bool explicitIds,unseeded;
 @override State<AuditOwners> createState()=>_AuditOwnersState();
}
class _AuditOwnersState extends State<AuditOwners> {
 bool reversed=false;
 @override Component build(BuildContext context)=>div([
  button([Component.text('Reorder')],id:'reorder',onClick:()=>setState(()=>reversed=!reversed)),
  for(final owner in reversed?['b','a']:['a','b'])
   AuditOwner(owner,component.type,component.record,explicitIds:component.explicitIds,unseeded:component.unseeded,key:ValueKey(owner)),
 ]);
}
class AuditOwner extends StatefulComponent {
 const AuditOwner(this.owner,this.type,this.record,{this.explicitIds=false,this.distinctKeys=false,this.unseeded=false,super.key});
 final String owner,type;final ScopeRecord record;final bool explicitIds,distinctKeys,unseeded;
 @override State<AuditOwner> createState()=>_AuditOwnerState();
}
class _AuditOwnerState extends State<AuditOwner> {
 bool visible=true;int builds=0;String? renamed;
 final CoreTreeController controller=CoreTreeController();
 void report(String event,Object value)=>component.record(component.owner,event,value is String?value:jsonEncode(value));
 Component example(){
  final o=component.owner,a=o=='a',key=ValueKey(component.distinctKeys?o:'same-local-key');
  final id=component.explicitIds?'public-$o':null,attrs={'data-caller':o};
  switch(component.type){
  case 'rich':return RichEditor(id:id,key:key,attributes:attrs,initialValue:a?'Alpha document':'Beta document',toolbar:const[],showSelectionToolbar:false,onChanged:(v)=>report('changed',v));
  case 'field':return FormField(id:id,key:key,label:a?'Alpha label':'Beta label',description:a?'Alpha description':'Beta description',child:TextField(initialValue:'Input $o'));
  case 'tree':return Tree(id:id,key:key,attributes:attrs,controller:controller,nodes:[CoreTreeNode(id:'$o-one',label:renamed??'$o one'),CoreTreeNode(id:'$o-two',label:'$o two')],onNodeRename:(node,label){report('rename',label);setState(()=>renamed=label);});
  case 'picker':return ItemPicker(id:id,key:key,attributes:attrs,items:['$o one','$o two'],showSearch:false,onChanged:(v)=>report('changed',v));
  case 'loading':return Loading(id:id,key:key,attributes:attrs,loadingStyle:CoreLoadingStyle(duration:Duration(milliseconds:a?2000:400)));
  case 'marquee':return OverflowMarquee(id:id,key:key,attributes:attrs,overflowMarqueeStyle:const CoreOverflowMarqueeStyle(duration:Duration(seconds:1),delayDuration:Duration.zero),child:div([Component.text('Content $o')],styles:Styles(raw:{'height':'40px','width':a?'100px':'360px','background':'#446688'})));
  case 'formatted':return FormattedInput.phone(id:id,key:key,attributes:attrs,value:component.unseeded?null:'1112223333',formattedInputStyle:CoreFormattedInputStyle(hoverBorderColor:CoreColor(a?0xffff0000:0xff0000ff)),onChanged:(v)=>report('changed',v));
  case 'object':return ObjectInput(id:id,key:key,attributes:attrs,fields:const[CoreObjectInputField(key:'one',placeholder:'Part')],values:{'one':a?'Alpha':'Beta'},objectInputStyle:CoreObjectInputStyle(hoverBorderColor:CoreColor(a?0xffff0000:0xff0000ff)),onChanged:(v)=>report('changed',v));
  case 'scrollbar':return Scrollbar(id:id,key:key,attributes:attrs,visibility:CoreScrollbarVisibility.always,child:div([Component.text('Content $o')],styles:Styles(raw:{'height':a?'600px':'1200px','width':'200px','background':'#446688'})));
  case 'area':return TextArea(id:id,key:key,attributes:attrs,initialValue:a?'Alpha area':'Beta area',onTapOutside:()=>report('outside',''),textAreaStyle:const CoreTextAreaStyle(initialHeight:100,initialWidth:200));
  default:throw StateError(component.type);
  }
 }
 @override Component build(BuildContext context){builds++;final o=component.owner;return div([
  button([Component.text('Rebuild $o')],id:'rebuild-$o',onClick:()=>setState((){})),
  button([Component.text('Toggle $o')],id:'toggle-$o',onClick:()=>setState(()=>visible=!visible)),
  if(component.type=='tree')button([Component.text('Rename $o')],id:'rename-$o',onClick:()=>controller.startRename('$o-one')),
  div([if(visible)example()],id:'host-$o',attributes:{'data-owner':o,'data-browser':'$kIsWeb'},styles:Styles(raw:{'width':component.type=='scrollbar'?'200px':component.type=='marquee'?'100px':'420px','height':component.type=='scrollbar'?'300px':component.type=='marquee'?'40px':component.type=='loading'?'64px':'auto'})),
 ],id:'owner-$o',attributes:{'data-builds':'$builds'});}
}
''';

const _client = '''
import 'dart:js_interop';
import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:jaspr/client.dart' as client;
import 'widgets.dart';
@JS('globalThis.recordScope')external void recordScope(String owner,String event,String value);
@JS('globalThis.mountScopeClient')external set mountScopeClient(JSFunction value);
void main(){client.Jaspr.initializeApp();final q=Uri.base.queryParameters;
 void report(String o,String e,String v)=>recordScope(o,e,v);
 void mount(){CoUIThemeController.setTheme('light');client.runApp(Component.fragment([
  Document.html(attributes:{'data-theme':'light'}),Style(styles:docsContentTheme().styles),
  CoUIWeb(theme:ThemeData.coui,themeMode:CoreThemeMode.light,child:q['partial']=='true'
   ?AuditOwner('b',q['type']!,report,explicitIds:true,distinctKeys:true)
   :AuditOwners(q['type']!,report,explicitIds:q['explicit']=='true',unseeded:q['unseeded']=='true')),
 ]),attachTo:q['partial']=='true'?'#client-island':'#app');}
 if(q['partial']=='true'){mountScopeClient=((){mount();}).toJS;}else{mount();}
}
''';

const _server = '''
import 'dart:io';
import 'package:coui_web/coui_web.dart';
import 'REPOSITORY_ROOT/tool/parity/src/web/ssr_render.dart';
import 'widgets.dart';
void main(List<String> args)async{
 void record(String owner,String event,String value){}
 stdout.write(await renderComponentBodyHtml(CoUIWeb(theme:ThemeData.coui,child:div([
  AuditOwner('a',args[0],record,explicitIds:true,distinctKeys:true),
  div([AuditOwner('b',args[0],record,explicitIds:true,distinctKeys:true)],id:'client-island'),
 ]))));
}
''';
