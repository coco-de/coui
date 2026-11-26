@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:image/image.dart' as image;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/swap_natural_size_cases.dart';

const _revisionChanged =
    'n=>Number(document.querySelector("#swap-ready").dataset.builds)>n';

const _read = '''
name=>{
 const owner=document.querySelector('#swap-'+name), host=document.querySelector('#case-'+name);
 window.swapProbeNodeIds??={next:0,ids:new WeakMap()};
 const nodeId=e=>{const s=window.swapProbeNodeIds;if(!s.ids.has(e))s.ids.set(e,++s.next);return s.ids.get(e)};
 const box=e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height}};
 const faces=[...owner.querySelectorAll('[data-face]')].map(e=>{
  const slot=e.parentElement,s=getComputedStyle(slot),c=getComputedStyle(e);
  return {name:e.dataset.face,mount:e.dataset.mount,faceNode:nodeId(e),slotNode:nodeId(slot),face:box(e),slot:box(slot),
   position:s.position,inert:slot.inert,opacity:s.opacity,transform:s.transform,
   backface:s.backfaceVisibility,faceWidth:c.width,faceHeight:c.height,
   maxWidth:c.maxWidth,maxHeight:c.maxHeight};
 });
 const marker=document.querySelector('#stage-'+name+' [data-baseline]');
 const rs=getComputedStyle(owner);
 const overlap=owner.querySelector('[data-face]').parentElement.parentElement;
 return {name,ownerNode:nodeId(owner),overlapNode:nodeId(overlap),root:box(owner),faces,checked:host.dataset.checked,context:host.dataset.context,
  animation:host.dataset.animation,rootTransform:rs.transform,
  maxWidth:rs.maxWidth,maxHeight:rs.maxHeight,
  baselineFromTop:marker?marker.getBoundingClientRect().y-owner.getBoundingClientRect().y:null,
  callbacks:Number(host.dataset.callbacks),values:host.dataset.values,
  focused:document.activeElement===owner,focusVisible:owner.matches(':focus-visible'),
  role:owner.getAttribute('role'),ariaPressed:owner.getAttribute('aria-pressed'),
  display:getComputedStyle(owner).display};
}
''';

