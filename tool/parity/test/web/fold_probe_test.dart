// The fold transport in a real browser: what the viewport segments and the
// posture query read as through `FoldScope.of`, and where a dialog, a drawer
// and an anchored panel open across a fold. The VM tests read the rule
// against the shared table; only a browser has segments, a posture query and
// `env(viewport-segment-*)`.
//
// Chrome is told about the fold through DevTools emulation: the display
// feature of its device metrics, and its device posture. Both reach the
// page's segments, its `env(viewport-segment-*)` values and its posture
// query. Measured on Chrome 158, the newer display-features override returns
// success and reaches none of them, and desktop Chrome has no script posture
// object — which is why the probe sends the metrics call itself and the
// runtime reads the posture from CSS.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// The dialog panel's box, as drawn: `[left, top, right, bottom]`.
const _kPanel = '''
() => {
  const r = document.querySelector('[role="dialog"]').getBoundingClientRect();
  return [r.left, r.top, r.right, r.bottom];
}''';

/// The drawer panel's box, as drawn, or null before it is in the page.
const _kDrawerPanel = '''
() => {
  const content = document.getElementById('probe-drawer-content');
  if (!content) return null;
  const r = content.closest('[role="dialog"]').getBoundingClientRect();
  return [r.left, r.top, r.right, r.bottom];
}''';

/// The anchored panel's box, as drawn, or null before it is in the page.
const _kAnchoredPanel = '''
() => {
  const content = document.getElementById('probe-popover-content');
  if (!content) return null;
  const panel = content.closest('[id^="co-popover-panel-"]') || content;
  const r = panel.getBoundingClientRect();
  return [r.left, r.top, r.right, r.bottom];
}''';

