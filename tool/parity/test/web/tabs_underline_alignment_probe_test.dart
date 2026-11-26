@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/tabs_alignment_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

const _measure = '''
() => {
  const rows = [];
  for (const root of document.querySelectorAll('[data-tabs-case]')) {
    for (const tab of root.querySelectorAll('[role="tab"]')) {
      const hasHeight = e => e.style.height || e.style.minHeight;
      let face = [...tab.querySelectorAll('span')].find(hasHeight);
      if (!face) {
        for (let p = tab.parentElement; p && p !== root; p = p.parentElement) {
          if (hasHeight(p)) { face = p; break; }
        }
      }
      const label = [...tab.querySelectorAll('*')].findLast(e =>
        ['Selected', 'Inactive', 'Disabled'].includes(e.textContent.trim()));
      if (!face || !label || face === label) {
        throw new Error('Missing distinct face/label for ' + root.dataset.tabsCase);
      }
      const f = face.getBoundingClientRect(), l = label.getBoundingClientRect();
      const fs = getComputedStyle(face), ls = getComputedStyle(label);
      rows.push({case:root.dataset.tabsCase, variant:root.dataset.variant,
        label:label.textContent.trim(), faceHeight:f.height, labelHeight:l.height,
        clearanceAbove:l.top-f.top, clearanceBelow:f.bottom-l.bottom,
        lineHeight:ls.lineHeight, fontSize:ls.fontSize, color:ls.color,
        boxSizing:fs.boxSizing, borderBottomWidth:fs.borderBottomWidth,
        selected:tab.getAttribute('aria-selected')});
    }
  }
  return JSON.stringify(rows);
}''';

