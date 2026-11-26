@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import 'fixtures/composed_control_paint_probe.dart';

const _cases = [
  'switch-off',
  'switch-on',
  'multiple-flat',
  'chip-ramp',
  'carousel-slide',
  'carousel-banner',
  'carousel-caller',
];
const _readCase = '''
id => {
  const root = document.querySelector('[data-case="'+id+'"]');
  const content = root.querySelector('[data-component-case]');
  const faces = id.startsWith('switch') ? [content.querySelector('.co-toggle-track')]
    : id.startsWith('carousel') ? [...content.querySelectorAll('[role="tab"] > div')]
    : [...content.querySelectorAll('.co-chip-body')];
  const rr = root.getBoundingClientRect(), active = document.activeElement;
  return JSON.stringify({id,
    activeInside:content.contains(active),activeRole:active?.getAttribute('role'),
    focusVisible:active?.matches(':focus-visible'),
    palette:Object.fromEntries(['surface-container-highest','primary','surface',
      'on-surface','on-surface-variant','on-primary-container','focus-ring']
      .map(n=>[n,getComputedStyle(content).getPropertyValue('--coui-'+n).trim()])),
    faces:faces.map(e=>{
      const s=getComputedStyle(e),r=e.getBoundingClientRect();
      const owner=e.closest('[role="switch"],[role="radio"],[role="button"],[role="tab"]');
      return {background:s.backgroundColor,ink:s.color,boxShadow:s.boxShadow,
        outlineColor:s.outlineColor,outlineWidth:s.outlineWidth,
        outlineOffset:s.outlineOffset,outlineStyle:s.outlineStyle,
        pointerEvents:s.pointerEvents,role:owner?.getAttribute('role'),
        checked:owner?.getAttribute('aria-checked'),current:owner?.getAttribute('aria-current'),
        hovered:owner?.matches(':hover'),pressed:owner?.matches(':active'),
        focused:owner?.matches(':focus-visible'),
        groupFocused:e.closest('[role="tablist"]')?.matches(':focus-visible'),
        rect:[r.x-rr.x,r.y-rr.y,r.width,r.height]};})});
}
''';

Map<String, dynamic> _face(Map<String, dynamic> row, int index) =>
    ((row['faces'] as List)[index] as Map).cast<String, dynamic>();

// Parse only Chrome's computed numeric colors (never declarations, var()
// references or a CSS cascade). Preserve fractional channels at low alpha:
// converting through an 8-bit canvas would quantize them prematurely.
List<double> _color(String css) {
  final values = RegExp(
    r'[-+]?(?:\d*\.)?\d+(?:e[-+]?\d+)?',
  ).allMatches(css).map((m) => double.parse(m.group(0)!)).toList();
  if (css.startsWith('color(srgb ')) {
    return [
      for (final v in values.take(3)) v * 255,
      if (values.length == 4) values[3] else 1,
    ];
  }
  expect(values.length, anyOf(3, 4), reason: 'computed color: $css');
  return [...values.take(3), if (values.length == 4) values[3] else 1];
}

List<double> _palette(Map<String, dynamic> row, String role) =>
    _color((row['palette'] as Map)[role] as String);

// Independent source-over arithmetic, not the production wash/CSS helper.
// Core's state layer uses opaque semantic ink with the stated 3/8/12 weights.
List<double> _over(List<double> ink, List<double> base, double weight) {
  final alpha = weight + base[3] * (1 - weight);
  return [
    for (var i = 0; i < 3; i++)
      (ink[i] * weight + base[i] * base[3] * (1 - weight)) / alpha,
    alpha,
  ];
}

void _expectColor(String actual, List<double> expected, String reason) {
  final channels = _color(actual);
  for (var i = 0; i < 4; i++) {
    // Chrome serializes color(srgb) channels to finite decimal precision.
    expect(
      channels[i],
      closeTo(expected[i], i == 3 ? .000001 : .001),
      reason: '$reason channel $i: $actual',
    );
  }
}

