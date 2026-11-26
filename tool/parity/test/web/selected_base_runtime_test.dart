@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/selected_base_runtime_probe.dart';

const _kNodes = """
name=>{const root=document.querySelector('[data-runtime-paint="'+name+'"]')??document.getElementById(name);
const face=root.matches('.co-chip-body,.co-toggle-track')?root:root.querySelector('.co-toggle-track,.co-chip-body');
return {face,host:face.closest('[role=switch],[role=button]')??face};}
""";
const _kRead = """
name=>{const {face,host}=window.nodes(name),s=getComputedStyle(face);
return JSON.stringify({color:s.backgroundColor,image:s.backgroundImage,
owned:face.classList.contains('co-toggle-owned-fill'),base:face.style.backgroundColor,
hover:face.matches(':hover'),active:host.matches(':active'),inline:face.getAttribute('style')});}
""";

void main() {
  late Directory work;
  late HttpServer server;
  late pptr.Browser browser;
  late String origin;
  final errors = <String>[];
  final external = <String>[];
  final evidence = Platform.environment['COUI_SELECTED_RUNTIME_EVIDENCE'];
  void record(String name, Object? value) {
    if (evidence == null) return;
    Directory(evidence).createSync(recursive: true);
    File(
      '$evidence/$name.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
  }

  Future<void> settle(pptr.Page page) =>
      page.evaluate<void>('()=>new Promise(r=>setTimeout(r,160))');
  Future<Map<String, dynamic>> read(pptr.Page page, String name) async =>
      (jsonDecode(await page.evaluate<String>(_kRead, args: [name])) as Map)
          .cast<String, dynamic>();
  Future<void> point(pptr.Page page, String name) async {
    await page.evaluate<void>(
      "name=>window.nodes(name).host.scrollIntoView({block:'center'})",
      args: [name],
    );
    final xy =
        jsonDecode(
              await page.evaluate<String>(
                'name=>{const r=window.nodes(name).host.getBoundingClientRect();return JSON.stringify([r.x+r.width/2,r.y+r.height/2]);}',
                args: [name],
              ),
            )
            as List;
    await page.mouse.move(pptr.Point(xy[0] as num, xy[1] as num));
    await settle(page);
  }

  Future<void> away(pptr.Page page) async {
    await page.mouse.move(const pptr.Point(950, 10));
    await settle(page);
  }

  Future<pptr.Page> page(String theme) async {
    final p = await browser.newPage();
    p.onError.listen((e) => errors.add('$e'));
    p.onConsole.listen((e) {
      if (e.type == pptr.ConsoleMessageType.error) {
        errors.add(e.text ?? 'error');
      }
    });
    p.onRequest.listen((r) {
      if (!r.url.startsWith(origin) && !r.url.startsWith('data:')) {
        external.add(r.url);
      }
    });
    await p.goto('$origin/$theme.html', wait: pptr.Until.load);
    await p.waitForFunction(
      "document.documentElement.dataset.selectedRuntimeReady==='true'",
    );
    await p.evaluate<Object?>('()=>document.fonts.ready');
    await p.evaluate<void>('()=>{window.nodes=$_kNodes}');
    addTearDown(p.close);
    return p;
  }

  Future<void> setFlag(
    pptr.Page p,
    String field,
    bool value,
    String button,
  ) async {
    final current = await p.evaluate<String>(
      "field=>document.getElementById('runtime-status')"
      ".getAttribute('data-'+field)",
      args: [field],
    );
    if (current == '$value') return;
    await (await p.$('#$button')).click();
    await p.waitForFunction(
      "args=>document.getElementById('runtime-status')"
      ".getAttribute('data-'+args[0])===args[1]",
      args: [
        [field, '$value'],
      ],
    );
  }

  setUpAll(() async {
    work =
        evidence == null
              ? Directory.systemTemp.createTempSync('coui-selected-runtime-')
              : Directory('$evidence/harness')
          ..createSync(recursive: true);
    final body = await renderComponentBodyHtml(selectedBaseRuntimeProbe());
    final config =
        Platform.environment['COUI_SELECTED_RUNTIME_PACKAGE_CONFIG'] ??
        '.dart_tool/package_config.json';
    final compilation = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '--packages=$config',
      'packages/coui_web/test/browser/fixtures/selected_base_runtime_probe.client.dart',
      '-o',
      '${work.path}/client.js',
    ]);
    record('compile', {
      'exit': compilation.exitCode,
      'stdout': '${compilation.stdout}',
      'stderr': '${compilation.stderr}',
    });
    expect(compilation.exitCode, 0, reason: '${compilation.stderr}');
    for (final theme in ['light', 'dark']) {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: body,
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        theme: theme,
        animationFreezeCss: '',
        additionalHeadHtml:
            '<link rel="icon" href="data:,"><style>${buildLocalFontFaceCss()}</style>${buildLocalIconifyHeadHtml()}',
      );
      File('${work.path}/$theme.html').writeAsStringSync(
        html.replaceFirst(
          '</body>',
          '<script defer src="/client.js"></script></body>',
        ),
      );
    }
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = 'http://127.0.0.1:${server.port}';
    server.listen((r) async {
      try {
        if (r.uri.path == '/client.js') {
          r.response.headers.contentType = ContentType(
            'application',
            'javascript',
          );
          r.response.add(File('${work.path}/client.js').readAsBytesSync());
        } else {
          r.response.headers.contentType = ContentType.html;
          r.response.write(
            File('${work.path}${r.uri.path}').readAsStringSync(),
          );
        }
      } on Object catch (e) {
        r.response.statusCode = 404;
        r.response.write('$e');
      }
      await r.response.close();
    });
    browser = await launchCaptureBrowser(width: 1000, height: 900);
    record('browser', {
      'pid': browser.process?.pid,
      'version': await browser.version,
    });
    addTearDown(() async {
      await browser.close();
      await server.close(force: true);
      record('cleanup', {
        'browserClosed': true,
        'serverClosed': true,
        'errors': errors,
        'externalRequests': external,
      });
    });
  });
  test(
    'O2 live implicit explicit inherited and on-off modes '
    'retain the same paints',
    () async {
      final rows = <Object?>[];
      for (final theme in ['light', 'dark']) {
        final p = await page(theme);
        for (final value in [true, false]) {
          for (final owned in [false, true]) {
            for (final inherited in [false, true]) {
              await setFlag(p, 'value', value, 'runtime-value');
              await setFlag(p, 'owned', owned, 'runtime-mode');
              await setFlag(p, 'theme-owned', inherited, 'runtime-theme');
              final colors = <String, List<String>>{};
              for (final name in ['default-peer', 'dynamic', 'inherited']) {
                await away(p);
                final rest = await read(p, name);
                await point(p, name);
                final hover = await read(p, name);
                await p.mouse.down();
                await settle(p);
                final pressed = await read(p, name);
                await p.mouse.up();
                colors[name] = [
                  rest['color'] as String,
                  hover['color'] as String,
                  pressed['color'] as String,
                ];
                if (name == 'dynamic') {
                  expect(rest['owned'], owned);
                  expect((rest['base'] as String).isNotEmpty, owned);
                }
                if (name == 'inherited') {
                  expect(rest['owned'], inherited);
                }
              }
              expect(colors['dynamic'], colors['default-peer']);
              expect(colors['inherited'], colors['default-peer']);
              rows.add({
                'theme': theme,
                'value': value,
                'owned': owned,
                'inherited': inherited,
                'paints': colors,
              });
            }
          }
        }
        // Live palette switch uses the public document theme attribute.
        final switched = theme == 'light' ? 'dark' : 'light';
        await p.evaluate<void>(
          "()=>document.documentElement.dataset.theme='$switched'",
        );
        await away(p);
        final peer = await read(p, 'default-peer');
        final dynamic = await read(p, 'dynamic');
        expect(dynamic['color'], peer['color']);
      }
      record('live-modes', rows);
    },
  );
  test(
    'O2 reused configurations and rebuild remount do not share state paint',
    () async {
      final rows = <Object?>[];
      for (final theme in ['light', 'dark']) {
        final p = await page(theme);
        await away(p);
        final a = await read(p, 'reused-a');
        final b = await read(p, 'reused-b');
        await point(p, 'reused-a');
        final hovered = await read(p, 'reused-a');
        final sibling = await read(p, 'reused-b');
        expect(hovered['color'], isNot(a['color']));
        expect(sibling['color'], b['color']);
        await setFlag(p, 'owned', true, 'runtime-mode');
        Future<List<String>> dynamicPaints() async {
          await away(p);
          final rest = await read(p, 'dynamic');
          expect(rest['owned'], isTrue);
          await point(p, 'dynamic');
          final hover = await read(p, 'dynamic');
          await p.mouse.down();
          await settle(p);
          final pressed = await read(p, 'dynamic');
          await p.mouse.up();
          expect(hover['color'], isNot(rest['color']));
          expect(pressed['color'], isNot(hover['color']));
          return [
            rest['color'] as String,
            hover['color'] as String,
            pressed['color'] as String,
          ];
        }

        final preRemountPaint = await dynamicPaints();
        await p.evaluate<void>(
          "()=>window.savedFace=window.nodes('dynamic').face",
        );
        await (await p.$('#runtime-rebuild')).click();
        await p.waitForFunction(
          "document.getElementById('runtime-status').dataset.revision==='1'",
        );
        expect(
          await p.evaluate<bool>(
            "()=>window.nodes('dynamic').face===window.savedFace",
          ),
          isTrue,
        );
        await (await p.$('#runtime-remount')).click();
        await p.waitForFunction(
          "document.getElementById('runtime-status').dataset.mount==='1'",
        );
        expect(
          await p.evaluate<bool>(
            "()=>window.nodes('dynamic').face!==window.savedFace"
            '&&!window.savedFace.isConnected',
          ),
          isTrue,
        );
        final postRemountPaint = await dynamicPaints();
        expect(postRemountPaint, preRemountPaint);
        rows.add({
          'theme': theme,
          'a': a,
          'preRemountPaint': preRemountPaint,
          'postRemountPaint': postRemountPaint,
          'b': b,
          'hovered': hovered,
          'sibling': sibling,
        });
      }
      record('config-lifetime', rows);
    },
  );
  test(
    'O2 valid nested chip bodies keep their own state fallback and base',
    () async {
      final rows = <Object?>[];
      for (final theme in ['light', 'dark']) {
        final p = await page(theme);
        for (final suffix in ['raw', 'clear']) {
          final outer = 'outer-active-$suffix';
          final inner = 'inner-passive-$suffix';
          await away(p);
          final rest = await read(p, inner);
          await point(p, outer);
          final hovered = await read(p, inner);
          await p.mouse.down();
          await settle(p);
          final pressed = await read(p, inner);
          await p.mouse.up();
          expect(hovered['color'], rest['color']);
          expect(pressed['color'], rest['color']);
          rows.add({
            'theme': theme,
            'inner': inner,
            'rest': rest,
            'hover': hovered,
            'pressed': pressed,
          });
        }
        await away(p);
        final outer = await read(p, 'outer-passive');
        final inner = await read(p, 'inner-active');
        await point(p, 'inner-active');
        final outerHover = await read(p, 'outer-passive');
        final innerHover = await read(p, 'inner-active');
        expect(outerHover['color'], outer['color']);
        expect(innerHover['color'], isNot(inner['color']));
        rows.add({
          'theme': theme,
          'passiveOuter': outer,
          'passiveOuterHover': outerHover,
          'activeInner': inner,
          'activeInnerHover': innerHover,
        });
      }
      record('nested-chips', rows);
      expect(errors, isEmpty);
      expect(external, isEmpty);
    },
  );
}
