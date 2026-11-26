@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:html/parser.dart' as html;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../../packages/coui_web/test/browser/fixtures/roving_owner_probe.dart';
import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

const _groups = [
  'tabs-shared-a',
  'tabs-shared-b',
  'tabs-explicit-a',
  'tabs-explicit-b',
  'toggle-shared-a',
  'toggle-shared-b',
  'toggle-explicit-a',
  'toggle-explicit-b',
];
const _readOwners = '''
() => Object.fromEntries([...document.querySelectorAll('[data-roving-case]')]
  .map(root => [root.dataset.rovingCase,
    [...root.querySelectorAll('[data-roving-item]')]
      .map(item => item.getAttribute('data-roving-item'))]))
''';

void main() {
  late Directory work;
  late pptr.Browser browser;
  late String body;
  final evidence = Platform.environment['COUI_ROVING_OWNER_EVIDENCE'];
  final errors = <String>[];
  final requests = <String>[];

  void record(String name, Object? value) {
    if (evidence != null) {
      Directory(evidence).createSync(recursive: true);
      File('$evidence/$name.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(value),
      );
    }
  }

  Future<pptr.Page> page() async {
    final result = await browser.newPage();
    result.onError.listen((error) => errors.add('$error'));
    result.onConsole.listen((event) {
      if (event.type == pptr.ConsoleMessageType.error) {
        errors.add(event.text ?? 'console error');
      }
    });
    result.onRequest.listen((request) {
      if (!request.url.startsWith('file:') &&
          !request.url.startsWith('data:')) {
        requests.add(request.url);
      }
    });
    await result.goto(
      Uri.file('${work.path}/hydrated.html').toString(),
    );
    await result.waitForFunction(
      'document.documentElement.dataset.rovingReady === "true"',
    );
    addTearDown(result.close);
    return result;
  }

  setUpAll(() async {
    work = Directory.systemTemp.createTempSync('coui-roving-owner-');
    // Retain the generated SSR/O2 artifacts when evidence is requested.
    record('work', {'path': work.path});
    body = await renderComponentBodyHtml(rovingOwnerProbe());
    final document = buildOfflineTailwindHarnessHtml(
      bodyHtml: body,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
    );
    File('${work.path}/ssr.html').writeAsStringSync(document);
    File('${work.path}/hydrated.html').writeAsStringSync(
      document.replaceFirst(
        '</body>',
        '<script defer src="client.js"></script></body>',
      ),
    );
    final compilation = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      if (Platform.environment['COUI_ROVING_PACKAGE_CONFIG'] case final config?)
        '--packages=$config',
      'packages/coui_web/test/browser/fixtures/roving_owner_probe.client.dart',
      '-o',
      '${work.path}/client.js',
    ]);
    record('compilation', {
      'exit': compilation.exitCode,
      'stdout': '${compilation.stdout}',
      'stderr': '${compilation.stderr}',
    });
    expect(compilation.exitCode, 0, reason: '${compilation.stderr}');
    browser = await launchCaptureBrowser(width: 1000, height: 900);
    record('browser', {
      'version': await browser.version,
      'pid': browser.process?.pid,
    });
    addTearDown(() async {
      final pid = browser.process?.pid;
      await browser.close();
      if (browser.process case final process?) await process.exitCode;
      record('cleanup', {
        'browserCloseAwaited': true,
        'pid': pid,
        'pidClosed':
            pid == null ||
            (await Process.run('kill', ['-0', '$pid'])).exitCode != 0,
        'errors': errors,
        'externalRequests': requests,
        'servers': 0,
      });
    });
  });

  test(
    'SSR isolates repeated const collections and preserves explicit IDs',
    () {
      final parsed = html.parse(body);
      final owners = <String, List<String>>{
        for (final root in parsed.querySelectorAll('[data-roving-case]'))
          root.attributes['data-roving-case']!: [
            for (final item in root.querySelectorAll('[data-roving-item]'))
              item.attributes['data-roving-item']!,
          ],
      };
      record('ssr-owners', owners);
      expect(owners, hasLength(10));
      final all = owners.values.expand((values) => values).toList();
      expect(all.toSet(), hasLength(all.length));
      for (final component in ['tabs', 'toggle']) {
        for (final suffix in ['a', 'b']) {
          expect(owners['$component-explicit-$suffix'], [
            for (var i = 0; i < 3; i++) 'caller-$component-$suffix:$i',
          ]);
        }
      }
    },
  );

  for (final component in ['tabs', 'toggle']) {
    test(
      'O2 $component keys stay within each repeated/explicit group',
      () async {
        final client = await page();
        final owners = await client.evaluate<Map<String, dynamic>>(_readOwners);
        final rows = <Map<String, Object?>>[];
        for (final group in _groups.where(
          (name) => name.startsWith(component),
        )) {
          final keys = [
            ('ArrowRight', pptr.Key.arrowRight, 1),
            ('ArrowLeft', pptr.Key.arrowLeft, 2),
            ('Home', pptr.Key.home, 0),
            ('End', pptr.Key.end, 2),
            if (component == 'toggle') ...[
              ('ArrowDown', pptr.Key.arrowDown, 1),
              ('ArrowUp', pptr.Key.arrowUp, 2),
            ],
            ('Enter', pptr.Key.enter, 1),
            ('Space', pptr.Key.space, 1),
          ];
          for (final (name, key, expectedIndex) in keys) {
            final activation = name == 'Enter' || name == 'Space';
            await client.evaluate<void>(
              '''
(group, index) => document.querySelectorAll(
              '[data-roving-case="'+group+'"] [data-roving-item]')[index].focus()''',
              args: [group, if (activation) 1 else 0],
            );
            final before = await client.evaluate<String>(
              '() => document.documentElement.dataset.rovingEvents',
            );
            await client.keyboard.press(key);
            final actual = await client.evaluate<Map<String, dynamic>>('''
() => {
  const focused = document.activeElement;
  return {group:focused.closest('[data-roving-case]')?.dataset.rovingCase,
    index:Number(focused.getAttribute('data-roving-item')?.split(':').at(-1)),
    events:JSON.parse(document.documentElement.dataset.rovingEvents)};
}''');
            final oldEvents = jsonDecode(before) as List<dynamic>;
            final actualEvents = actual['events'] as List<dynamic>;
            final expectedEvents = [
              ...oldEvents,
              if (component == 'toggle' || activation)
                if (component == 'tabs')
                  'tab:$expectedIndex'
                else
                  'toggle:${['alpha', 'beta', 'gamma'][expectedIndex]}',
            ];
            rows.add({
              'group': group,
              'key': name,
              'expectedIndex': expectedIndex,
              'actual': actual,
              'focusCorrect':
                  actual['group'] == group && actual['index'] == expectedIndex,
              'activationCorrect':
                  jsonEncode(actualEvents) == jsonEncode(expectedEvents),
            });
          }
        }
        record('$component-keys', {'owners': owners, 'rows': rows});
        expect(rows.every((row) => row['focusCorrect'] == true), isTrue);
        expect(rows.every((row) => row['activationCorrect'] == true), isTrue);
        expect(errors, isEmpty);
        expect(requests, isEmpty);
      },
    );
  }

  test('Element owners survive rebuilds and change on keyed remount', () async {
    final client = await page();
    final before = await client.evaluate<Map<String, dynamic>>(_readOwners);
    await client.click('#rebuild');
    await client.waitForFunction(
      'document.querySelector("#revision").dataset.revision === "1"',
    );
    final rebuilt = await client.evaluate<Map<String, dynamic>>(_readOwners);
    await client.click('#remount');
    await client.waitForFunction(
      'document.querySelector("#revision").dataset.mount === "1"',
    );
    final remounted = await client.evaluate<Map<String, dynamic>>(_readOwners);
    record('lifetime', {
      'before': before,
      'rebuilt': rebuilt,
      'remounted': remounted,
    });
    expect(rebuilt, before);
    for (final component in ['tabs', 'toggle']) {
      expect(
        remounted['$component-lifecycle'],
        isNot(before['$component-lifecycle']),
      );
    }
    for (final group in _groups) {
      expect(remounted[group], before[group]);
    }
  });
}