void _expectBand(Map<String, dynamic> row, String id) {
  final faces = row['faces'] as List;
  final selected = faces.indexWhere((f) => (f as Map)['current'] == 'true');
  expect(selected, greaterThanOrEqualTo(0));
  final dot = _face(row, selected);
  expect(row['focusVisible'], isTrue);
  expect(row['activeRole'], 'tablist');
  expect(dot['groupFocused'], isTrue);
  expect(dot['outlineStyle'], 'solid');
  expect(dot['outlineWidth'], '2px');
  expect(dot['outlineOffset'], '2px');
  _expectColor(dot['outlineColor'] as String, _palette(row, 'focus-ring'), id);
  final shadow = dot['boxShadow'] as String;
  if (id == 'carousel-slide') {
    final colorEnd = shadow.indexOf(')');
    expect(colorEnd, greaterThan(0));
    _expectColor(
      shadow.substring(0, colorEnd + 1),
      _palette(row, 'surface'),
      id,
    );
    expect(shadow.substring(colorEnd + 1).trim(), '0px 0px 0px 2px');
  } else {
    expect(shadow, 'none', reason: '$id explicitly has a transparent gap');
  }
}

void main() {
  late Directory work;
  late pptr.Browser browser;
  final evidence = Platform.environment['COUI_COMPOSED_PAINT_EVIDENCE'];
  final errors = <String>[];
  final requests = <String>[];
  final records = <Map<String, Object?>>[];

  void record(String name, Object? value) {
    if (evidence == null) return;
    Directory(evidence).createSync(recursive: true);
    File('$evidence/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(value),
    );
  }

  Future<Map<String, dynamic>> read(pptr.Page page, String id) async =>
      (jsonDecode(await page.evaluate<String>(_readCase, args: [id])) as Map)
          .cast<String, dynamic>();
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  setUpAll(() async {
    work = Directory.systemTemp.createTempSync('coui-composed-control-paint-');
    record('work', {'path': work.path});
    final body = await renderComponentBodyHtml(composedControlPaintProbe());
    for (final theme in ['light', 'dark']) {
      final document = buildOfflineTailwindHarnessHtml(
        bodyHtml: body,
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        theme: theme,
        animationFreezeCss: '',
        additionalHeadHtml:
            '<link rel="icon" href="data:,"> '
            '<style>${buildLocalFontFaceCss()}</style>',
      );
      File('${work.path}/$theme-ssr.html').writeAsStringSync(document);
      File('${work.path}/$theme-o2.html').writeAsStringSync(
        document.replaceFirst(
          '</body>',
          '<script defer src="client.js" '
              'onload="document.documentElement.dataset.clientLoaded=\'true\'">'
              '</script></body>',
        ),
      );
    }
    final compilation = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      if (Platform.environment['COUI_COMPOSED_PAINT_PACKAGE_CONFIG']
          case final config?)
        '--packages=$config',
      'tool/parity/test/web/fixtures/composed_control_paint_probe.client.dart',
      '-o',
      '${work.path}/client.js',
    ]);
    record('compilation', {
      'exit': compilation.exitCode,
      'stdout': '${compilation.stdout}',
      'stderr': '${compilation.stderr}',
    });
    expect(compilation.exitCode, 0, reason: '${compilation.stderr}');
    browser = await launchCaptureBrowser(
      width: 1000,
      height: 900,
      executablePath: Platform.environment['COUI_COMPOSED_PAINT_CHROME'],
    );
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

  for (final theme in ['light', 'dark']) {
    test(
      'SSR/O2 $theme public callers preserve their computed paint',
      () async {
        final ssrRest = <String, List<dynamic>>{};
        for (final mode in ['ssr', 'o2']) {
          final page = await browser.newPage();
          addTearDown(page.close);
          page.onError.listen((e) => errors.add('$e'));
          page.onConsole.listen((e) {
            if (e.type == pptr.ConsoleMessageType.error) {
              errors.add(e.text ?? 'console error');
            }
          });
          page.onRequest.listen((r) {
            if (!r.url.startsWith('file:') && !r.url.startsWith('data:')) {
              requests.add(r.url);
            }
          });
          await page.goto(
            Uri.file('${work.path}/$theme-$mode.html').toString(),
          );
          if (mode == 'o2') {
            await page.waitForFunction(
              'document.documentElement.dataset.clientLoaded === "true"',
            );
          }
          expect(
            await page.evaluate<String>(
              '() => document.documentElement.getAttribute("data-theme")',
            ),
            theme,
          );
          await page.evaluate<void>('() => document.fonts.ready');
          await settle();
          for (final id in _cases) {
            await page.mouse.move(const pptr.Point(950, 10));
            await page.evaluate<void>(
              '''
id => {document.activeElement?.blur();
            document.querySelector('[data-case="'+id+'"]').scrollIntoView({block:'center'});}''',
              args: [id],
            );
            await settle();
            final rest = await read(page, id);
            final faces = rest['faces'] as List;
            final shape = [
              for (final f in faces)
                {
                  'role': (f as Map)['role'],
                  'rect': f['rect'],
                  'checked': f['checked'],
                  'current': f['current'],
                },
            ];
            if (mode == 'ssr') {
              ssrRest['$theme/$id'] = shape;
            } else {
              expect(
                shape,
                ssrRest['$theme/$id'],
                reason: 'SSR/O2 rest role/geometry: $id',
              );
            }
            if (id.startsWith('switch')) {
              expect(faces, hasLength(1));
              final track = _face(rest, 0);
              expect(track['role'], 'switch');
              expect((track['rect'] as List).sublist(2), [40, 24]);
              expect(track['pointerEvents'], 'none');
              _expectColor(
                track['background'] as String,
                _palette(
                  rest,
                  id == 'switch-off' ? 'surface-container-highest' : 'primary',
                ),
                id,
              );
            } else if (id == 'multiple-flat') {
              expect(faces, hasLength(2));
              expect(
                [for (final f in faces) (f as Map)['role']],
                ['radio', 'radio'],
              );
              expect(
                [for (final f in faces) (f as Map)['checked']],
                ['true', 'false'],
              );
              _expectColor(_face(rest, 0)['background'] as String, [
                170,
                0,
                0,
                1,
              ], id);
              _expectColor(_face(rest, 1)['background'] as String, [
                0,
                170,
                0,
                1,
              ], id);
            } else if (id == 'chip-ramp') {
              expect(faces, hasLength(1));
              expect(_face(rest, 0)['role'], 'button');
              _expectColor(_face(rest, 0)['background'] as String, [
                0,
                0,
                0,
                0,
              ], id);
            } else {
              expect(faces, hasLength(3));
              expect(
                [for (final f in faces) (f as Map)['current']],
                ['true', null, null],
              );
              _expectColor(
                _face(rest, 0)['background'] as String,
                _palette(rest, 'primary'),
                id,
              );
            }
            final targets = id == 'multiple-flat' ? [0, 1] : [0];
            for (final index in targets) {
              final base = id == 'multiple-flat'
                  ? <double>[
                      if (index == 0) 170 else 0,
                      if (index == 1) 170 else 0,
                      0,
                      1,
                    ]
                  : <double>[0, 0, 0, 0];
              final inkRole = id == 'chip-ramp'
                  ? 'on-surface'
                  : index == 0
                  ? 'on-primary-container'
                  : 'on-surface-variant';
              if (id == 'multiple-flat' || id == 'chip-ramp') {
                _expectColor(
                  _face(rest, index)['ink'] as String,
                  _palette(rest, inkRole),
                  '$id ink',
                );
              }
              final point = await page.evaluate<List<dynamic>>(
                '''
(id,index) => {
              const content=document.querySelector('[data-component-case="'+id+'"]');
              const all=id.startsWith('switch')?[content.querySelector('.co-toggle-track')]
                :id.startsWith('carousel')?[...content.querySelectorAll('[role="tab"] > div')]
                :[...content.querySelectorAll('.co-chip-body')];
              const r=all[index].getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2];
            }''',
                args: [id, index],
              );
              await page.mouse.move(
                pptr.Point(point[0] as num, point[1] as num),
              );
              await settle();
              final hover = await read(page, id);
              if (id == 'multiple-flat' || id == 'chip-ramp') {
                expect(_face(hover, index)['hovered'], isTrue);
                _expectColor(
                  _face(hover, index)['background'] as String,
                  _over(_palette(rest, inkRole), base, .03),
                  '$id hover',
                );
              }
              if (!id.startsWith('carousel')) {
                await page.mouse.down();
                await settle();
                final pressed = await read(page, id);
                if (id == 'multiple-flat' || id == 'chip-ramp') {
                  expect(_face(pressed, index)['pressed'], isTrue);
                  _expectColor(
                    _face(pressed, index)['background'] as String,
                    _over(_palette(rest, inkRole), base, .12),
                    '$id pressed',
                  );
                } else {
                  _expectColor(
                    _face(pressed, 0)['background'] as String,
                    _color(_face(rest, 0)['background'] as String),
                    '$id passive track',
                  );
                }
                await page.mouse.up();
                records.add({
                  'mode': mode,
                  'theme': theme,
                  'case': id,
                  'face': index,
                  'state': 'pressed',
                  'actual': pressed,
                });
              }
              await page.mouse.move(const pptr.Point(950, 10));
              await page.evaluate<void>(
                '''
id => {document.activeElement?.blur();
              document.querySelector('[data-keyboard-start="'+id+'"]').focus();}''',
                args: [id],
              );
              for (var tab = 0; tab <= index; tab++) {
                await page.keyboard.press(pptr.Key.tab);
              }
              await settle();
              final focus = await read(page, id);
              expect(focus['activeInside'], isTrue);
              expect(focus['focusVisible'], isTrue);
              if (id.startsWith('carousel')) {
                _expectBand(focus, id);
                if (mode == 'o2') {
                  // DotIndicator's documented keyboard model is axis arrows
                  // with clamped endpoints; Home/End are not its contract.
                  for (final (key, selected) in [
                    (pptr.Key.arrowRight, 1),
                    (pptr.Key.arrowLeft, 0),
                    (pptr.Key.arrowRight, 1),
                    (pptr.Key.arrowRight, 2),
                    (pptr.Key.arrowRight, 2),
                  ]) {
                    await page.keyboard.press(key);
                    await settle();
                    final changed = await read(page, id);
                    expect(
                      (changed['faces'] as List).indexWhere(
                        (f) => (f as Map)['current'] == 'true',
                      ),
                      selected,
                    );
                    _expectBand(changed, id);
                    records.add({
                      'mode': mode,
                      'theme': theme,
                      'case': id,
                      'state': 'keyboard',
                      'key': '$key',
                      'expectedIndex': selected,
                      'actual': changed,
                    });
                  }
                }
              } else if (id == 'multiple-flat' || id == 'chip-ramp') {
                expect(_face(focus, index)['focused'], isTrue);
                _expectColor(
                  _face(focus, index)['background'] as String,
                  _over(_palette(rest, inkRole), base, .08),
                  '$id focus',
                );
              } else {
                _expectColor(
                  _face(focus, 0)['background'] as String,
                  _color(_face(rest, 0)['background'] as String),
                  '$id passive focus',
                );
              }
              records.add({
                'mode': mode,
                'theme': theme,
                'case': id,
                'face': index,
                'rest': rest,
                'hover': hover,
                'focus': focus,
              });
              record('observations', records);
            }
          }
          expect(errors, isEmpty);
          expect(requests, isEmpty);
        }
      },
    );
  }
}
