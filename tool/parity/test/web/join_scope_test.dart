@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/join_scope_cases.dart';

void main() {
  late Directory directory;
  late pptr.Browser browser;
  final records = <Map<String, dynamic>>[];
  final errors = <Object>[];
  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-join-scope-');
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        joinScopeCases(),
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
    browser = await launchCaptureBrowser(
      width: 1000,
      height: 1000,
      executablePath: Platform.environment['PUPPETEER_EXECUTABLE_PATH'],
    );
  });
  tearDownAll(() async {
    await browser.close();
    File('${directory.path}/observed.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'records': records,
        'errors': errors.map((e) => '$e').toList(),
        'browserCloseAwaited': true,
      }),
    );
    stderr.writeln('Join scope proof: ${directory.path}');
    expect(errors, isEmpty);
  });

  for (final theme in ['light', 'dark']) {
    for (final pair in ['shared', 'equal']) {
      test(
        '$theme $pair radius and axis values belong to each owner',
        () async {
          final page = await browser.newPage();
          page.onError.listen(errors.add);
          try {
            await page.goto(
              File('${directory.path}/$theme.html').uri.toString(),
            );
            await page.evaluate<void>('()=>document.fonts.ready');
            Future<Map<String, dynamic>> read(String owner) => page.evaluate(
              '''
owner=>{const root=document.querySelector('#'+owner+' > [data-join-case]');
const wrappers=[...root.children].filter(e=>e.tagName==='DIV');
return {id:root.id,
classes:root.className,
firstTag:root.firstElementChild.tagName,
items:wrappers.map(w=>{const e=w.firstElementChild,
s=getComputedStyle(e),
ws=getComputedStyle(w);
return {radius:[s.borderTopLeftRadius,
s.borderTopRightRadius,
s.borderBottomRightRadius,
s.borderBottomLeftRadius],
wrapperRadius:ws.borderRadius,
minWidth:s.minWidth,
minHeight:s.minHeight,
boxSizing:s.boxSizing};
})};
}''',
              args: [owner],
            );
            final a = await read(
              pair == 'shared' ? 'unique-a' : 'equal-reference-a',
            );
            final b = await read(
              pair == 'shared' ? 'unique-b' : 'equal-reference-b',
            );
            final observedA = await read('$pair-a');
            final observedB = await read('$pair-b');
            records.add({
              'theme': theme,
              'pair': pair,
              'referenceA': a,
              'referenceB': b,
              'observedA': observedA,
              'observedB': observedB,
            });
            expect(a['items'], isNot(b['items']));
            expect(observedA['items'], a['items']);
            expect(observedB['items'], b['items']);
            expect(observedA['firstTag'], 'STYLE');
            expect(
              observedA['id'],
              observedB['id'],
              reason: 'legacy duplicate DOM IDs remain an explicit boundary',
            );
          } finally {
            await page.close();
          }
        },
      );
    }
  }
}
