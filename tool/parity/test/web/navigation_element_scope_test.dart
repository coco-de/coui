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
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';

void main() {
  late Directory directory;
  late File html;
  pptr.Browser? browser;
  late pptr.Page page;

  Future<void> settle() => page.evaluate<void>(
    '() => new Promise(done => requestAnimationFrame(() => '
    'requestAnimationFrame(done)))',
  );

  Future<img.Image> pixels() async {
    final subject = await page.$('[data-audit-owner="a"]');
    return img.decodePng(Uint8List.fromList(await subject.screenshot()))!;
  }

  void expectSamePixels(img.Image actual, img.Image expected, String reason) {
    expect((actual.width, actual.height), (expected.width, expected.height));
    expect(
      actual.getBytes(order: img.ChannelOrder.rgba),
      expected.getBytes(order: img.ChannelOrder.rgba),
      reason: reason,
    );
  }

  Future<Map<String, dynamic>> paint(String kind) =>
      page.evaluate<Map<String, dynamic>>(
        '''
kind => {
  const a=document.querySelector('[data-audit-owner="a"]');
  const b=document.querySelector('[data-audit-owner="b"]');
  const target=kind==='breadcrumb'?a.querySelector('[role="link"] > div'):
    Array.from(a.querySelectorAll('[class]')).find(n=>
      Array.from(n.classList).some(c=>c.endsWith('-wash')));
  const css=getComputedStyle(target),box=a.getBoundingClientRect();
  return {paint:kind==='breadcrumb'?css.color:css.backgroundColor,
    rect:[box.x,box.y,box.width,box.height],sameRoot:a===window.savedA,
    builds:document.getElementById('holder-a').dataset.builds,
    css:Array.from(a.querySelectorAll('style')).map(n=>n.textContent),
    rootId:a.id,bId:b?.id,callerClass:a.classList.contains('caller-a'),
    callerCss:getComputedStyle(a).getPropertyValue('--caller-owner').trim(),
    hover:a.matches(':hover'),active:a.matches(':active')};
}
''',
        args: [kind],
      );

  Future<void> hoverOrPress(String kind) async {
    final point = kind == 'breadcrumb'
        ? '[data-audit-owner="a"] [role="link"]'
        : '[data-audit-owner="a"]';
    await page.hover(point);
    if (kind == 'option_item') await page.mouse.down();
    await settle();
  }

  Future<void> release(String kind) async {
    if (kind == 'option_item') await page.mouse.up();
  }

  Future<void> verify(Map<String, String> query) async {
    final kind = query['kind']!;
    await page.goto(html.uri.replace(queryParameters: query).toString());
    await page.waitForSelector('[data-audit-owner="a"]');
    await page.evaluate<void>('() => document.fonts.ready');
    await settle();
    await page.evaluate<void>('''
() => {window.savedA=document.querySelector('[data-audit-owner="a"]');}
''');
    await hoverOrPress(kind);
    final before = await paint(kind);
    final beforePixels = await pixels();
    await release(kind);
    await page.evaluate<void>(
      '() => document.getElementById("toggle-b").click()',
    );
    await page.waitForSelector('[data-audit-owner="b"]');
    await hoverOrPress(kind);
    final mounted = await paint(kind);
    expectSamePixels(
      await pixels(),
      beforePixels,
      '$query: mounting B must not repaint unchanged A; '
      'before=$before mounted=$mounted',
    );
    expect(mounted['paint'], before['paint']);
    expect(mounted['rect'], before['rect']);
    expect(mounted['css'], before['css']);
    expect(mounted['builds'], before['builds']);
    expect(mounted['sameRoot'], isTrue);
    expect(mounted['hover'], isTrue);
    if (kind == 'option_item') expect(mounted['active'], isTrue);
    expect(mounted['callerClass'], isTrue);
    expect(mounted['callerCss'], 'a');
    final explicitId = kind != 'breadcrumb' || query['explicit-id'] == 'true';
    expect(mounted['rootId'], explicitId ? 'subject-a' : '');
    expect(mounted['bId'], explicitId ? 'subject-b' : '');
    await release(kind);
    await page.evaluate<void>(
      '() => document.getElementById("toggle-b").click()',
    );
    await hoverOrPress(kind);
    expectSamePixels(await pixels(), beforePixels, '$query: B removal');
    expect((await paint(kind))['sameRoot'], isTrue);
    await release(kind);
  }

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-navigation-scopes-');
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
              '<div id="app"></div><script>${js.readAsStringSync()}</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          additionalHeadHtml:
              '<style>${buildLocalFontFaceCss()}</style>${buildLocalIconifyHeadHtml()}',
        ),
      );
    browser = await launchCaptureBrowser(width: 900, height: 800);
  });
  setUp(() async {
    page = await browser!.newPage();
  });
  tearDown(() async {
    await page.close();
  });
  tearDownAll(() async {
    await browser?.close();
    directory.deleteSync(recursive: true);
  });

  for (final kind in [
    'sidebar_item',
    'sidebar_search',
    'sidebar_header',
    'sidebar_rail_item',
    'menu_item',
    'breadcrumb',
    'option_item',
    'command_search',
  ]) {
    test(
      '$kind keeps local-key owners and caller attributes independent',
      () async {
        for (final theme in ['light', 'dark']) {
          for (final keys in ['same', 'different']) {
            await verify({'kind': kind, 'theme': theme, 'keys': keys});
          }
          if (kind == 'breadcrumb') {
            await verify({
              'kind': kind,
              'theme': theme,
              'keys': 'same',
              'explicit-id': 'true',
            });
            await verify({
              'kind': kind,
              'theme': theme,
              'keys': 'same',
              'palette': 'token',
            });
          }
        }
      },
    );
  }
}

