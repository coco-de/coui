@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/previews/examples/web/accordion/accordion_default_example.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  late pptr.Browser browser;
  late Directory fixture;
  late pptr.Page page;

  setUpAll(() async {
    fixture = Directory.systemTemp.createTempSync('remaining-layout-');
    browser = await launchCaptureBrowser(width: 1600, height: 1200);
    Component host(String id, Component child, {double width = 800}) => div(
      [child],
      id: id,
      styles: Styles(raw: {'width': '${width}px', 'display': 'flex'}),
    );
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        CoUIWeb(
          theme: .coui,
          child: div([
            host('accordion', const AccordionDefaultExample()),
            // Icon-only destinations beside one labelled one: the cells the
            // floor and the clamp below are measured on.
            host(
              'rail',
              NavigationBar(
                mode: .rail,
                selectedIndex: 0,
                onSelected: (_) {},
                labelMode: .selected,
                items: const [
                  CoreNavigationBarItem.destination(
                    icon: Icon(LucideIcons.house),
                    label: '홈',
                  ),
                  CoreNavigationBarItem.destination(
                    icon: Icon(LucideIcons.search),
                    label: '검색',
                  ),
                  CoreNavigationBarItem.destination(
                    icon: Icon(LucideIcons.bell),
                    label: '알림',
                  ),
                  CoreNavigationBarItem.destination(
                    icon: Icon(LucideIcons.user),
                    label: '프로필',
                  ),
                ],
              ),
            ),
            host(
              'toast',
              Toast(
                message: 'Message',
                description: 'Description',
                variant: .destructive,
              ),
            ),
            host(
              'hint',
              const TextField(
                placeholder: Text('YYYY'),
                textFieldStyle: CoreTextFieldStyle(
                  valueStyle: CoreTextStyle.token(CoreTextStyles.codeMd),
                  placeholderStyle: CoreTextStyle.token(
                    CoreTextStyles.bodyLarge,
                  ),
                ),
              ),
            ),
            host(
              'raw',
              const TextField(
                placeholder: Text('Hint'),
                textFieldStyle: CoreTextFieldStyle(
                  valueStyle: CoreTextStyle(fontSize: 30),
                  placeholderStyle: CoreTextStyle(
                    fontSize: 17,
                    fontWeight: 700,
                    letterSpacing: 0.05,
                    color: CoreColor(0xFF123456),
                  ),
                ),
              ),
            ),
            host(
              'raw-base',
              const TextField(
                placeholder: Text('Hint'),
                textFieldStyle: CoreTextFieldStyle(
                  baseTextStyle: CoreTextStyle(fontSize: 15),
                  valueStyle: CoreTextStyle(fontFamily: CoreFontFamily.mono),
                  placeholderStyle: CoreTextStyle(fontSize: 17),
                ),
              ),
            ),
            for (final size in [
              CoreComponentSize.sm,
              CoreComponentSize.md,
              CoreComponentSize.lg,
            ]) ...[
              host(
                'base-${size.name}',
                TextField(size: size, placeholder: const Text('Base')),
              ),
              host(
                'value-${size.name}',
                TextField(
                  size: size,
                  placeholder: const Text('Base'),
                  textFieldStyle: const CoreTextFieldStyle(
                    valueStyle: CoreTextStyle(fontSize: 40),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
    final html = buildOfflineTailwindHarnessHtml(
      bodyHtml: body,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml:
          '<style>${buildLocalFontFaceCss()}</style>${buildLocalIconifyHeadHtml()}',
    );
    final file = File('${fixture.path}/index.html')..writeAsStringSync(html);
    page = await browser.newPage();
    await page.goto(Uri.file(file.path).toString());
    await page.evaluate<void>('() => document.fonts.ready');
  });

  tearDownAll(() async {
    await browser.close();
    fixture.deleteSync(recursive: true);
  });

  Future<Map<String, dynamic>> measure(String js) async =>
      (jsonDecode(await page.evaluate<String>('() => JSON.stringify(($js)())'))
              as Map)
          .cast();

  test('an accordion hugs its content and accepts a caller width', () async {
    final m = await measure('''
() => {
      const host=document.querySelector('#accordion'), root=host.firstElementChild;
      const natural=root.getBoundingClientRect().width;
      root.classList.add('w-full');
      const full=root.getBoundingClientRect().width;
      root.classList.remove('w-full');root.style.width='320px';
      const stated=root.getBoundingClientRect().width;
      root.style.width='';host.style.width='180px';
      const narrow=root.getBoundingClientRect().width;
      host.style.display='block';host.style.width='800px';
      const blockWidth=root.getBoundingClientRect().width;
      const next=document.createElement('div');next.style.height='1px';host.appendChild(next);
      const blockGap=next.getBoundingClientRect().top-root.getBoundingClientRect().bottom;
      root.replaceChildren();
      const emptyHeight=root.getBoundingClientRect().height;
      const emptyGap=next.getBoundingClientRect().top-root.getBoundingClientRect().bottom;
      return {natural,full,stated,narrow,blockWidth,blockGap,emptyHeight,emptyGap};
    }''');
    expect(m['natural'], inExclusiveRange(200, 300));
    expect(m['full'], 800);
    expect(m['stated'], 320);
    expect(m['narrow'], lessThanOrEqualTo(180));
    expect(m['blockWidth'], 800);
    expect(m['blockGap'], closeTo(0, 0.01));
    expect(m['emptyHeight'], 0);
    expect(m['emptyGap'], closeTo(0, 0.01));
  });

  test('the rail keeps its Core floor and clamps to a narrow parent', () async {
    final m = await measure('''
() => {
      const host=document.querySelector('#rail'), root=host.querySelector('nav');
      const natural=root.getBoundingClientRect().width;
      host.style.width='60px';
      const narrow=root.getBoundingClientRect().width;
      const items=[...root.querySelectorAll('[data-coui-nav-chrome]')].map(e=>e.getBoundingClientRect().width);
      host.style.width='800px';
      root.style.width='40px';
      const ownWidth=root.getBoundingClientRect().width;
      root.style.width='';host.style.width='80px';root.style.margin='0 8px';
      const withMargin=root.getBoundingClientRect().width;
      root.style.margin='';host.style.width='800px';
      return {natural,narrow,items,ownWidth,withMargin};
    }''');
    expect(m['natural'], 81);
    expect(m['narrow'], 60);
    expect(m['ownWidth'], 40);
    expect(m['withMargin'], 64);
    expect(
      (m['items'] as List).cast<num>(),
      everyElement(lessThanOrEqualTo(43)),
    );
  });

  test(
    'toast content starts after the icon instead of at the far edge',
    () async {
      final m = await measure('''
() => {
      const host=document.querySelector('#toast'), root=host.firstElementChild;
      const text=[...root.querySelectorAll('*')].find(e=>e.textContent==='Message');
      return {start:text.getBoundingClientRect().left-root.getBoundingClientRect().left};
    }''');
      expect(m['start'], lessThan(100));
    },
  );

  test('placeholder role and face differ from the value role', () async {
    final m = await measure('''
() => {
      const input=document.querySelector('#hint input');
      const value=getComputedStyle(input), hint=getComputedStyle(input,'::placeholder');
      return {value:value.fontSize,hint:hint.fontSize,valueFamily:value.fontFamily,hintFamily:hint.fontFamily};
    }''');
    expect(m['value'], '13px');
    expect(m['hint'], '15px');
    expect(m['hintFamily'], isNot(m['valueFamily']));
  });

  test(
    'raw placeholder typography leaves the value typography alone',
    () async {
      final m = await measure('''
() => {
      const input=document.querySelector('#raw input'), hint=getComputedStyle(input,'::placeholder');
      return {value:getComputedStyle(input).fontSize,size:hint.fontSize,weight:hint.fontWeight,tracking:hint.letterSpacing,color:hint.color};
    }''');
      expect(m, {
        'value': '30px',
        'size': '17px',
        'weight': '700',
        'tracking': '0.85px',
        'color': 'rgb(18, 52, 86)',
      });
    },
  );

  test(
    'each placeholder uses its size base rather than the value override',
    () async {
      final m = await measure('''
() => {
      const result={};
      for(const size of ['sm','md','lg']) {
        const base=document.querySelector('#base-'+size+' input'), value=document.querySelector('#value-'+size+' input');
        result[size]=[getComputedStyle(base).fontSize,getComputedStyle(value,'::placeholder').fontSize];
      }
      return result;
    }''');
      for (final pair in m.values.cast<List<dynamic>>()) {
        expect(pair[1], pair[0]);
      }
    },
  );
  test('a token-less hint keeps the default face over a mono value', () async {
    final m = await measure('''
() => {
      const input=document.querySelector('#raw-base input');
      return {value:getComputedStyle(input).fontFamily,hint:getComputedStyle(input,'::placeholder').fontFamily};
    }''');
    expect(m['value'], contains(CoreFontFamily.mono));
    expect(m['hint'], contains(CoreFontFamily.sans));
    expect(m['hint'], isNot(m['value']));
  });
}