void main() {
  late pptr.Browser browser;
  late Directory work;
  final measurements = <String, List<dynamic>>{};

  setUpAll(() async {
    // The published docs disable Tailwind preflight and supply this reset.
    // A bare Tailwind harness leaves span borders as `none`/content-box.
    final resetHead = await renderComponentBodyHtml(
      Style(styles: [...docsContentTheme().styles, ...docsPreviewStyles()]),
    );
    final body = await renderComponentBodyHtml(tabsAlignmentProbe());
    work = Directory.systemTemp.createTempSync('coui-tabs-alignment-');
    addTearDown(() => work.deleteSync(recursive: true));
    browser = await launchCaptureBrowser(
      width: 1280,
      height: 1400,
      executablePath: [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/usr/bin/google-chrome',
        '/usr/bin/chromium',
      ].firstWhere((candidate) => File(candidate).existsSync()),
    );
    addTearDown(browser.close);
    final evidence = Platform.environment['COUI_TABS_ALIGNMENT_EVIDENCE'];
    if (evidence != null) Directory(evidence).createSync(recursive: true);
    for (final theme in ['light', 'dark']) {
      final file = File('${work.path}/$theme.html')
        ..writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml: body,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            theme: theme,
            additionalHeadHtml:
                '$resetHead<style>${buildLocalFontFaceCss()} body{margin:0}</style>',
          ),
        );
      final page = await browser.newPage();
      try {
        await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
        await page.evaluate<Object?>('() => document.fonts.ready');
        for (final rem in [16, 20, 32]) {
          await page.evaluate<Object?>(
            '() => {document.documentElement.style.fontSize="${rem}px";}',
          );
          await page.evaluate<Object?>(
            '() => new Promise(r => requestAnimationFrame(() => '
            'requestAnimationFrame(r)))',
          );
          final rows =
              jsonDecode(await page.evaluate<String>(_measure)) as List;
          final key = '$theme-rem$rem';
          measurements[key] = rows;
          if (evidence != null) {
            File('$evidence/$key.json').writeAsStringSync(
              const JsonEncoder.withIndent('  ').convert(rows),
            );
            if (rem == 16) {
              File(
                '$evidence/$theme.png',
              ).writeAsBytesSync(await page.screenshot(fullPage: true));
            }
          }
        }
      } finally {
        await page.close();
      }
    }
  });

  for (final theme in ['light', 'dark']) {
    for (final rem in [16, 20, 32]) {
      test('$theme/rem$rem: each label is centered in the full face', () {
        final rows = measurements['$theme-rem$rem']!;
        expect(rows, isNotEmpty);
        for (final raw in rows) {
          final row = raw as Map<String, dynamic>;
          expect(row['boxSizing'], 'border-box');
          expect(row['labelHeight'], greaterThan(0));
          expect(row['labelHeight'], lessThan(row['faceHeight'] as num));
          expect(
            row['clearanceAbove'],
            closeTo((row['clearanceBelow'] as num).toDouble(), 0.05),
            reason: '${row['case']}/${row['label']}',
          );
        }
      });
    }
  }

  test(
    'optimized hydration retains full-height paint and real interactions',
    () async {
      final client = File('${work.path}/client.js');
      final compilation = await Process.run('dart', [
        'compile',
        'js',
        '-O2',
        'packages/coui_web/test/browser/fixtures/tabs_alignment_probe.client.dart',
        '-o',
        client.path,
      ]);
      expect(
        compilation.exitCode,
        0,
        reason: '${compilation.stdout}\n${compilation.stderr}',
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        if (request.uri.path == '/client.js') {
          request.response.headers.contentType = ContentType(
            'application',
            'javascript',
          );
          request.response.add(client.readAsBytesSync());
        } else {
          final theme = request.uri.queryParameters['theme'] == 'dark'
              ? 'dark'
              : 'light';
          final direction = request.uri.queryParameters['dir'] == 'rtl'
              ? 'rtl'
              : 'ltr';
          var html = File('${work.path}/$theme.html')
              .readAsStringSync()
              .replaceFirst('<html ', '<html dir="$direction" ')
              .replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
          if (request.uri.queryParameters['hydrate'] == 'true') {
            html = html.replaceFirst(
              '</body>',
              '<script defer src="/client.js"></script></body>',
            );
          }
          request.response.headers.contentType = ContentType.html;
          request.response.write(html);
        }
        await request.response.close();
      });
      const tabCase = '[data-tabs-case="underline-md-standard-2"]';
      const inactive = '$tabCase [role="tab"]:nth-of-type(2)';
      const disabled = '$tabCase [role="tab"][aria-disabled="true"]';
      final results = <String, Object?>{};
      for (final theme in ['light', 'dark']) {
        for (final direction in ['ltr', 'rtl']) {
          final page = await browser.newPage();
          final errors = <String>[];
          final subscription = page.onError.listen(
            (error) => errors.add('$error'),
          );
          try {
            final url =
                'http://127.0.0.1:${server.port}/'
                '?theme=$theme&dir=$direction';
            await page.goto(url, wait: .load);
            await page.evaluate<Object?>('() => document.fonts.ready');
            final before = await page.evaluate<String>(_measure);
            await page.goto('$url&hydrate=true', wait: .load);
            await page.waitForFunction(
              'document.documentElement.dataset.tabsHydrated === "true"',
            );
            await page.evaluate<Object?>('() => document.fonts.ready');
            await page.evaluate<Object?>(_settle);
            expect(
              await page.evaluate<int>(
                '() => document.querySelectorAll("[data-tabs-case]").length',
              ),
              57,
            );
            expect(
              await page.evaluate<String>(_measure),
              before,
              reason: '$theme/$direction SSR and optimized client layout',
            );
            final initialPaint = await page.evaluate<String>(_paint);
            final paintRows = jsonDecode(initialPaint) as List;
            final duration =
                CoreTabsStyle
                    .defaultIndicatorTransitionDuration
                    .inMilliseconds /
                1000;
            expect(paintRows, hasLength(90));
            for (final raw in paintRows) {
              final row = raw as Map<String, dynamic>;
              expect(row['pointerEvents'], 'none');
              expect(row['hidden'], 'true');
              expect(row['bottomDelta'], closeTo(0, 0.05));
              expect(row['widthDelta'], closeTo(0, 0.05));
              expect(
                row['duration'],
                '${duration}s',
              );
              expect(row['opacity'], row['selected'] == 'true' ? '1' : '0');
              if (row['case'] == 'raw-color' && row['selected'] == 'true') {
                expect(row['background'], 'rgb(18, 52, 86)');
                expect(row['height'], 6);
              }
            }
            // A real pointer reaches the handler even on the painted rule.
            await page.evaluate<Object?>(
              "() => document.querySelector('$inactive').scrollIntoView()",
            );
            final target =
                jsonDecode(
                      await page.evaluate<String>(
                        '''
            () => {
              const tab = document.querySelector('$inactive');
              const face = [...tab.querySelectorAll('span')]
                .find(e => e.style.height);
              const r = face.getBoundingClientRect();
              return JSON.stringify({x:r.x+r.width/2, y:r.bottom-1});
            }
          '''
                            .trim(),
                      ),
                    )
                    as Map<String, dynamic>;
            await page.mouse.click(
              Point(target['x'] as num, target['y'] as num),
            );
            await page.waitForFunction(
              'document.querySelector("#probe-state").dataset.selected === "1"',
            );
            await page.click(disabled);
            await page.evaluate<Object?>(_settle);
            final focus =
                jsonDecode(
                      await page.evaluate<String>(
                        '''
            () => {
              const e = document.activeElement, s = getComputedStyle(e);
              return JSON.stringify({role:e.getAttribute('role'),
                outlineStyle:s.outlineStyle, outlineColor:s.outlineColor,
                outlineWidth:s.outlineWidth, outlineOffset:s.outlineOffset,
                boxShadow:s.boxShadow, cursor:s.cursor});
            }
          '''
                            .trim(),
                      ),
                    )
                    as Map<String, dynamic>;
            expect(focus['role'], 'tab');
            expect(focus['outlineStyle'], isNot('auto'));
            expect(
              await page.evaluate<String>(
                '() => document.querySelector("#probe-state").dataset.selected',
              ),
              '1',
            );
            await page.click('[data-tabs-case="closable"] [aria-label]');
            await page.waitForFunction(
              'document.querySelector("#probe-state").dataset.closed === "1"',
            );
            expect(
              await page.evaluate<String>(
                '() => document.querySelector("#probe-state").dataset.selected',
              ),
              '1',
            );
            await page.focus(inactive);
            await page.keyboard.press(pptr.Key.home);
            await page.keyboard.press(pptr.Key.enter);
            await page.waitForFunction(
              'document.querySelector("#probe-state").dataset.selected === "0"',
            );
            await page.evaluate<Object?>(_settle);
            final keyboardFocus =
                jsonDecode(
                      await page.evaluate<String>(_focusChrome),
                    )
                    as Map<String, dynamic>;
            expect(keyboardFocus['role'], 'tab');
            expect(keyboardFocus['outlineStyle'], 'solid');
            expect(keyboardFocus['outlineColor'], isNot('rgba(0, 0, 0, 0)'));
            final after =
                jsonDecode(await page.evaluate<String>(_measure)) as List;
            for (final raw in after) {
              final row = raw as Map<String, dynamic>;
              expect(
                row['clearanceAbove'],
                closeTo((row['clearanceBelow'] as num).toDouble(), 0.05),
              );
            }
            expect(errors, isEmpty);
            final key = '$theme-$direction';
            results[key] = {
              'paint': paintRows,
              'after': after,
              'focus': focus,
              'keyboardFocus': keyboardFocus,
              'runtimeErrors': errors,
              'selected': 0,
              'closed': 1,
            };
            final evidence =
                Platform.environment['COUI_TABS_ALIGNMENT_EVIDENCE'];
            if (evidence != null) {
              File(
                '$evidence/release-$key.png',
              ).writeAsBytesSync(await page.screenshot(fullPage: true));
            }
          } finally {
            await subscription.cancel();
            await page.close();
          }
        }
      }
      final evidence = Platform.environment['COUI_TABS_ALIGNMENT_EVIDENCE'];
      if (evidence != null) {
        File('$evidence/release.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(results),
        );
      }
    },
  );
}

