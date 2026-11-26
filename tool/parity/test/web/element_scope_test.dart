@Timeout(Duration(minutes: 5))
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart';
import 'package:jaspr/server.dart' as server;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';
import '../fixtures/element_scope_cases.dart';

void main() {
  late Directory directory;
  late HttpServer http;
  late pptr.Browser browser;
  late pptr.Page page;
  final errors = <Object>[];

  Future<void> settle() async {
    await page.evaluate<void>(
      '() => new Promise(done => requestAnimationFrame(() => '
      'requestAnimationFrame(done)))',
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Future<void> attachClient() async {
    await page.addScriptTag(url: 'http://127.0.0.1:${http.port}/client.js');
    await page.waitForFunction(
      '''
() => document.querySelector('#scope-ready,#partial-ready')
  .dataset.ready === 'true'
''',
    );
    await settle();
  }

  Future<void> open({
    bool partial = false,
    bool primitives = false,
    bool hydrate = true,
  }) async {
    await page.goto(
      'http://127.0.0.1:${http.port}/${partial
          ? 'partial'
          : primitives
          ? 'primitives'
          : 'cases'}.html'
      '${partial
          ? '?partial=true'
          : primitives
          ? '?primitives=true'
          : ''}',
      wait: pptr.Until.load,
    );
    await page.evaluate<void>('() => document.fonts.ready');
    await settle();
    if (hydrate) await attachClient();
  }

  Future<Map<String, dynamic>> state() => page.evaluate<Map<String, dynamic>>(
    '''
() => {
      const cases = [...document.querySelectorAll('[data-case]')];
      return Object.fromEntries(cases.map(outer => {
        const root=outer.firstElementChild, input=root.querySelector('input');
        const refs=['aria-labelledby','aria-describedby'].flatMap(name =>
          (root.getAttribute(name)||'').split(' ').filter(Boolean));
        return [outer.dataset.case, {id:root.id, cursor:getComputedStyle(root).cursor,
          caller:root.dataset.caller, callerClass:root.classList.contains('caller-root'),
          referenceCount:refs.length,referencesResolve:refs.every(id=>root.contains(document.getElementById(id))),
          sameRoot:!window.savedRoots||window.savedRoots[outer.dataset.case]===root,
          sameInput:!input||!window.savedInputs||window.savedInputs[outer.dataset.case]===input,
          value:input?.value, selection:input?[input.selectionStart,input.selectionEnd]:null,
          focused:input&&document.activeElement===input,
          count:root.querySelector('[data-count]')?.dataset.count}];
      }));
    }''',
  );

  Future<void> saveNodes() => page.evaluate<void>('''
() => {
    window.savedRoots=Object.fromEntries([...document.querySelectorAll('[data-case]')]
      .map(e=>[e.dataset.case,e.firstElementChild]));
    window.savedInputs=Object.fromEntries([...document.querySelectorAll('[data-case]')]
      .map(e=>[e.dataset.case,e.querySelector('input')]));
  }''');

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('coui-element-scope-');
    final fixture = File(
      'tool/parity/test/fixtures/element_scope_cases.dart',
    ).absolute.uri;
    final entry = File('${directory.path}/client.dart')
      ..writeAsStringSync('''
import 'package:coui_web/coui_web.dart';
import '$fixture';
void main()=>runApp(Uri.base.queryParameters['partial']=='true'
  ?elementScopeClientOwner():Uri.base.queryParameters['primitives']=='true'
  ?elementScopePrimitiveCases():elementScopeCases(),attachTo:'#mount');
''');
    final config = (await Isolate.packageConfig)!;
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      '-Djaspr.flags.release=true',
      '--packages=${config.toFilePath()}',
      entry.path,
      '-o',
      '${directory.path}/client.js',
    ]);
    expect(
      compiled.exitCode,
      0,
      reason: '${compiled.stdout}\n${compiled.stderr}',
    );

    Future<String> document(Component body) => renderComponentToDocumentHtml(
      server.Document(
        head: docsSharedHead(),
        styles: [...docsContentTheme().styles, ...docsPreviewStyles()],
        body: body,
      ),
    );
    // Render this first: it also covers a fresh server runtime beside a
    // fresh, independently hydrated client runtime, without resetting either.
    final partial = await document(
      div([
        elementScopeStaticOwner(),
        elementScopeStaticReference(),
        div(id: 'mount', [elementScopeClientOwner()]),
      ]),
    );
    File('${directory.path}/partial.html').writeAsStringSync(partial);
    // Warm the server through a previous request before the hydrated document.
    await document(div(id: 'mount', [elementScopeCases()]));
    final cases = await document(div(id: 'mount', [elementScopeCases()]));
    File('${directory.path}/cases.html').writeAsStringSync(cases);
    final primitives = await document(
      div(id: 'mount', [elementScopePrimitiveCases()]),
    );
    File('${directory.path}/primitives.html').writeAsStringSync(primitives);
    http = (await HttpServer.bind(InternetAddress.loopbackIPv4, 0))
      ..listen((request) async {
        final file = File('${directory.path}/${request.uri.path.substring(1)}');
        request.response.headers.contentType = request.uri.path.endsWith('.js')
            ? ContentType('application', 'javascript')
            : ContentType.html;
        if (file.existsSync()) {
          request.response.add(file.readAsBytesSync());
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });
    browser = await launchCaptureBrowser(width: 1000, height: 800);
  });
  setUp(() async {
    errors.clear();
    page = await browser.newPage();
    page.onError.listen(errors.add);
    await page.setRequestInterception(true);
    page.onRequest.listen((request) {
      if (request.url == 'https://cdn.tailwindcss.com/3.4.17') {
        unawaited(
          request.respond(
            contentType: 'application/javascript',
            body: loadVendoredTailwindScript(),
          ),
        );
      } else if (request.url.contains('iconify-icon.min.js')) {
        unawaited(
          request.respond(
            contentType: 'application/javascript',
            body: loadVendoredIconifyScript(),
          ),
        );
      } else if (request.url.contains('pretendard.min.css')) {
        unawaited(
          request.respond(
            contentType: 'text/css',
            body: buildLocalFontFaceCss(),
          ),
        );
      } else {
        unawaited(request.continueRequest());
      }
    });
  });
  tearDown(() async {
    expect(errors, isEmpty);
    await page.close();
  });
  tearDownAll(() async {
    await browser.close();
    await http.close(force: true);
    directory.deleteSync(recursive: true);
  });

  test(
    'hydrating one owner preserves a server-only owner and its hover paint',
    () async {
      await open(partial: true, hydrate: false);
      Future<String?> hoverColor(String selector) async {
        await page.hover(selector);
        await settle();
        return await page.$eval<String>(
          selector,
          'e=>getComputedStyle(e).backgroundColor',
        );
      }

      final reference = await hoverColor('#static-reference');
      final otherOwner = await hoverColor('#client-b > span');
      expect(reference, isNotNull);
      expect(otherOwner, isNotNull);
      expect(reference, isNot(otherOwner));
      await page.hover('#static-a > span');
      await settle();
      await page.evaluate<void>(
        '() => window.staticRoot=document.querySelector("#static-a > span")',
      );
      Future<Map<String, dynamic>> paint() =>
          page.evaluate<Map<String, dynamic>>('''
() => {
      const a=document.querySelector('#static-a > span'),b=document.querySelector('#client-b > span');
      return {color:getComputedStyle(a).backgroundColor,ownRule:a.querySelector('style').textContent,
        sameNode:a===window.staticRoot,distinct:a.id!==b.id};
    }''');
      final before = await paint();
      expect(before['color'], reference);
      await attachClient();
      final after = await paint();
      expect(after['color'], before['color']);
      expect(after['ownRule'], before['ownRule']);
      expect(after['sameNode'], isTrue);
      expect(after['distinct'], isTrue);
    },
  );

  test(
    'Badge and Progress isolate local keys and shared const configurations',
    () async {
      await open();
      for (final theme in ['light', 'dark']) {
        if (theme == 'dark') {
          await page.click('#scope-theme');
          await settle();
        }
        expect(
          await page.evaluate<String>(
            '() => document.documentElement.dataset.theme',
          ),
          theme,
        );
        final palette = theme == 'dark'
            ? ThemeData.dark.colorScheme
            : ThemeData.light.colorScheme;
        String rgb(CoreColor color) =>
            'rgb(${color.red}, ${color.green}, ${color.blue})';
        final paintedPalette = await page.evaluate<Map<String, dynamic>>('''
() => {const s=getComputedStyle(document.getElementById('scope-palette'));
return {ink:s.color, surface:s.backgroundColor};}
''');
        expect(paintedPalette['ink'], rgb(palette.onSurface!));
        expect(paintedPalette['surface'], rgb(palette.surface!));
        for (final type in ['badge', 'progress']) {
          final references = <String, Object?>{};
          for (final mode in [
            'unique',
            'local-key',
            'unkeyed',
            'const',
            'public-id',
          ]) {
            for (final side in ['a', 'b']) {
              final selector = '#case-$type-$mode-$side > :first-child';
              if (type == 'badge') {
                await page.hover(selector);
                await settle();
              }
              final actual = await page.evaluate<Object?>(
                '''
selector => {
              const root=document.querySelector(selector),fill=root.querySelector('.co-progress-indeterminate');
              if(!fill)return getComputedStyle(root).backgroundColor;
              const css=getComputedStyle(fill);return [css.width,css.animationDuration];
            }''',
                args: [selector],
              );
              if (mode == 'unique') references[side] = actual;
              expect(
                actual,
                references[side],
                reason: '$theme/$type/$mode/$side',
              );
            }
          }
        }
        final roots = await state();
        for (final row in roots.values.cast<Map<String, dynamic>>()) {
          expect(row['cursor'], 'crosshair');
          expect(row['caller'], 'kept');
          expect(row['callerClass'], isTrue);
          expect(row['referencesResolve'], isTrue);
        }
        expect(
          (roots['badge-public-id-a'] as Map<String, dynamic>)['id'],
          'caller-badge-a',
        );
        expect(
          (roots['progress-public-id-a'] as Map<String, dynamic>)['id'],
          'caller-progress-a',
        );
      }
      await page.click('#case-badge-unkeyed-a > span');
      expect(
        await page.evaluate<String>(
          '() => document.querySelector("#scope-ready").dataset.presses',
        ),
        '1',
      );
    },
  );

  test(
    'four primitive consumers retain their raw hover and focus paint',
    () async {
      await open(primitives: true);
      for (final theme in ['light', 'dark']) {
        if (theme == 'dark') {
          await page.click('#scope-theme');
          await settle();
        }
        expect(
          await page.evaluate<String>(
            '()=>document.documentElement.dataset.theme',
          ),
          theme,
        );
        final palette = theme == 'dark'
            ? ThemeData.dark.colorScheme
            : ThemeData.light.colorScheme;
        String rgb(CoreColor color) =>
            'rgb(${color.red}, ${color.green}, ${color.blue})';
        final painted = await page.evaluate<Map<String, dynamic>>('''
() => {const s=getComputedStyle(document.getElementById('scope-palette'));
return {ink:s.color, surface:s.backgroundColor};}
''');
        expect(painted['ink'], rgb(palette.onSurface!));
        expect(painted['surface'], rgb(palette.surface!));
        for (final type in [
          'button',
          'pagination',
          'disclosure',
          'chipinput',
        ]) {
          final references = <String, Object?>{};
          for (final mode in [
            'unique',
            'local-key',
            'unkeyed',
            'const',
            'public-id',
          ]) {
            for (final side in ['a', 'b']) {
              final outer = '#case-$type-$mode-$side';
              final selector = type == 'pagination'
                  ? '$outer [class*="co-pagination-h-"]'
                  : type == 'disclosure'
                  ? '$outer summary'
                  : '$outer > :first-child';
              if (type == 'disclosure') {
                await page.keyboard.press(pptr.Key.tab);
                await page.focus(selector);
              } else {
                await page.hover(selector);
              }
              await settle();
              final actual = await page.$eval<String>(selector, '''
e=>{const s=getComputedStyle(e);return ${type == 'disclosure'
                  ? 's.outlineColor'
                  : type == 'chipinput'
                  ? 's.borderColor'
                  : 's.backgroundColor'};}
''');
              if (type == 'disclosure') {
                expect(
                  await page.$eval<bool>(
                    selector,
                    'e=>e.matches(":focus-visible")',
                  ),
                  isTrue,
                );
              }
              if (mode == 'unique') references[side] = actual;
              expect(
                actual,
                references[side],
                reason: '$theme/$type/$mode/$side',
              );
            }
            expect(references['a'], isNot(references['b']));
          }
        }
        for (final row in (await state()).values.cast<Map<String, dynamic>>()) {
          expect(row['cursor'], 'crosshair');
          expect(row['caller'], 'kept');
          expect(row['callerClass'], isTrue);
        }
      }
      await page.click('#case-button-unkeyed-a > button');
      expect(
        await page.$eval<String>('#scope-ready', 'e=>e.dataset.presses'),
        '1',
      );
      await page.focus('#case-chipinput-unkeyed-a input');
      await page.type('#case-chipinput-unkeyed-a input', 'chip');
      await page.keyboard.press(pptr.Key.enter);
      await settle();
      expect(
        await page.$eval<String>('#scope-ready', 'e=>e.dataset.presses'),
        '2',
      );
    },
  );

  test(
    'warm SSR hydration and rebuilds preserve caller '
    'nodes, input and references',
    () async {
      await open(hydrate: false);
      final before = await state();
      await saveNodes();
      const input = '#input-progress-unkeyed-a';
      await page.click(input);
      await page.type(input, 'caller-owned-value');
      await page.$eval<void>(input, 'e => e.setSelectionRange(2,7)');
      await attachClient();
      final hydrated = await state();
      final row = hydrated['progress-unkeyed-a'] as Map<String, dynamic>;
      expect(row['sameInput'], isTrue);
      expect(row['value'], 'caller-owned-value');
      expect(row['selection'], [2, 7]);
      expect(
        (hydrated['progress-unkeyed-a'] as Map<String, dynamic>)['id'],
        isNot((before['progress-unkeyed-a'] as Map<String, dynamic>)['id']),
      );
      for (final value in hydrated.values.cast<Map<String, dynamic>>()) {
        expect(value['sameRoot'], isTrue);
        expect(value['referencesResolve'], isTrue);
      }
      // Observe client focus after hydration, independently of initial attach.
      await page.focus(input);
      expect(
        await page.$eval<bool>(input, 'e=>document.activeElement===e'),
        isTrue,
      );
      await page.$eval<void>('#count-progress-unkeyed-a', 'e=>e.click()');
      await settle();
      final ids = {
        for (final entry in hydrated.entries)
          entry.key: (entry.value as Map<String, dynamic>)['id'],
      };
      for (final action in ['scope-rebuild', 'scope-reorder']) {
        await page.$eval<void>('#$action', 'e=>e.click()');
        await settle();
        final current = await state();
        for (final entry in current.entries) {
          expect((entry.value as Map<String, dynamic>)['id'], ids[entry.key]);
          expect((entry.value as Map<String, dynamic>)['sameRoot'], isTrue);
          expect(
            (entry.value as Map<String, dynamic>)['referencesResolve'],
            isTrue,
          );
        }
        final caller = current['progress-unkeyed-a'] as Map<String, dynamic>;
        expect(caller['sameInput'], isTrue);
        expect(caller['value'], 'caller-owned-value');
        expect(caller['selection'], [2, 7]);
        expect(caller['count'], '2');
        if (action == 'scope-rebuild') {
          expect(
            await page.$eval<bool>(input, 'e=>document.activeElement===e'),
            isTrue,
          );
        }
      }
      await page.click('#scope-presence');
      await settle();
      expect((await state()).containsKey('progress-const-b'), isFalse);
      await page.click('#scope-presence');
      await settle();
      final remounted = await state();
      expect(
        (remounted['progress-const-b'] as Map<String, dynamic>)['id'],
        isNot(ids['progress-const-b']),
      );
      expect(
        (remounted['progress-const-a'] as Map<String, dynamic>)['id'],
        ids['progress-const-a'],
      );
      expect(
        (remounted['progress-const-b']
            as Map<String, dynamic>)['referencesResolve'],
        isTrue,
      );
    },
  );
}
