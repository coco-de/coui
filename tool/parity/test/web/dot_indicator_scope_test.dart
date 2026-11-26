@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/dot_indicator_scope_cases.dart';

void main() {
  late Directory directory;
  late pptr.Browser browser;
  final records = <Map<String, dynamic>>[];
  final errors = <Object>[];
  const inactive = '[role="tab"]:not([aria-current]) > div';

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-dot-scope-');
    for (final theme in ['light', 'dark']) {
      final body = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          dotIndicatorScopeCases(dark: theme == 'dark'),
        ]),
      );
      File('${directory.path}/$theme.html').writeAsStringSync(
        buildOfflineTailwindHarnessHtml(
          bodyHtml: body,
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          theme: theme,
        ),
      );
    }
    browser = await launchCaptureBrowser(width: 1000, height: 1000);
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
    stderr.writeln('Dot scope proof: ${directory.path}');
  });

  for (final theme in ['light', 'dark']) {
    for (final pair in ['shared', 'equal']) {
      test(
        '$theme $pair runtime/local-key hover stays with its own theme',
        () async {
          final page = await browser.newPage();
          page.onError.listen(errors.add);
          try {
            await page.goto(
              File('${directory.path}/$theme.html').uri.toString(),
            );
            Future<Map<String, dynamic>> hover(String owner) async {
              final selector = '#$owner $inactive';
              await page.hover(selector);
              await page.waitForFunction(
                '''
(selector)=>document.querySelector(selector).matches(":hover")
''',
                args: [selector],
              );
              return (await page.$eval<Map<String, dynamic>>(
                selector,
                '''
e=>({border:getComputedStyle(e).borderColor,borderStyle:getComputedStyle(e).borderStyle,borderWidth:getComputedStyle(e).borderWidth,classes:e.className,hover:e.matches(':hover'),
owner:e.closest('[data-case]').dataset.case})''',
              ))!;
            }

            final reference = await hover('unique-a');
            final otherReference = await hover('unique-b');
            final observed = await hover('$pair-a');
            final other = await hover('$pair-b');
            records.add({
              'theme': theme,
              'pair': pair,
              'reference': reference,
              'otherReference': otherReference,
              'observed': observed,
              'other': other,
            });
            expect(reference['border'], isNot(otherReference['border']));
            expect(observed['border'], reference['border']);
            expect(other['border'], otherReference['border']);
            expect(observed['borderStyle'], 'solid');
            expect(observed['borderWidth'], '2px');
          } finally {
            await page.close();
          }
        },
      );
    }
  }
}
