// Runtime compatibility of the existing public role variables. These probes
// change CSS after Tailwind has built its classes, without rebuilding Dart.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../../src/web/offline_tailwind_harness.dart';

String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

void main() {
  final chromePath = _systemChromePath();
  final config = ThemeConfig.defaults();
  final tailwind = loadVendoredTailwindScript();

  Component fixture({ThemeConfig? theme}) => Component.fragment([
    Document.head(
      children: [
        Component.element(tag: 'script', children: [RawText(tailwind)]),
        Component.element(
          tag: 'script',
          children: [RawText((theme ?? config).tailwindConfig)],
        ),
        Component.element(
          tag: 'style',
          children: [RawText((theme ?? config).cssVariables)],
        ),
      ],
    ),
    CoUIWeb(
      theme: .coui,
      typographyTier: .desktop,
      child: div([
        div([const Text('Ag').s20], id: 'label', classes: 'text-label-large'),
        div([const Text('Ag').s20], id: 'code', classes: 'text-code-sm'),
        div(
          [const Text('Ag').s20],
          id: 'raw',
          classes: 'text-label-large',
          styles: const Styles(raw: {'font-size': '1.25rem'}),
        ),
        div(
          [const Text('Ag').s20],
          id: 'scaled-label',
          classes: 'text-label-large',
          styles: const Styles(
            raw: {
              'font-size': 'calc(var(--coui-text-label-large-size) * 1.5)',
              '--coui-text-scale': '1.5',
            },
          ),
        ),
        div(
          [const Text('Ag').s20],
          id: 'scaled-code',
          classes: 'text-code-sm',
          styles: const Styles(
            raw: {
              'font-size': 'calc(var(--coui-text-code-sm-size) * 1.5)',
              '--coui-text-scale': '1.5',
            },
          ),
        ),
      ]),
    ),
  ]);

  Future<Map<String, dynamic>> measure(
    String html,
    String mutate, {
    String? read,
  }) async {
    final temp = Directory.systemTemp.createTempSync('coui-typography-compat-');
    final browser = await pptr.puppeteer.launch(executablePath: chromePath);
    try {
      final file = File(p.join(temp.path, 'fixture.html'))
        ..writeAsStringSync(html);
      final page = await browser.newPage();
      await page.setOfflineMode(true);
      await page.goto(Uri.file(file.path).toString(), wait: pptr.Until.load);
      await page.evaluate<void>(mutate);
      return jsonDecode(
            await page.evaluate<String>(
              read ??
                  '''
() => JSON.stringify({
        values: Object.fromEntries(['label', 'code', 'raw', 'scaled-label', 'scaled-code'].map(id => {
          const el = document.getElementById(id);
          return [id, {
            line: parseFloat(getComputedStyle(el).lineHeight),
            child: parseFloat(getComputedStyle(el.firstElementChild).lineHeight),
          }];
        })),
        syntax: [...document.styleSheets].flatMap(sheet => [...sheet.cssRules])
          .filter(rule => rule.constructor.name === 'CSSPropertyRule')
          .map(rule => ({name: rule.name, syntax: rule.syntax})),
      })''',
            ),
          )
          as Map<String, dynamic>;
    } finally {
      await browser.close();
      temp.deleteSync(recursive: true);
    }
  }

  testServer(
    'a runtime typography block may change both line-height types',
    (tester) async {
      tester.pumpComponent(fixture());
      final replacement = ThemeConfig.typographyCssBlock(
        CoreTypography.coui.copyWith(
          labelLarge: const CoreTextStyle(fontSize: 14, lineHeightPx: 28),
          codeSm: const CoreTextStyle(fontSize: 12, lineHeight: 1.4),
        ),
      );
      final result = await measure(
        (await tester.request('/')).body,
        '''
() => {
  const s = document.createElement("style");
  s.textContent = ${jsonEncode(replacement)};
  document.head.append(s);
}
''',
      );
      final values = result['values'] as Map;
      expect((values['label'] as Map)['line'], 28);
      expect((values['label'] as Map)['child'], 40);
      expect((values['code'] as Map)['line'], 17);
      expect((values['code'] as Map)['child'], 28);
      expect((values['raw'] as Map)['line'], 28);
      expect((values['scaled-label'] as Map)['line'], 42);
      expect((values['scaled-label'] as Map)['child'], 40);
      expect((values['scaled-code'] as Map)['line'], 25);
      expect((values['scaled-code'] as Map)['child'], 28);
      final syntax = result['syntax'] as List;
      for (final (name, type) in const [
        ('--coui-text-scale', '<number>'),
      ]) {
        expect(syntax, anyElement(equals({'name': name, 'syntax': type})));
      }
    },
    skip: chromePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testServer(
    'same-type source variable overrides remain live on the role element',
    (tester) async {
      tester.pumpComponent(fixture());
      final result = await measure((await tester.request('/')).body, '''
() => {
      for (const id of ['label', 'scaled-label', 'raw']) {
        document.getElementById(id).style.setProperty('--coui-text-label-large-line-height', '1.37');
      }
      for (const id of ['code', 'scaled-code']) {
        document.getElementById(id).style.setProperty('--coui-text-code-sm-line-height', '27.25px');
      }
    }''');
      final values = result['values'] as Map;
      expect((values['label'] as Map)['line'], 19);
      expect((values['raw'] as Map)['line'], 27);
      expect((values['code'] as Map)['line'], 27);
      expect((values['scaled-label'] as Map)['line'], 29);
      expect((values['scaled-code'] as Map)['line'], 41);
    },
    skip: chromePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testServer(
    'role boxes retain fractional number/length inputs, CSS vars and scaling',
    (tester) async {
      tester.pumpComponent(fixture());
      // Independent used values: no string is parsed by production Dart.
      const cases = [
        ('0', false, 1.0, 0),
        ('0.25', false, 1.0, 4),
        ('1.4', false, 1.0, 20),
        ('1.37', false, 0.5, 10),
        ('1.625', false, 1.5, 34),
        ('calc(1 + 0.37)', false, 2.0, 38),
        ('var(--caller-leading)', false, 1.0, 19),
        ('0px', true, 1.0, 0),
        ('0.25px', true, 1.0, 0),
        ('17px', true, 1.0, 17),
        ('21.5px', true, 0.5, 11),
        ('1.3125rem', true, 1.5, 32),
        ('calc(1rem + 3px)', true, 2.0, 38),
        ('var(--caller-box)', true, 1.0, 27),
      ];
      final inputs = [
        for (final (value, fixed, scale, _) in cases)
          {'value': value, 'fixed': fixed, 'scale': scale},
      ];
      final result = await measure(
        (await tester.request('/')).body,
        '''
() => {
  window.compatInputs = ${jsonEncode(inputs)}.map(input => {
    const el = document.getElementById(input.fixed ? 'code' : 'label');
    const source = input.fixed ? 'code-sm' : 'label-large';
    el.style.setProperty('--caller-leading', '1.37');
    el.style.setProperty('--caller-box', '27.25px');
    el.style.setProperty('--coui-text-' + source + '-line-height', input.value);
    el.style.setProperty('--coui-text-scale', input.scale);
    el.style.fontSize = (14 * input.scale) + 'px';
    return {
      line: parseFloat(getComputedStyle(el).lineHeight),
      child: parseFloat(getComputedStyle(el.firstElementChild).lineHeight),
    };
  });
}
''',
        read: '() => JSON.stringify({inputs: window.compatInputs})',
      );
      final actual = result['inputs'] as List;
      for (final (index, (value, fixed, scale, line)) in cases.indexed) {
        expect(
          (actual[index] as Map)['line'],
          line,
          reason: '$value (fixed=$fixed, scale=$scale)',
        );
      }
    },
    skip: chromePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testServer(
    'an initially unstated role line height keeps native inheritance',
    (tester) async {
      tester.pumpComponent(
        fixture(
          theme: ThemeConfig.from(
            CouiColorPresets.source,
            typography: CoreTypography.coui.copyWith(
              labelLarge: const CoreTextStyle(fontSize: 14),
            ),
          ),
        ),
      );
      final result = await measure(
        (await tester.request('/')).body,
        '() => {}',
      );
      final values = result['values'] as Map;
      expect((values['label'] as Map)['line'], 21);
      expect((values['label'] as Map)['child'], 30);
    },
    skip: chromePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testServer(
    'rem boxes follow browser root text scaling',
    (tester) async {
      tester.pumpComponent(fixture());
      final replacement = ThemeConfig.typographyCssBlock(
        CoreTypography.coui.copyWith(
          labelLarge: const CoreTextStyle(fontSize: 14, lineHeightPx: 21),
        ),
      );
      final result = await measure((await tester.request('/')).body, '''
() => {
  const s = document.createElement('style');
  s.textContent = ${jsonEncode(replacement)};
  document.head.append(s);
  document.documentElement.style.fontSize = '20px';
}
''');
      final values = result['values'] as Map;
      expect((values['label'] as Map)['line'], 26);
      expect((values['label'] as Map)['child'], 38);
      expect((values['scaled-label'] as Map)['line'], 39);
      expect((values['scaled-label'] as Map)['child'], 38);
    },
    skip: chromePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testServer(
    'a previously unstated role accepts a later multiplier variable',
    (tester) async {
      tester.pumpComponent(
        fixture(
          theme: ThemeConfig.from(
            CouiColorPresets.source,
            typography: CoreTypography.coui.copyWith(
              labelLarge: const CoreTextStyle(fontSize: 14),
            ),
          ),
        ),
      );
      final result = await measure((await tester.request('/')).body, '''
() => {
  document.getElementById('label').style.setProperty(
    '--coui-text-label-large-line-height', '2');
}
''');
      final values = result['values'] as Map;
      expect((values['label'] as Map)['line'], 28);
    },
    skip: chromePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testServer(
    'clearing source and public flag variables preserves CSS defaults',
    (tester) async {
      tester.pumpComponent(fixture());
      final result = await measure((await tester.request('/')).body, '''
() => {
  const el = document.getElementById('label');
  const line = () => parseFloat(getComputedStyle(el).lineHeight);
  const values = {initial: line()};
  el.style.setProperty('--coui-text-label-large-line-box', 'initial');
  values.clearedFlag = line();
  el.style.removeProperty('--coui-text-label-large-line-box');
  values.removedFlag = line();
  el.style.setProperty('--coui-text-label-large-line-box', '0');
  values.restoredFlag = line();
  el.style.setProperty('--coui-text-label-large-line-height', 'initial');
  values.clearedSource = line();
  el.style.removeProperty('--coui-text-label-large-line-height');
  values.restoredSource = line();
  window.compatCleared = values;
}
''', read: '() => JSON.stringify(window.compatCleared)');
      expect(
        result,
        equals({
          'initial': 20,
          'clearedFlag': 20,
          'removedFlag': 20,
          'restoredFlag': 20,
          'clearedSource': 21,
          'restoredSource': 20,
        }),
      );
    },
    skip: chromePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