const _settle = '''
() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)))
''';

const _paint = '''
() => JSON.stringify([...document.querySelectorAll('[data-tabs-case]')].flatMap(root =>
  [...root.querySelectorAll('[role="tab"]')].flatMap(tab => {
    let face = [...tab.querySelectorAll('span')].find(e => e.style.height || e.style.minHeight);
    if (!face) face = tab.parentElement;
    const ink = [...face.children].find(e => e.style.position === 'absolute');
    if (!ink) return [];
    const f = face.getBoundingClientRect(), i = ink.getBoundingClientRect();
    const s = getComputedStyle(ink), bar = face.closest('[role="tablist"]');
    return [{case:root.dataset.tabsCase, selected:tab.getAttribute('aria-selected'),
      pointerEvents:s.pointerEvents, hidden:ink.getAttribute('aria-hidden'),
      bottomDelta:i.bottom-f.bottom, widthDelta:i.width-f.width,
      barBottomDelta:bar ? i.bottom-bar.getBoundingClientRect().bottom : null,
      height:i.height, background:s.backgroundColor, opacity:s.opacity,
      duration:s.transitionDuration}];
  })))
''';

const _focusChrome = '''
() => {
  const e = document.activeElement, s = getComputedStyle(e);
  return JSON.stringify({role:e.getAttribute('role'),
    outlineStyle:s.outlineStyle, outlineColor:s.outlineColor,
    outlineWidth:s.outlineWidth, outlineOffset:s.outlineOffset,
    boxShadow:s.boxShadow, cursor:s.cursor});
}
''';