void main() {
  final chrome = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
  ].where((path) => File(path).existsSync()).firstOrNull;
  Browser? browser;
  late Directory fixture;
  late File html;
  final pages = <Page>[];

  Future<void> settle(Page page) => page.evaluate<void>(
    '() => new Promise(r => '
    'requestAnimationFrame(() => requestAnimationFrame(r)))',
  );

  /// Tells [page] its viewport is [width] × [height], split by [feature]
  /// (`{orientation, offset, maskLength}`) or by nothing, and folded as
  /// [posture] (`continuous` or `folded`).
  Future<void> emulate(
    Page page, {
    required int width,
    required int height,
    Map<String, Object>? feature,
    String posture = 'continuous',
  }) async {
    await page.devTools.client.send('Emulation.setDeviceMetricsOverride', {
      'width': width,
      'height': height,
      'deviceScaleFactor': 1,
      'mobile': false,
      'displayFeature': ?feature,
    });
    await page.devTools.client.send('Emulation.setDevicePostureOverride', {
      'posture': {'type': posture},
    });
  }

  Future<Page> openPage({
    required int width,
    required int height,
    Map<String, Object>? feature,
    String posture = 'continuous',
    bool rtl = false,
    (int, int)? anchor,
  }) async {
    final page = await browser!.newPage();
    pages.add(page);
    await emulate(
      page,
      width: width,
      height: height,
      feature: feature,
      posture: posture,
    );
    final query = [
      if (rtl) 'rtl',
      if (anchor case (final x, final y)) ...['ax=$x', 'ay=$y'],
    ].join('&');
    await page.goto(
      '${Uri.file(html.path)}${query.isEmpty ? '' : '?$query'}',
      wait: Until.load,
    );
    await page.waitForFunction('typeof couiFoldRead === "function"');
    await settle(page);

    return page;
  }

  Future<Map<String, dynamic>> read(Page page) async =>
      jsonDecode(await page.evaluate<String>('() => couiFoldRead()'))
          as Map<String, dynamic>;

  Future<List<double>> openDialog(Page page) async {
    await page.evaluate<void>('() => couiFoldOpen()');
    await page.waitForSelector('[role="dialog"]');
    await settle(page);

    return [
      for (final value in await page.evaluate<List<dynamic>>(_kPanel))
        (value as num).toDouble(),
    ];
  }

  /// The box [script] reads, once it is in the page and has stopped moving:
  /// a drawer slides in and an anchored panel is placed a frame after it
  /// mounts.
  Future<List<double>> settledBox(Page page, String script) async {
    List<double>? previous;
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final raw = await page.evaluate<List<dynamic>?>(script);
      final box = raw == null
          ? null
          : [for (final value in raw) (value as num).toDouble()];
      if (box != null && previous != null) {
        var same = true;
        for (var edge = 0; edge < 4; edge++) {
          if (box[edge] != previous[edge]) same = false;
        }
        if (same) return box;
      }
      previous = box;
    }
    fail('the panel never came to rest');
  }

  Future<List<double>> openDrawer(Page page, String side) async {
    await page.evaluate<void>(
      '(side) => couiFoldOpenDrawer(side)',
      args: [side],
    );
    final box = await settledBox(page, _kDrawerPanel);

    return box;
  }

  Future<List<double>> openAnchored(Page page) async {
    await page.evaluate<void>('() => couiFoldOpenPopover()');
    final box = await settledBox(page, _kAnchoredPanel);

    return box;
  }

  const book = {'orientation': 'vertical', 'offset': 420, 'maskLength': 0};
  const stand = {'orientation': 'horizontal', 'offset': 502, 'maskLength': 0};

  group(
    'folds in Chrome',
    () {
      setUpAll(() async {
        if (chrome == null) return;
        fixture = Directory.systemTemp.createTempSync('coui-fold-');
        final js = '${fixture.path}/entry.js';
        final result = await Process.run(Platform.resolvedExecutable, [
          'compile',
          'js',
          '-O2',
          '-o',
          js,
          'tool/parity/src/web/fold_entry.dart',
        ]);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        html = File('${fixture.path}/index.html')
          ..writeAsStringSync(
            buildOfflineTailwindHarnessHtml(
              bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
              themeConfig: ThemeConfig.defaults(),
              vendoredTailwindScript: loadVendoredTailwindScript(),
            ),
          );
        browser = await launchCaptureBrowser(
          width: 900,
          height: 1100,
          executablePath: chrome,
        );
      });
      tearDown(() async {
        for (final page in pages) {
          await page.close();
        }
        pages.clear();
      });
      tearDownAll(() async {
        if (chrome == null) return;
        await browser?.close();
        fixture.deleteSync(recursive: true);
      });

      test("the panel's sizes take in its padding, as Flutter's do", () async {
        // The kit turns Tailwind's preflight off, so a box is sized by its
        // content unless it says otherwise; the Flutter panel's cap and its
        // room inside the route take in the padding. Measured without a fold:
        // the cap (640) on a wide page, the page less the route's padding on
        // a narrow one.
        for (final (width, expected) in [(840, 640.0), (400, 368.0)]) {
          final page = await openPage(width: width, height: 900);
          final panel = await openDialog(page);
          expect(panel[2] - panel[0], expected, reason: 'at $width');
        }
      });

      test('a viewport with no fold is one segment with no kind', () async {
        final page = await openPage(width: 840, height: 900);

        expect(await read(page), {
          'kind': null,
          'posture': null,
          'split': false,
          'segments': [
            [0, 0, 840, 900],
          ],
        });
      });

      test('a fold half open as a book opens a dialog on the left', () async {
        final page = await openPage(
          width: 840,
          height: 900,
          feature: {'orientation': 'vertical', 'offset': 420, 'maskLength': 0},
          posture: 'folded',
        );

        expect(await read(page), {
          'kind': 'fold',
          'posture': 'book',
          'split': true,
          'segments': [
            [0, 0, 420, 900],
            [420, 0, 420, 900],
          ],
        });
        final panel = await openDialog(page);
        expect(panel[0], greaterThanOrEqualTo(0));
        expect(panel[2], lessThanOrEqualTo(420));
      });

      test('read right to left, it opens on the right', () async {
        final page = await openPage(
          width: 840,
          height: 900,
          feature: {'orientation': 'vertical', 'offset': 420, 'maskLength': 0},
          posture: 'folded',
          rtl: true,
        );

        final panel = await openDialog(page);
        expect(panel[0], greaterThanOrEqualTo(420));
        expect(panel[2], lessThanOrEqualTo(840));
      });

      test('a flip in its stand opens a dialog on the upper half', () async {
        final page = await openPage(
          width: 412,
          height: 1004,
          feature: {
            'orientation': 'horizontal',
            'offset': 502,
            'maskLength': 0,
          },
          posture: 'folded',
        );

        final fold = await read(page);
        expect(fold['kind'], 'flip');
        expect(fold['posture'], 'tabletop');
        final panel = await openDialog(page);
        expect(panel[1], greaterThanOrEqualTo(0));
        expect(panel[3], lessThanOrEqualTo(502));
      });

      test(
        'a seamless fold lying flat is one surface the dialog spans',
        () async {
          // The emulator splits the viewport even while the posture is
          // continuous; the rule reads a seamless fold that lies flat as one
          // surface, as Flutter reads the same fold.
          final page = await openPage(
            width: 840,
            height: 900,
            feature: {
              'orientation': 'vertical',
              'offset': 420,
              'maskLength': 0,
            },
          );

          final fold = await read(page);
          expect(fold['split'], isFalse);
          expect(fold['kind'], 'fold');
          expect(fold['posture'], 'flat');
          final panel = await openDialog(page);
          expect(panel[0], lessThan(420));
          expect(panel[2], greaterThan(420));
        },
      );

      test('a hinge splits the viewport however it is folded', () async {
        final page = await openPage(
          width: 874,
          height: 900,
          feature: {
            'orientation': 'vertical',
            'offset': 420,
            'maskLength': 34,
          },
        );

        expect(await read(page), {
          'kind': 'fold',
          'posture': 'flat',
          'split': true,
          'segments': [
            [0, 0, 420, 900],
            [454, 0, 420, 900],
          ],
        });
        final panel = await openDialog(page);
        expect(panel[2], lessThanOrEqualTo(420));
      });

      test('an open dialog moves when the device folds', () async {
        final page = await openPage(width: 840, height: 900);
        final before = await openDialog(page);
        expect(before[0], lessThan(420));
        expect(before[2], greaterThan(420));

        await emulate(
          page,
          width: 840,
          height: 900,
          feature: {'orientation': 'vertical', 'offset': 420, 'maskLength': 0},
          posture: 'folded',
        );
        await page.waitForFunction(
          '() => JSON.parse(couiFoldRead()).split === true',
        );
        await settle(page);

        final after = [
          for (final value in await page.evaluate<List<dynamic>>(_kPanel))
            (value as num).toDouble(),
        ];
        expect(after[2], lessThanOrEqualTo(420));
      });

      test('a fold half open as a book docks a bottom drawer in the left '
          'half, and a right drawer in the right', () async {
        final bottom = await openDrawer(
          await openPage(
            width: 840,
            height: 900,
            feature: book,
            posture: 'folded',
          ),
          'bottom',
        );
        expect(bottom[0], closeTo(0, 0.5));
        expect(bottom[2], closeTo(420, 0.5));
        expect(bottom[3], closeTo(900, 0.5));

        final right = await openDrawer(
          await openPage(
            width: 840,
            height: 900,
            feature: book,
            posture: 'folded',
          ),
          'right',
        );
        expect(right[0], greaterThanOrEqualTo(420));
        expect(right[2], closeTo(840, 0.5));
        expect(right[1], closeTo(0, 0.5));
        expect(right[3], closeTo(900, 0.5));
      });

      test('read right to left, the bottom drawer docks in the right '
          'half', () async {
        final panel = await openDrawer(
          await openPage(
            width: 840,
            height: 900,
            feature: book,
            posture: 'folded',
            rtl: true,
          ),
          'bottom',
        );

        expect(panel[0], closeTo(420, 0.5));
        expect(panel[2], closeTo(840, 0.5));
      });

      test('a flip in its stand docks a bottom drawer in the lower half, '
          'and a left drawer in the upper', () async {
        final bottom = await openDrawer(
          await openPage(
            width: 412,
            height: 1004,
            feature: stand,
            posture: 'folded',
          ),
          'bottom',
        );
        expect(bottom[1], greaterThanOrEqualTo(502));
        expect(bottom[3], closeTo(1004, 0.5));
        expect(bottom[0], closeTo(0, 0.5));
        expect(bottom[2], closeTo(412, 0.5));

        final left = await openDrawer(
          await openPage(
            width: 412,
            height: 1004,
            feature: stand,
            posture: 'folded',
          ),
          'left',
        );
        expect(left[0], closeTo(0, 0.5));
        expect(left[1], closeTo(0, 0.5));
        expect(left[3], closeTo(502, 0.5));
      });

      test('a narrow half caps a side drawer at its width', () async {
        // The side panel is 400 wide; a half of 300 holds it at 300.
        final panel = await openDrawer(
          await openPage(
            width: 600,
            height: 900,
            feature: {
              'orientation': 'vertical',
              'offset': 300,
              'maskLength': 0,
            },
            posture: 'folded',
          ),
          'left',
        );

        expect(panel[0], closeTo(0, 0.5));
        expect(panel[2], closeTo(300, 0.5));
      });

      test('across a seamless fold lying flat the drawer spans the '
          'viewport', () async {
        final panel = await openDrawer(
          await openPage(width: 840, height: 900, feature: book),
          'bottom',
        );

        expect(panel[0], closeTo(0, 0.5));
        expect(panel[2], closeTo(840, 0.5));
      });

      test('an open drawer moves when the device folds', () async {
        final page = await openPage(width: 840, height: 900);
        final before = await openDrawer(page, 'bottom');
        expect(before[2], closeTo(840, 0.5));

        await emulate(
          page,
          width: 840,
          height: 900,
          feature: book,
          posture: 'folded',
        );
        await page.waitForFunction(
          '() => JSON.parse(couiFoldRead()).split === true',
        );

        final after = await settledBox(page, _kDrawerPanel);
        expect(after[2], closeTo(420, 0.5));
      });

      test('an anchored panel stays in the half its trigger is in', () async {
        // The panel is 280 wide and opens centred under its trigger: beside
        // the fold it would reach across.
        final inLeft = await openAnchored(
          await openPage(
            width: 840,
            height: 900,
            feature: book,
            posture: 'folded',
            anchor: (360, 300),
          ),
        );
        expect(inLeft[0], greaterThanOrEqualTo(0));
        expect(inLeft[2], lessThanOrEqualTo(420));

        final inRight = await openAnchored(
          await openPage(
            width: 840,
            height: 900,
            feature: book,
            posture: 'folded',
            anchor: (440, 300),
          ),
        );
        expect(inRight[0], greaterThanOrEqualTo(420));
        expect(inRight[2], lessThanOrEqualTo(840));
      });

      test('a flip in its stand flips an anchored panel back into its '
          'half', () async {
        // Under a trigger just above the fold the panel would cross it.
        final panel = await openAnchored(
          await openPage(
            width: 412,
            height: 1004,
            feature: stand,
            posture: 'folded',
            anchor: (186, 440),
          ),
        );

        expect(panel[1], greaterThanOrEqualTo(0));
        expect(panel[3], lessThanOrEqualTo(502));
      });

      test('across a seamless fold lying flat an anchored panel is placed '
          'as with no fold', () async {
        final withFold = await openAnchored(
          await openPage(
            width: 840,
            height: 900,
            feature: book,
            anchor: (400, 300),
          ),
        );
        final withNone = await openAnchored(
          await openPage(width: 840, height: 900, anchor: (400, 300)),
        );

        expect(withFold, withNone);
        expect(withFold[0], lessThan(420));
        expect(withFold[2], greaterThan(420));
      });
    },
    skip: chrome == null ? 'Chrome is unavailable' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