const _client = r'''
import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/client.dart' as client;

void main() {
  client.Jaspr.initializeApp();
  final q=Uri.base.queryParameters;
  final theme=q['theme']??'light';
  CoUIThemeController.setTheme(theme);
  client.runApp(Component.fragment([
    Document.html(attributes:{'data-theme':theme}),
    Style(styles:docsContentTheme().styles),
    CoUIWeb(theme:ThemeData.coui,
      themeMode:theme=='dark'?CoreThemeMode.dark:CoreThemeMode.light,
      child:div([_Holder(name:'a',q:q),_Holder(name:'b',q:q)])),
  ]),attachTo:'#app');
}

class _Holder extends StatefulComponent {
  const _Holder({required this.name,required this.q});
  final String name; final Map<String,String> q;
  @override State<_Holder> createState()=>_HolderState();
}
class _HolderState extends State<_Holder> {
  late bool shown;int builds=0;
  @override void initState(){super.initState();shown=component.name=='a';}
  @override Component build(BuildContext context)=>div([
    button([Component.text('Toggle ${component.name}')],id:'toggle-${component.name}',
      onClick:()=>setState(()=>shown=!shown)),
    div([if(shown)_subject(component.name,component.q)],id:'paint-${component.name}',
      classes:'bg-surface',styles:const Styles(raw:{'width':'320px','height':'88px'})),
  ],id:'holder-${component.name}',attributes:{'data-builds':'${++builds}'},
  styles:const Styles(raw:{'width':'340px','min-height':'120px'}));
}

Component _subject(String owner,Map<String,String> q) {
  final kind=q['kind']??'sidebar_item';
  final keyMode=q['keys']??'same';
  final Key? key=keyMode=='none'?null:ValueKey(keyMode=='same'?'same-local-key':'local-$owner');
  final second=owner=='b'&&q['same-color']!='true';
  final CoreColor ink=q['palette']=='token'
    ?CoreColor.token(second?CoreColors.onSurface:CoreColors.primary)
    :CoreColor(second?0xff0044ff:0xffff2200);
  final attrs={'data-audit-owner':owner};
  final String? id=kind=='breadcrumb'&&q['explicit-id']!='true'?null:'subject-$owner';
  final label=Component.text('Subject $owner');
  switch(kind){
    case 'sidebar_item':return SidebarItem(key:key,id:id,label:label,
      classes:'caller-$owner',css:Styles(raw:{'--caller-owner':owner}),attributes:attrs,onPressed:(){},sidebarItemStyle:CoreSidebarItemStyle(stateLayerColor:ink));
    case 'sidebar_search':return SidebarSearch(key:key,id:id,placeholder:'Search $owner',
      classes:'caller-$owner',css:Styles(raw:{'--caller-owner':owner}),attributes:attrs,onPressed:(){},sidebarSearchStyle:CoreSidebarSearchStyle(stateLayerColor:ink));
    case 'sidebar_header':return SidebarHeader(key:key,id:id,title:label,
      classes:'caller-$owner',css:Styles(raw:{'--caller-owner':owner}),attributes:attrs,onPressed:(){},sidebarHeaderStyle:CoreSidebarHeaderStyle(stateLayerColor:ink));
    case 'sidebar_rail_item':return SidebarRailItem(key:key,id:id,icon:const Icon(LucideIcons.search),
      label:'Rail $owner',classes:'caller-$owner',css:Styles(raw:{'--caller-owner':owner}),attributes:attrs,onPressed:(){},
      sidebarRailItemStyle:CoreSidebarRailItemStyle(stateLayerColor:ink));
    case 'menu_item':return MenuItem(key:key,id:id,label:label,classes:'caller-$owner',css:Styles(raw:{'--caller-owner':owner}),attributes:attrs,onPressed:(){},
      menuItemStyle:CoreMenuItemStyle(hoverBackgroundColor:ink));
    case 'option_item':return OptionItem(key:key,id:id,label:label,classes:'caller-$owner',css:Styles(raw:{'--caller-owner':owner}),attributes:attrs,onPressed:(){},
      optionItemStyle:CoreOptionItemStyle(pressedBackgroundColor:ink));
    case 'command_search':return CommandSearch(key:key,id:id,hint:'Command $owner',
      classes:'caller-$owner',css:Styles(raw:{'--caller-owner':owner}),attributes:attrs,onPressed:(){},commandSearchStyle:CoreCommandSearchStyle(stateLayerColor:ink));
    case 'breadcrumb':return Breadcrumb(key:key,id:id,
      items:[CoreBreadcrumbItem(label:'First $owner'),CoreBreadcrumbItem(label:'Current $owner')],
      classes:'caller-$owner',css:Styles(raw:{'--caller-owner':owner}),attributes:attrs,onItemTap:(_){},breadcrumbStyle:CoreBreadcrumbStyle(itemHoverColor:ink));
    default:throw StateError(kind);
  }
}

''';
