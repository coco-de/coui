@Timeout(Duration(minutes: 3))
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
import '../fixtures/selected_base_paint_probe.dart';

const _kLocate = """
id => {
 const root=document.querySelector('[data-paint-case="'+id+'"]');
 const face=root.querySelector('.co-toggle-track,.co-chip-body');
 const host=face.closest('[role=switch],[role=button]')??face;
 return {root,face,host};
}""";
const _kRead = """
id => {const {face}=window.locate(id),s=getComputedStyle(face);
 return JSON.stringify({color:s.backgroundColor,image:s.backgroundImage,
 boxSizing:s.boxSizing,borderStyle:s.borderStyle,hovered:face.matches(':hover')});}""";

void main() {
  late Directory work;
  late HttpServer server;
  late pptr.Browser browser;
  late String origin;
  final errors = <String>[];
  final requests = <String>[];
  final evidence = Platform.environment['COUI_SELECTED_BASE_EVIDENCE'];
  void record(String name, Object? value) {
    if (evidence != null) {
      Directory(evidence).createSync(recursive: true);
      File(
        '$evidence/$name.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
    }
  }

  Future<Map<String, dynamic>> read(pptr.Page page, String id) async =>
      (jsonDecode(await page.evaluate<String>(_kRead, args: [id])) as Map)
          .cast<String, dynamic>();
  Future<void> settle(pptr.Page page) =>
      page.evaluate<void>('()=>new Promise(r=>setTimeout(r,160))');
  Future<pptr.Page> page(String theme, {bool glass = false}) async {
    final result = await browser.newPage();
    result.onError.listen((e) => errors.add('$e'));
    result.onConsole.listen((e) {
      if (e.type == pptr.ConsoleMessageType.error) {
        errors.add(e.text ?? 'error');
      }
    });
    result.onRequest.listen((r) {
      if (!r.url.startsWith(origin) && !r.url.startsWith('data:')) {
        requests.add(r.url);
      }
    });
    await result.goto(
      '$origin/$theme${glass ? '-glass' : ''}.html',
      wait: pptr.Until.load,
    );
    await result.waitForFunction(
      """
()=>[...document.styleSheets].some(s=>{try{return [...s.cssRules].some(r=>r.cssText.includes('.inline-flex'))}catch(e){return false}})""",
    );
    await result.evaluate<Object?>('()=>document.fonts.ready');
    await result.evaluate<void>('()=>{window.locate=$_kLocate}');
    addTearDown(result.close);
    return result;
  }

  setUpAll(() async {
    work =
        evidence == null
              ? Directory.systemTemp.createTempSync('coui-selected-base-')
              : Directory('$evidence/harness')
          ..createSync(recursive: true);
    final body = await renderComponentBodyHtml(selectedBasePaintProbe());
    for (final theme in ['light', 'dark']) {
      for (final glass in [false, true]) {
        File(
          '${work.path}/$theme${glass ? '-glass' : ''}.html',
        ).writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml: body,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            theme: theme,
            surfaceStyleId: glass ? 'liquidGlass' : null,
            animationFreezeCss: '',
            additionalHeadHtml:
                '<link rel="icon" href="data:,"><style>${buildLocalFontFaceCss()}</style>${buildLocalIconifyHeadHtml()}',
          ),
        );
      }
    }
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = 'http://127.0.0.1:${server.port}';
    server.listen((r) async {
      try {
        r.response.headers.contentType = ContentType.html;
        r.response.write(File('${work.path}${r.uri.path}').readAsStringSync());
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
      final pid = browser.process?.pid;
      await browser.close();
      await server.close(force: true);
      record('cleanup', {
        'pid': pid,
        'browserClosed': true,
        'serverClosed': true,
        'errors': errors,
        'externalRequests': requests,
      });
    });
  });
  test('13 original faces per theme retain their base '
      'and paint all52 pointer washes', () async {
    final observations = <Map<String, Object?>>[];
    final missing = <Map<String, Object?>>[];
    for (final theme in ['light', 'dark']) {
      final p = await page(theme);
      final ids =
          (jsonDecode(
                    await p.evaluate<String>(
                      """
()=>JSON.stringify([...document.querySelectorAll('[data-paint-case]')].map(e=>e.dataset.paintCase).filter(id=>id.startsWith('toggle-')||id.startsWith('chip-')))""",
                    ),
                  )
                  as List)
              .cast<String>();
      expect(ids, hasLength(13));
      for (final id in ids) {
        await p.evaluate<void>(
          'id=>window.locate(id).host.scrollIntoView({block:"center"})',
          args: [id],
        );
        await p.mouse.move(const pptr.Point(950, 10));
        await settle(p);
        final rest = await read(p, id);
        final xy =
            jsonDecode(
                  await p.evaluate<String>(
                    'id=>{const r=window.locate(id).host.getBoundingClientRect();return JSON.stringify([r.x+r.width/2,r.y+r.height/2]);}',
                    args: [id],
                  ),
                )
                as List;
        await p.mouse.move(pptr.Point(xy[0] as num, xy[1] as num));
        await settle(p);
        final hover = await read(p, id);
        await p.mouse.down();
        await settle(p);
        final pressed = await read(p, id);
        await p.mouse.up();
        for (final entry in {'hover': hover, 'pressed': pressed}.entries) {
          final observation = {
            'theme': theme,
            'id': id,
            'state': entry.key,
            'rest': rest,
            'actual': entry.value,
          };
          observations.add(observation);
          if (entry.value['color'] == rest['color']) missing.add(observation);
          expect(
            entry.value['image'],
            rest['image'],
            reason:
                'State wash paints the owned colour, '
                'without replacing caller images',
          );
        }
      }
    }
    record('original52', {'events': observations, 'missing': missing});
    expect(observations, hasLength(52));
    expect(
      missing,
      isEmpty,
      reason:
          'The real state colour must compose over each '
          'raw/token/transparent rest base: ${jsonEncode(missing)}',
    );
  });
  test('passive disabled and caller CSS colour gradient important '
      'keep paint precedence', () async {
    final rows = <Object?>[];
    for (final theme in ['light', 'dark']) {
      final p = await page(theme);
      for (final id in [
        'passive-first',
        'disabled-first',
        'caller-color',
        'caller-gradient',
        'caller-important',
      ]) {
        await p.evaluate<void>(
          'id=>window.locate(id).host.scrollIntoView({block:"center"})',
          args: [id],
        );
        await p.mouse.move(const pptr.Point(950, 10));
        await settle(p);
        final rest = await read(p, id);
        final xy =
            jsonDecode(
                  await p.evaluate<String>(
                    'id=>{const r=window.locate(id).host.getBoundingClientRect();return JSON.stringify([r.x+r.width/2,r.y+r.height/2]);}',
                    args: [id],
                  ),
                )
                as List;
        await p.mouse.move(pptr.Point(xy[0] as num, xy[1] as num));
        await settle(p);
        final hover = await read(p, id);
        await p.mouse.down();
        await settle(p);
        final pressed = await read(p, id);
        await p.mouse.up();
        expect(rest['boxSizing'], 'border-box');
        expect(rest['borderStyle'], 'solid');
        if (id == 'passive-first') {
          expect(rest['color'], 'rgb(51, 68, 85)');
        }
        if (id == 'disabled-first') {
          expect(rest['color'], 'rgba(51, 68, 85, 0.5)');
        }
        if (id != 'caller-gradient') {
          expect(hover['color'], rest['color']);
          expect(pressed['color'], rest['color']);
        }
        if (id.startsWith('caller-') && id != 'caller-gradient') {
          expect(rest['color'], 'rgb(238, 170, 34)');
        }
        expect(hover['image'], rest['image']);
        expect(pressed['image'], rest['image']);
        rows.add({
          'theme': theme,
          'id': id,
          'rest': rest,
          'hover': hover,
          'pressed': pressed,
        });
      }
    }
    record('boundaries', rows);
    expect(errors, isEmpty);
    expect(requests, isEmpty);
  });
  test(
    'implicit and explicit same-token tracks keep rest and states '
    'in both orders',
    () async {
      final rows = <Object?>[];
      final mismatches = <Object?>[];
      for (final theme in ['light', 'dark']) {
        final p = await page(theme);
        for (final reversed in [false, true]) {
          final pair = <String, List<Map<String, dynamic>>>{};
          for (final explicit in [false, true]) {
            final id = 'mode-$reversed-$explicit';
            await p.evaluate<void>(
              'id=>window.locate(id).host.scrollIntoView({block:"center"})',
              args: [id],
            );
            await p.mouse.move(const pptr.Point(950, 10));
            await settle(p);
            final rest = await read(p, id);
            final xy =
                jsonDecode(
                      await p.evaluate<String>(
                        'id=>{const r=window.locate(id).host.getBoundingClientRect();return JSON.stringify([r.x+r.width/2,r.y+r.height/2]);}',
                        args: [id],
                      ),
                    )
                    as List;
            await p.mouse.move(pptr.Point(xy[0] as num, xy[1] as num));
            await settle(p);
            final hover = await read(p, id);
            await p.mouse.down();
            await settle(p);
            final pressed = await read(p, id);
            await p.mouse.up();
            pair['$explicit'] = [rest, hover, pressed];
          }
          final equal = List.generate(
            3,
            (index) =>
                pair['false']![index]['color'] == pair['true']![index]['color'],
          );
          final row = {
            'theme': theme,
            'reversed': reversed,
            'pair': pair,
            'equal': equal,
          };
          rows.add(row);
          if (equal.any((value) => !value)) mismatches.add(row);
        }
      }
      record('same-token-modes', {'rows': rows, 'mismatches': mismatches});
      expect(
        mismatches,
        isEmpty,
        reason:
            'A rule reading override-only values must not select '
            'an implicit face',
      );
    },
  );
  test(
    'nested owned tracks keep rest when only outer '
    'prefix or suffix host is hovered',
    () async {
      final rows = <Object?>[];
      final mismatches = <Object?>[];
      for (final theme in ['light', 'dark']) {
        final p = await page(theme);
        for (final slot in ['prefix', 'suffix']) {
          await p.evaluate<void>(
            "slot=>document.getElementById('owner-outer-'+slot)"
            ".scrollIntoView({block:'center'})",
            args: [slot],
          );
          await p.mouse.move(const pptr.Point(950, 10));
          await settle(p);
          Future<Map<String, dynamic>> inner() async =>
              (jsonDecode(
                        await p.evaluate<String>(
                          """
slot=>{const inner=document.getElementById('owner-inner-'+slot);
const face=inner.querySelector(':scope > span > .co-toggle-track');
return JSON.stringify({color:getComputedStyle(face).backgroundColor,
hovered:inner.matches(':hover'),active:inner.matches(':active')});}
""",
                          args: [slot],
                        ),
                      )
                      as Map)
                  .cast<String, dynamic>();
          final rest = await inner();
          final xy =
              jsonDecode(
                    await p.evaluate<String>(
                      """
slot=>{const outer=document.getElementById('owner-outer-'+slot);
const face=outer.querySelector(':scope > span > .co-toggle-track');
const r=face.getBoundingClientRect();return JSON.stringify([r.x+r.width/2,r.y+r.height/2]);}
""",
                      args: [slot],
                    ),
                  )
                  as List;
          await p.mouse.move(pptr.Point(xy[0] as num, xy[1] as num));
          await settle(p);
          final hover = await inner();
          await p.mouse.down();
          await settle(p);
          final pressed = await inner();
          await p.mouse.up();
          await p.mouse.move(const pptr.Point(950, 10));
          await p.keyboard.press(pptr.Key.tab);
          await p.evaluate<void>(
            "slot=>document.getElementById('owner-outer-'+slot).focus()",
            args: [slot],
          );
          final focus =
              jsonDecode(
                    await p.evaluate<String>(
                      """
slot=>{const outer=document.getElementById('owner-outer-'+slot),
inner=document.getElementById('owner-inner-'+slot),
o=outer.querySelector(':scope > span > .co-toggle-track'),
i=inner.querySelector(':scope > span > .co-toggle-track');
return JSON.stringify({outerVisible:outer.matches(':focus-visible'),
innerVisible:inner.matches(':focus-visible'),outer:getComputedStyle(o).outlineColor,
inner:getComputedStyle(i).outlineColor});}
""",
                      args: [slot],
                    ),
                  )
                  as Map;
          expect(focus['outerVisible'], isTrue);
          expect(focus['innerVisible'], isFalse);
          expect(focus['outer'], isNot(focus['inner']));
          expect(focus['inner'], 'rgba(0, 0, 0, 0)');

          final row = {
            'theme': theme,
            'slot': slot,
            'focus': focus,
            'rest': rest,
            'hover': hover,
            'pressed': pressed,
          };
          rows.add(row);
          expect(hover['hovered'], isFalse);
          expect(pressed['hovered'], isFalse);
          if (hover['color'] != rest['color'] ||
              pressed['color'] != rest['color']) {
            mismatches.add(row);
          }
        }
      }
      record('nested-owner', {'rows': rows, 'mismatches': mismatches});
      expect(
        mismatches,
        isEmpty,
        reason:
            'Only the track owned by the hovered host may take its state wash',
      );
    },
  );
  test(
    'material presets preserve explicit Toggle base priority and states',
    () async {
      final rows = <Object?>[];
      for (final theme in ['light', 'dark']) {
        final ordinary = await page(theme);
        final glass = await page(theme, glass: true);
        for (final kind in ['raw', 'token', 'alpha']) {
          for (final value in [true, false]) {
            final id = 'toggle-$kind-$value';
            final paints = <List<String>>[];
            for (final current in [ordinary, glass]) {
              await current.bringToFront();
              await current.evaluate<void>(
                "id=>window.locate(id).host.scrollIntoView({block:'center'})",
                args: [id],
              );
              await current.mouse.move(const pptr.Point(950, 10));
              await settle(current);
              final rest = await read(current, id);
              final xy =
                  jsonDecode(
                        await current.evaluate<String>(
                          'id=>{const r=window.locate(id).face.getBoundingClientRect();return JSON.stringify([r.x+r.width/2,r.y+r.height/2]);}',
                          args: [id],
                        ),
                      )
                      as List;
              await current.mouse.move(pptr.Point(xy[0] as num, xy[1] as num));
              await settle(current);
              final hover = await read(current, id);
              expect(hover['hovered'], isTrue);
              expect(hover['color'], isNot(rest['color']));
              await current.mouse.down();
              await settle(current);
              final pressed = await read(current, id);
              await current.mouse.up();
              paints.add([
                rest['color'] as String,
                hover['color'] as String,
                pressed['color'] as String,
              ]);
            }
            rows.add({'theme': theme, 'id': id, 'paints': paints});
            expect(
              paints[1],
              paints[0],
              reason: 'Explicit inline paint retains authority under material',
            );
          }
        }
      }
      record('material-priority', rows);
    },
  );
  test(
    'explicit enabled null callback Toggle keeps its live state layer',
    () async {
      final rows = <Object?>[];
      for (final theme in ['light', 'dark']) {
        final p = await page(theme);
        for (final kind in ['raw', 'token']) {
          final colors = <List<String>>[];
          for (final id in ['toggle-$kind-true', 'null-callback-$kind']) {
            await p.evaluate<void>(
              'id=>window.locate(id).host.scrollIntoView({block:"center"})',
              args: [id],
            );
            await p.mouse.move(const pptr.Point(950, 10));
            await settle(p);
            final rest = await read(p, id);
            final xy =
                jsonDecode(
                      await p.evaluate<String>(
                        'id=>{const r=window.locate(id).face.getBoundingClientRect();return JSON.stringify([r.x+r.width/2,r.y+r.height/2]);}',
                        args: [id],
                      ),
                    )
                    as List;
            await p.mouse.move(pptr.Point(xy[0] as num, xy[1] as num));
            await settle(p);
            final hover = await read(p, id);
            await p.mouse.down();
            await settle(p);
            final pressed = await read(p, id);
            await p.mouse.up();
            colors.add([
              rest['color'] as String,
              hover['color'] as String,
              pressed['color'] as String,
            ]);
            expect(hover['hovered'], isTrue);
            expect(hover['color'], isNot(rest['color']));
          }
          expect(colors[1], colors[0]);
          rows.add({'theme': theme, 'kind': kind, 'paints': colors});
        }
      }
      record('enabled-null-callback', rows);
    },
  );
}