void main() {
  late Directory evidence;
  late bool retainEvidence;
  late HttpServer server;
  late pptr.Browser browser;
  late String origin;
  final records = <Map<String, Object?>>[];
  final errors = <String>[];
  final externalRequests = <String>[];
  final names = [
    for (final shape in ['horizontal', 'vertical', 'same-size'])
      for (final variant in CoreSwapAnimation.values) '$shape-${variant.name}',
    for (final shape in ['horizontal', 'vertical'])
      for (final variant in CoreSwapAnimation.values)
        '$shape-${variant.name}-tight',
    for (final variant in CoreSwapAnimation.values)
      'horizontal-${variant.name}-inline',
    for (final shape in ['horizontal', 'vertical'])
      for (final variant in [CoreSwapAnimation.none, CoreSwapAnimation.rotate])
        '$shape-${variant.name}-caller-flex',
    for (final shape in ['horizontal', 'vertical'])
      for (final variant in [CoreSwapAnimation.none, CoreSwapAnimation.rotate])
        '$shape-${variant.name}-interactive-tight',
    for (final shape in ['horizontal', 'vertical']) '$shape-none-mode',
    for (final shape in ['horizontal', 'vertical']) '$shape-none-caller-max',
    for (final shape in ['horizontal', 'vertical'])
      for (final context in ['caller-class', 'caller-important'])
        '$shape-none-$context',
    'vertical-none-child-max',
    'horizontal-flip-caller-transform',
    'horizontal-flip-caller-padding',
    for (final shape in ['horizontal', 'vertical'])
      for (final variant in [CoreSwapAnimation.none, CoreSwapAnimation.rotate])
        for (final context in ['frame-loose', 'frame-tight'])
          '$shape-${variant.name}-$context',
  ];
  setUpAll(() async {
    final explicitEvidence = Platform.environment['SWAP_EVIDENCE'];
    retainEvidence = explicitEvidence != null;
    final parent = explicitEvidence == null
        ? Directory.systemTemp.createTempSync('coui-swap-natural-size-')
        : Directory(explicitEvidence);
    evidence = Directory('${parent.path}/web-harness')
      ..createSync(recursive: true);
    final fixture = File(
      'tool/parity/test/fixtures/swap_natural_size_cases.dart',
    ).absolute.uri;
    final entry = File('${evidence.path}/client.dart')
      ..writeAsStringSync('''
import 'package:coui_web/coui_web.dart';
import '$fixture';
void main()=>runApp(swapNaturalSizeCases(),attachTo:'#swap-app');
''');
    final config = (await Isolate.packageConfig)!;
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '-Djaspr.flags.release=true',
      '--packages=${config.toFilePath()}',
      entry.path,
      '-o',
      '${evidence.path}/client.js',
    ]);
    File('${evidence.path}/compile.json').writeAsStringSync(
      jsonEncode({
        'exitCode': result.exitCode,
        'stdout': '${result.stdout}',
        'stderr': '${result.stderr}',
      }),
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final body = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        div(id: 'swap-app', [swapNaturalSizeCases()]),
      ]),
    );
    File('${evidence.path}/index.html').writeAsStringSync(
      buildOfflineTailwindHarnessHtml(
        bodyHtml: body,
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        animationFreezeCss: '',
        additionalHeadHtml:
            '<link rel="icon" href="data:,"><style>${buildLocalFontFaceCss()}</style>',
      ),
    );
    final direct = await renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        swapDirectResolverCases(),
      ]),
    );
    File('${evidence.path}/direct.html').writeAsStringSync(
      buildOfflineTailwindHarnessHtml(
        bodyHtml: direct,
        themeConfig: ThemeConfig.defaults(),
        vendoredTailwindScript: loadVendoredTailwindScript(),
        animationFreezeCss: '',
        additionalHeadHtml:
            '<link rel="icon" href="data:,"><style>${buildLocalFontFaceCss()}</style>',
      ),
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = 'http://127.0.0.1:${server.port}';
    server.listen((r) async {
      final file = File('${evidence.path}/${r.uri.path.substring(1)}');
      r.response.headers.contentType = r.uri.path.endsWith('.js')
          ? ContentType('application', 'javascript')
          : ContentType.html;
      if (file.existsSync()) {
        r.response.add(file.readAsBytesSync());
      } else {
        r.response.statusCode = 404;
      }
      await r.response.close();
    });
    browser = await launchCaptureBrowser(
      width: 1200,
      height: 1000,
      executablePath: Platform.environment['PUPPETEER_EXECUTABLE_PATH'],
    );
    File('${evidence.path}/browser.json').writeAsStringSync(
      jsonEncode({
        'pid': browser.process?.pid,
        'version': await browser.version,
        'origin': origin,
        'executable': Platform.environment['PUPPETEER_EXECUTABLE_PATH'],
      }),
    );
  });
  tearDownAll(() async {
    final serverPort = server.port;
    await browser.close();
    if (browser.process case final process?) await process.exitCode;
    await server.close(force: true);
    File('${evidence.parent.path}/web-observed.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'records': records,
        'errors': errors,
        'externalRequests': externalRequests,
        'browserClosed': true,
        'httpClosed': true,
      }),
    );
    final pid = browser.process?.pid;
    File('${evidence.parent.path}/cleanup.json').writeAsStringSync(
      jsonEncode({
        'pid': pid,
        'pidClosed':
            pid == null ||
            (await Process.run('kill', ['-0', '$pid'])).exitCode != 0,
        'serverPort': serverPort,
        'httpClosed': true,
        'errors': errors,
        'externalRequests': externalRequests,
      }),
    );
    expect(errors, isEmpty);
    expect(externalRequests, isEmpty);
    if (!retainEvidence) {
      evidence.parent.deleteSync(recursive: true);
    }
  });
  void observePage(pptr.Page p) {
    p.onError.listen((e) => errors.add('$e'));
    p.onConsole.listen((e) {
      if (e.type == pptr.ConsoleMessageType.error) {
        errors.add(e.text ?? 'console error');
      }
    });
    p.onRequest.listen((r) {
      if (!r.url.startsWith(origin) && !r.url.startsWith('data:')) {
        externalRequests.add(r.url);
      }
    });
  }

  Future<pptr.Page> open({required bool client}) async {
    final p = await browser.newPage();
    observePage(p);
    await p.goto('$origin/index.html');
    await p.evaluate<Object?>('()=>document.fonts.ready');
    await p.waitForFunction(
      '''
()=>[...document.styleSheets].some(s=>{
try{return [...s.cssRules].some(r=>r.cssText.includes('.inline-flex'))}
catch(e){return false}})''',
    );
    if (!client) {
      final rules = await p.evaluate<Object?>(
        '''
()=>[...document.styleSheets]
.flatMap(s=>{try{return [...s.cssRules]}catch(e){return []}})
.filter(r=>r.selectorText?.startsWith(':where(')&&
/max-width|max-height|min-width|min-height/.test(r.style?.cssText??''))
.map(r=>({selector:r.selectorText,declarations:r.style.cssText}))''',
      );
      File(
        '${evidence.path}/constraint-cssom.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rules));
    }
    if (client) {
      await p.addScriptTag(url: '$origin/client.js');
      final before = await p.evaluate<num>(
        "Number(document.querySelector('#swap-ready').dataset.builds)",
      );
      await p.click('#false-horizontal-none');
      await p.waitForFunction(
        _revisionChanged,
        args: [before],
      );
    }
    return p;
  }

  Future<Map<String, dynamic>> read(pptr.Page p, String name) =>
      p.evaluate(_read, args: [name]);
  Future<void> settle(pptr.Page p) async {
    await p.evaluate<void>(
      '()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))',
    );
    await p.waitForFunction(
      '''
()=>document.getAnimations()
.every(a=>a.playState!=='running'&&!a.pending)''',
    );
  }

  List<num> expected(String name) => name.startsWith('horizontal')
      ? [80, 24]
      : name.startsWith('vertical')
      ? [24, 80]
      : [24, 24];
  void geometry(Map<String, dynamic> row, List<Object?> failures) {
    if (row['animation'] == 'flip') return;
    final context = row['context'];
    final e =
        context == 'tight' || context == 'child-max' || context == 'frame-tight'
        ? [24, 24]
        : context == 'caller-max' || context == 'caller-class'
        ? [12, 12]
        : context == 'caller-important'
        ? [14, 14]
        : expected(row['name'] as String);
    final r = row['root'] as Map<String, dynamic>;
    if (r['width'] != e[0] || r['height'] != e[1]) {
      failures.add({'name': row['name'], 'expected': e, 'actual': r});
    }
    final vertical = (row['name'] as String).startsWith('vertical');
    final same = (row['name'] as String).startsWith('same-size');
    for (final face in (row['faces'] as List).cast<Map<String, dynamic>>()) {
      final off = face['name'] == 'off';
      final natural = [
        if (vertical || same) 24 else if (off) 16 else 80,
        if (vertical && off) 16 else if (vertical) 80 else 24,
      ];
      final bounded =
          context == 'tight' ||
          context == 'frame-tight' ||
          context == 'caller-max' ||
          context == 'caller-class' ||
          context == 'caller-important' ||
          context == 'child-max' && off;
      final target = [
        for (var i = 0; i < 2; i++)
          if (bounded) natural[i].clamp(0, e[i]) else natural[i],
      ];
      final actual = face['face'] as Map<String, dynamic>;
      if (actual['width'] != target[0] || actual['height'] != target[1]) {
        failures.add({
          'name': row['name'],
          'face': face['name'],
          'expectedFace': target,
          'actualFace': actual,
          'slot': face['slot'],
        });
      }
      num center(Map<String, dynamic> box, String axis, String length) =>
          (box[axis] as num) + (box[length] as num) / 2;
      if (center(actual, 'x', 'width') != center(r, 'x', 'width') ||
          center(actual, 'y', 'height') != center(r, 'y', 'height')) {
        failures.add({
          'name': row['name'],
          'face': face['name'],
          'centerMismatch': actual,
          'owner': r,
        });
      }
    }
  }

  Future<void> flipPaint(
    pptr.Page p,
    String name,
    Map<String, dynamic> row,
  ) async {
    if (row['animation'] != 'flip') return;
    final vertical = name.startsWith('vertical');
    final same = name.startsWith('same-size');
    expect(
      [
        (row['root'] as Map<String, dynamic>)['width'],
        (row['root'] as Map<String, dynamic>)['height'],
      ],
      row['context'] == 'caller-padding'
          ? [32, 40]
          : vertical
          ? [24, 16]
          : same
          ? [24, 24]
          : [16, 24],
    );
    if (row['context'] == 'caller-padding') {
      final on = (row['faces'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere(
            (f) => f['name'] == 'on',
          );
      records.add({
        'phase': 'O2-flip-padding-face',
        'checked': row['checked'],
        'face': on['face'],
        'slot': on['slot'],
      });
      expect(
        (on['face'] as Map<String, dynamic>)['width'],
        32,
        reason: 'retain the existing root padding-box containing block',
      );
    }
    final face = await p.$('#swap-$name');
    final png = image.decodePng(Uint8List.fromList(await face.screenshot()))!;
    final pixel = png.getPixel(png.width ~/ 2, png.height ~/ 2);
    final actual = [
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
      pixel.a.toInt(),
    ];
    final showsOn =
        row['checked'] == 'true' && row['context'] != 'caller-transform';
    final expected = showsOn ? [32, 144, 96, 255] : [48, 80, 160, 255];
    records.add({
      'phase': 'O2-flip-paint',
      'name': name,
      'checked': row['checked'],
      'actual': actual,
      'expected': expected,
      'rootTransform': row['rootTransform'],
    });
    expect(actual, expected, reason: 'flip remains in the existing 3D context');
    if (row['context'] == 'caller-transform') {
      expect(row['rootTransform'], 'matrix(1, 0, 0, 1, 7, 0)');
    }
  }

  test(
    'SSR none/rotate reserve both public faces in the natural owner',
    () async {
      final p = await open(client: false);
      final failures = <Object?>[];
      try {
        for (final name in names) {
          final row = await read(p, name);
          records.add({'phase': 'SSR', 'observed': row});
          expect(row['faces'] as List, hasLength(2));
          geometry(row, failures);
        }
      } finally {
        await p.close();
      }
      expect(
        failures,
        isEmpty,
        reason:
            'A caller onContent must participate in the non-flip '
            'natural-size owner.',
      );
    },
  );
  test(
    'public resolveSwap chrome works without any Swap widget stylesheet',
    () async {
      final p = await browser.newPage();
      observePage(p);
      final failures = <Object?>[];
      try {
        await p.goto('$origin/direct.html');
        await p.evaluate<Object?>('()=>document.fonts.ready');
        await p.waitForFunction(
          '''
()=>[...document.styleSheets].some(s=>{
try{return [...s.cssRules].some(r=>r.cssText.includes('.flex'))}
catch(e){return false}})''',
        );
        for (final name in ['horizontal-direct', 'vertical-direct']) {
          final row = await read(p, name);
          records.add({'phase': 'SSR-direct-resolver', 'observed': row});
          geometry(row, failures);
        }
      } finally {
        await p.close();
      }
      expect(failures, isEmpty);
    },
  );
  test(
    'O2 controlled state keeps mounts/inert and owns the visible natural '
    'face and pointer region',
    () async {
      final p = await open(client: true);
      final failures = <Object?>[];
      try {
        for (final name in names) {
          final initial = await read(p, name);
          for (final checked in [false, true, false]) {
            final before = await p.evaluate<num>(
              "Number(document.querySelector('#swap-ready').dataset.builds)",
            );
            await p.click('#${checked ? 'true' : 'false'}-$name');
            await p.waitForFunction(
              _revisionChanged,
              args: [before],
            );
            await settle(p);
            final row = await read(p, name);
            records.add({
              'phase': 'O2-controlled',
              'requested': checked,
              'observed': row,
            });
            expect(row['checked'], '$checked');
            expect(row['callbacks'], 0);
            expect(row['ownerNode'], initial['ownerNode']);
            expect(row['overlapNode'], initial['overlapNode']);
            final faces = (row['faces'] as List).cast<Map<String, dynamic>>();
            for (var i = 0; i < faces.length; i++) {
              expect(
                faces[i]['mount'],
                ((initial['faces'] as List)[i]
                    as Map<String, dynamic>)['mount'],
              );
              expect(
                faces[i]['faceNode'],
                ((initial['faces'] as List)[i]
                    as Map<String, dynamic>)['faceNode'],
              );
              expect(
                faces[i]['slotNode'],
                ((initial['faces'] as List)[i]
                    as Map<String, dynamic>)['slotNode'],
              );
              expect(
                faces[i]['inert'],
                faces[i]['name'] == 'on' ? !checked : checked,
              );
            }
            geometry(row, failures);
            await flipPaint(p, name, row);
            if (row['context'] == 'caller-max' ||
                row['context'] == 'caller-class' ||
                row['context'] == 'caller-important') {
              final limit = row['context'] == 'caller-important'
                  ? '14px'
                  : '12px';
              expect(row['maxWidth'], limit);
              expect(row['maxHeight'], limit);
            }
            if (row['context'] == 'child-max') {
              final on = (row['faces'] as List)
                  .cast<Map<String, dynamic>>()
                  .singleWhere(
                    (f) => f['name'] == 'on',
                  );
              expect(on['maxWidth'], 'none');
              expect(on['maxHeight'], 'none');
            }
            if (checked && name.endsWith('none') && !name.startsWith('same')) {
              await p
                  .$('#stage-$name')
                  .then((e) => e.screenshot())
                  .then(
                    (bytes) => File(
                      '${evidence.parent.path}/$name-on.png',
                    ).writeAsBytesSync(bytes),
                  );
            }
          }
        }
        for (final shape in ['horizontal', 'vertical']) {
          final name = '$shape-none-interactive';
          await p.keyboard.press(pptr.Key.tab);
          await p.focus('#swap-$name');
          final focused = await read(p, name);
          expect(focused['focused'], isTrue);
          expect(focused['focusVisible'], isTrue);
          expect(focused['role'], 'button');
          final before = await p.evaluate<num>(
            "Number(document.querySelector('#swap-ready').dataset.builds)",
          );
          await p.keyboard.press(pptr.Key.enter);
          await p.waitForFunction(
            _revisionChanged,
            args: [before],
          );
          await settle(p);
          final selected = await read(p, name);
          expect(selected['values'], '[true]');
          expect(selected['ariaPressed'], 'true');
          final point = await p.evaluate<List<dynamic>>(
            '''
name=>{const e=document.querySelector('#swap-'+name);
const r=e.getBoundingClientRect(),vertical=name.startsWith('vertical');
const x=r.x+(vertical?12:70),y=r.y+(vertical?70:12);
const hit=document.elementFromPoint(x,y);
return [x,y,!!hit&&e.contains(hit),hit?.id,hit?.dataset.face??null];}
''',
            args: [name],
          );
          await p.mouse.click(pptr.Point(point[0] as num, point[1] as num));
          await settle(p);
          final after = await read(p, name);
          records.add({
            'phase': 'O2-interaction',
            'focus': focused,
            'selected': selected,
            'point': point,
            'after': after,
          });
          if (after['values'] != '[true, false]') {
            failures.add({
              'name': name,
              'expectedValues': '[true, false]',
              'actualValues': after['values'],
              'point': point,
            });
          }
        }
        for (final shape in ['horizontal', 'vertical']) {
          final name = '$shape-none-mode';
          final initial = await read(p, name);
          final before = await p.evaluate<num>(
            "Number(document.querySelector('#swap-ready').dataset.builds)",
          );
          await p.click('#true-$name');
          await p.waitForFunction(
            _revisionChanged,
            args: [before],
          );
          for (final mode in ['rotate', 'flip', 'none']) {
            final revision = await p.evaluate<num>(
              "Number(document.querySelector('#swap-ready').dataset.builds)",
            );
            await p.click('#mode-$mode-$name');
            await p.waitForFunction(
              _revisionChanged,
              args: [revision],
            );
            await settle(p);
            final row = await read(p, name);
            records.add({
              'phase': 'O2-mode-change',
              'mode': mode,
              'observed': row,
            });
            expect(row['animation'], mode);
            expect(row['checked'], 'true');
            expect(row['callbacks'], 0);
            expect(row['ownerNode'], initial['ownerNode']);
            expect(row['overlapNode'], initial['overlapNode']);
            final faces = (row['faces'] as List).cast<Map<String, dynamic>>();
            for (var i = 0; i < 2; i++) {
              expect(
                faces[i]['mount'],
                ((initial['faces'] as List)[i]
                    as Map<String, dynamic>)['mount'],
              );
              expect(
                faces[i]['faceNode'],
                ((initial['faces'] as List)[i]
                    as Map<String, dynamic>)['faceNode'],
              );
              expect(
                faces[i]['slotNode'],
                ((initial['faces'] as List)[i]
                    as Map<String, dynamic>)['slotNode'],
              );
              expect(faces[i]['inert'], faces[i]['name'] == 'off');
            }
            geometry(row, failures);
            await flipPaint(p, name, row);
          }
        }
      } finally {
        await p.close();
      }
      expect(
        failures,
        isEmpty,
        reason:
            'Same public content must own natural layout and its expected '
            'click region.',
      );
    },
  );
}
