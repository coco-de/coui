import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  _rowIdentityContract();
  _dividerGeometryContract();
  _tokenTitleContract();
  test(
    'DescriptionCard title styles reach the rendered owned paragraph',
    () async {
      final cases = <String, CoreTextStyle?>{
        'default': null,
        'size': const CoreTextStyle(fontSize: 17),
        'ratio': const CoreTextStyle(fontSize: 17, lineHeight: 1.3),
        'fixed': const CoreTextStyle(
          fontSize: 17,
          lineHeight: 1.3,
          lineHeightPx: 20.3,
        ),
        'family': const CoreTextStyle(
          fontSize: 17,
          fontFamily: CoreFontFamily.mono,
        ),
        'all': const CoreTextStyle(
          fontSize: 17,
          lineHeight: 1.3,
          lineHeightPx: 20.3,
          fontFamily: CoreFontFamily.mono,
          fontWeight: CoreFontWeight.bold,
          letterSpacing: 0.03,
          color: CoreColor(0xFF123456),
        ),
      };
      final body = await renderComponentBodyHtml(
        CoUIWeb(
          theme: .coui,
          child: div([
            for (final entry in cases.entries)
              div([
                DescriptionCard(
                  title: 'Title AG09',
                  titleLeading: const span(
                    [Text('CALLER')],
                    styles: Styles(
                      raw: {'font-size': '13px', 'line-height': '1.7'},
                    ),
                  ),
                  rows: const [
                    DescriptionRow(label: 'Row AG09', value: 'Value AG09'),
                  ],
                  descriptionCardStyle: CoreDescriptionCardStyle(
                    titleColor: const CoreColor(0xFF654321),
                    titleTextStyle: entry.value,
                  ),
                ),
              ], id: entry.key),
          ]),
        ),
      );
      final dir = Directory.systemTemp.createTempSync(
        'coui-description-title-',
      );
      final browser = await launchCaptureBrowser(width: 900, height: 1600);
      try {
        final page = await browser.newPage();
        await page.setOfflineMode(true);
        for (final theme in ['light', 'dark']) {
          final file = File('${dir.path}/$theme.html')
            ..writeAsStringSync(
              buildOfflineTailwindHarnessHtml(
                bodyHtml: body,
                themeConfig: ThemeConfig.defaults(),
                theme: theme,
                vendoredTailwindScript: loadVendoredTailwindScript(),
                additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
              ),
            );
          await page.goto(file.uri.toString(), wait: .load);
          await page.evaluate<void>(
            '() => document.fonts.ready.then(() => {})',
          );
          final rows =
              jsonDecode(
                    await page.evaluate<String>('''
() => JSON.stringify([...document.querySelectorAll('div[id]')].filter(e=>
  ['default','size','ratio','fixed','family','all'].includes(e.id)).map(root=>{
    const find=text=>[...root.querySelectorAll('*')].find(e=>!e.children.length&&e.textContent===text);
    const measure=text=>{const e=find(text),s=getComputedStyle(e);return {
      size:s.fontSize,weight:s.fontWeight,line:s.lineHeight,family:s.fontFamily,
      tracking:s.letterSpacing,color:s.color,owner:e.parentElement.textContent,
    };};
    return {name:root.id,title:measure('Title AG09'),label:measure('Row AG09'),
      value:measure('Value AG09'),caller:measure('CALLER')};
  }))
'''),
                  )
                  as List;
          expect(rows, hasLength(cases.length));
          for (final row in rows.cast<Map<String, dynamic>>()) {
            final name = row['name'] as String;
            final title = row['title'] as Map<String, dynamic>;
            final reason = '$theme $name $row';
            expect(
              title['size'],
              name == 'default' ? '15px' : '17px',
              reason: reason,
            );
            expect(
              title['weight'],
              name == 'all' ? '700' : '600',
              reason: reason,
            );
            expect(title['line'], switch (name) {
              'default' => '21px',
              'ratio' => '22px',
              'fixed' || 'all' => '20px',
              _ => '24px',
            }, reason: reason);
            expect(
              title['family'],
              startsWith(
                name == 'family' || name == 'all'
                    ? '"Geist Mono"'
                    : 'Pretendard',
              ),
              reason: reason,
            );
            expect(
              title['color'],
              name == 'all' ? 'rgb(18, 52, 86)' : 'rgb(101, 67, 33)',
              reason: reason,
            );
            expect(title['owner'], 'Title AG09', reason: reason);
            if (name == 'all') {
              expect(title['tracking'], '0.51px', reason: reason);
            }
            final label = row['label'] as Map<String, dynamic>;
            final value = row['value'] as Map<String, dynamic>;
            expect(label['size'], '14px', reason: reason);
            expect(label['weight'], '400', reason: reason);
            expect(label['line'], '21px', reason: reason);
            expect(value['weight'], '500', reason: reason);
            expect(value['line'], '20px', reason: reason);
            final caller = row['caller'] as Map<String, dynamic>;
            expect(caller['size'], '13px', reason: reason);
            expect(caller['line'], '22.1px', reason: reason);
            expect(caller['owner'], 'CALLER', reason: reason);
          }
        }
      } finally {
        await browser.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}

void _tokenTitleContract() {
  test(
    'title tokens preserve Core merge, colors and reactive default roles',
    () async {
      final cases = <String, (CoreTextStyle?, CoreTextStyle?)>{
        'fallback': (null, null),
        'code': (null, const CoreTextStyle.token(CoreTextStyles.codeMd)),
        'raw': (
          null,
          const CoreTextStyle.token(CoreTextStyles.codeMd).copyWith(
            fontSize: 17,
            lineHeight: 1.3,
            lineHeightPx: 20.3,
            fontWeight: CoreFontWeight.bold,
            letterSpacing: 0.03,
            color: const CoreColor(0xFF123456),
          ),
        ),
        'replace': (
          const CoreTextStyle.token(CoreTextStyles.codeMd).copyWith(
            fontSize: 17,
            lineHeightPx: 20.3,
            fontWeight: CoreFontWeight.semiBold,
            letterSpacing: 0.02,
          ),
          const CoreTextStyle.token(CoreTextStyles.bodyLarge),
        ),
        'same': (
          const CoreTextStyle.token(CoreTextStyles.codeMd).copyWith(
            fontSize: 17,
            lineHeightPx: 20.3,
            fontWeight: CoreFontWeight.semiBold,
          ),
          const CoreTextStyle.token(CoreTextStyles.codeMd),
        ),
        'color': (
          null,
          const CoreTextStyle.token(
            CoreTextStyles.codeMd,
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      };
      final body = await renderComponentBodyHtml(
        CoUIWeb(
          theme: .coui,
          child: div([
            for (final entry in cases.entries)
              div([
                Theme(
                  data: ThemeData.coui.copyWith(
                    coreComponentTheme: CoreComponentTheme(
                      descriptionCard: CoreDescriptionCardTheme(
                        style: CoreDescriptionCardStyle(
                          titleTextStyle: entry.value.$1,
                        ),
                      ),
                    ),
                  ),
                  child: DescriptionCard(
                    title: 'Token title',
                    rows: const [DescriptionRow(label: 'Row', value: 'Value')],
                    descriptionCardStyle: CoreDescriptionCardStyle(
                      titleColor: const CoreColor(0xFF654321),
                      titleTextStyle: entry.value.$2,
                    ),
                  ),
                ),
              ], id: 'token-${entry.key}'),
            span(
              const [Text('Reference')],
              id: 'reference',
              styles: Styles(
                raw: {
                  'color': const CoreColor.token(CoreColors.primary).toValue(),
                },
              ),
            ),
          ]),
        ),
      );
      final dir = Directory.systemTemp.createTempSync('coui-title-token-');
      final browser = await launchCaptureBrowser(width: 900, height: 1600);
      try {
        final page = await browser.newPage();
        await page.setOfflineMode(true);
        for (final custom in [false, true]) {
          final typography = custom
              ? CoreTypography.coui.copyWith(
                  labelXl: const CoreTextStyle(
                    fontSize: 19,
                    lineHeight: 1.6,
                    fontWeight: 600,
                  ),
                )
              : CoreTypography.coui;
          for (final theme in ['light', 'dark']) {
            final file = File('${dir.path}/$custom-$theme.html')
              ..writeAsStringSync(
                buildOfflineTailwindHarnessHtml(
                  bodyHtml: body,
                  themeConfig: ThemeConfig.from(
                    CouiColorPresets.source,
                    typography: typography,
                  ),
                  theme: theme,
                  vendoredTailwindScript: loadVendoredTailwindScript(),
                  additionalHeadHtml:
                      '<style>${buildLocalFontFaceCss()}</style>',
                ),
              );
            await page.goto(file.uri.toString(), wait: .load);
            await page.evaluate<void>(
              '() => document.fonts.ready.then(() => {})',
            );
            final rows =
                jsonDecode(
                      await page.evaluate<String>('''
() => JSON.stringify([...document.querySelectorAll('div[id^="token-"]')].map(root=>{
  const e=[...root.querySelectorAll('*')].find(e=>!e.children.length&&e.textContent==='Token title');
  const s=getComputedStyle(e),owner=e.parentElement;
  return {name:root.id.slice(6),size:s.fontSize,weight:s.fontWeight,line:s.lineHeight,
    family:s.fontFamily,tracking:s.letterSpacing,color:s.color,classes:owner.className,inlineColor:owner.style.color,
    reference:getComputedStyle(document.getElementById('reference')).color};
}))
'''),
                    )
                    as List;
            expect(rows, hasLength(cases.length));
            for (final row in rows.cast<Map<String, dynamic>>()) {
              final name = row['name'] as String;
              final reason = '$custom $theme $row';
              final fallback = name == 'fallback';
              final fixed = name == 'raw' || name == 'same';
              expect(
                row['size'],
                fallback && custom
                    ? '19px'
                    : fixed
                    ? '17px'
                    : '15px',
                reason: reason,
              );
              expect(
                row['line'],
                fallback && custom
                    ? '30px'
                    : fixed
                    ? '20px'
                    : '21px',
                reason: reason,
              );
              expect(row['weight'], switch (name) {
                'raw' => '700',
                'replace' || 'same' => '600',
                'fallback' when custom => '600',
                // The title is SemiBold on every size rung
                // (`CoreDescriptionCardStyle.defaultTitleTextStyle`).
                _ => '600',
              }, reason: reason);
              expect(
                row['family'],
                startsWith(
                  fallback || name == 'replace' ? 'Pretendard' : '"Geist Mono"',
                ),
                reason: reason,
              );
              expect(
                row['color'],
                name == 'color'
                    ? row['reference']
                    : name == 'raw'
                    ? 'rgb(18, 52, 86)'
                    : 'rgb(101, 67, 33)',
                reason: reason,
              );
              if (name == 'color') {
                expect(row['inlineColor'], isEmpty, reason: reason);
                expect(
                  (row['classes'] as String)
                      .split(' ')
                      .where((value) => value == 'text-primary'),
                  hasLength(1),
                  reason: reason,
                );
              }
              if (name == 'raw') {
                expect(row['inlineColor'], 'rgb(18, 52, 86)', reason: reason);
              }
              if (!fallback) {
                final classes = (row['classes'] as String).split(' ');
                final roles = CoreTextStyles.values.map(
                  (role) => 'text-${role.name}',
                );
                final expectedRole = name == 'replace'
                    ? 'text-body-large'
                    : 'text-code-md';
                expect(classes.where(roles.contains), [
                  expectedRole,
                ], reason: reason);
              }
              if (name == 'raw') {
                expect(row['tracking'], '0.51px', reason: reason);
              }
              if (name == 'replace') {
                expect(row['tracking'], '0.3px', reason: reason);
              }
            }
          }
        }
      } finally {
        await browser.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}

void _dividerGeometryContract() {
  test('hiding the title rule preserves the surrounding layout', () async {
    final cases = <Component>[];
    for (final size in CoreDescriptionCardSize.values) {
      for (final gap in <double?>[null, 7.25, 0].indexed) {
        for (final title in <String?>[null, '', 'Title AG09'].indexed) {
          final pair = '${size.name}-${gap.$1}-${title.$1}';
          for (final visible in [true, false]) {
            Component caller(String name, String copy) => span(
              [Component.text(copy)],
              attributes: {'data-caller-slot': name},
            );
            cases.add(
              div(
                [
                  DescriptionCard(
                    id: 'card-$pair-$visible',
                    attributes: const {'aria-label': 'Details'},
                    size: size,
                    title: title.$2,
                    showDivider: visible,
                    titleLeading: caller('title-leading', 'L'),
                    titleTrailing: caller('title-trailing', 'R'),
                    rows: [
                      DescriptionRow(
                        label: 'Row AG09',
                        value: 'IGNORED',
                        valueWidget: caller('value', 'CUSTOM'),
                        leading: caller('row-leading', 'A'),
                        trailing: caller('row-trailing', 'Z'),
                      ),
                    ],
                    bottomAction: caller('bottom', 'ACTION'),
                    showBottomActionDivider: false,
                    descriptionCardStyle: CoreDescriptionCardStyle(
                      titleContentGapStyle: gap.$2 == null
                          ? null
                          : CoreGapStyle(size: gap.$2),
                    ),
                  ),
                ],
                attributes: {
                  'data-divider-pair': pair,
                  'data-divider-visible': '$visible',
                  'data-has-title': '${title.$2 != null}',
                },
                styles: const Styles(raw: {'width': '420px'}),
              ),
            );
          }
        }
      }
    }
    final body = await renderComponentBodyHtml(
      CoUIWeb(
        theme: .coui,
        child: div([
          // Measure the same public primitive the card composes. The
          // expectation follows its rendered thickness, not a copied token.
          const Divider(id: 'divider-reference'),
          ...cases,
        ]),
      ),
    );
    final dir = Directory.systemTemp.createTempSync('coui-description-gap-');
    final browser = await launchCaptureBrowser(width: 900, height: 1600);
    try {
      final page = await browser.newPage();
      await page.setOfflineMode(true);
      for (final theme in ['light', 'dark']) {
        final file = File('${dir.path}/$theme.html')
          ..writeAsStringSync(
            buildOfflineTailwindHarnessHtml(
              bodyHtml: body,
              themeConfig: ThemeConfig.defaults(),
              theme: theme,
              vendoredTailwindScript: loadVendoredTailwindScript(),
              additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
            ),
          );
        await page.goto(file.uri.toString(), wait: .load);
        await page.evaluate<void>('() => document.fonts.ready.then(() => {})');
        final result =
            jsonDecode(
                  await page.evaluate<String>('''
() => {
  const pairs = {};
  for (const host of document.querySelectorAll('[data-divider-pair]')) {
    const card = host.firstElementChild, root = card.getBoundingClientRect();
    const title = card.querySelector('div.flex.items-center');
    const value = card.querySelector('[data-caller-slot="value"]');
    const slots = [...card.querySelectorAll('[data-caller-slot]')].map(node => {
      const box = node.getBoundingClientRect(), style = getComputedStyle(node);
      return {name:node.dataset.callerSlot, tag:node.tagName, html:node.innerHTML,
        left:box.left-root.left, top:box.top-root.top,
        width:box.width, height:box.height, font:style.font,
        userSelect:style.userSelect};
    });
    const selection = window.getSelection(), range = document.createRange();
    range.selectNodeContents(card); selection.removeAllRanges();
    selection.addRange(range); const copy = selection.toString();
    selection.removeAllRanges();
    (pairs[host.dataset.dividerPair] ??= {})[host.dataset.dividerVisible] = {
      hasTitle:host.dataset.hasTitle === 'true', width:root.width,
      height:root.height, rowTop:value.getBoundingClientRect().top-root.top,
      titleBottom:title ? title.getBoundingClientRect().bottom-root.top : null,
      slots, copy, aria:card.getAttribute('aria-label'),
      ignored:card.textContent.includes('IGNORED')
    };
  }
  return JSON.stringify({
    divider:document.getElementById('divider-reference').getBoundingClientRect().height,
    pairs
  });
}
'''),
                )
                as Map<String, dynamic>;
        final thickness = result['divider'] as num;
        expect(thickness, greaterThan(0));
        final pairs = result['pairs'] as Map<String, dynamic>;
        expect(pairs, hasLength(cases.length ~/ 2));
        for (final entry in pairs.entries) {
          final pair = entry.value as Map<String, dynamic>;
          final on = pair['true'] as Map<String, dynamic>;
          final off = pair['false'] as Map<String, dynamic>;
          final removed = on['hasTitle'] == true ? thickness : 0;
          final reason = '$theme ${entry.key}';
          expect(on['width'], off['width'], reason: reason);
          expect(
            (on['height'] as num) - (off['height'] as num),
            removed,
            reason: reason,
          );
          expect(
            (on['rowTop'] as num) - (off['rowTop'] as num),
            removed,
            reason: reason,
          );
          if (on['hasTitle'] == true) {
            expect(on['titleBottom'], off['titleBottom'], reason: reason);
            expect(
              (on['rowTop'] as num) - (on['titleBottom'] as num) - thickness,
              (off['rowTop'] as num) - (off['titleBottom'] as num),
              reason: reason,
            );
          }
          expect(on['copy'], off['copy'], reason: reason);
          expect(on['aria'], 'Details', reason: reason);
          expect(off['aria'], 'Details', reason: reason);
          expect(on['ignored'], isFalse, reason: reason);
          expect(off['ignored'], isFalse, reason: reason);
          final onSlots = (on['slots'] as List).cast<Map<String, dynamic>>();
          final offSlots = (off['slots'] as List).cast<Map<String, dynamic>>();
          expect(onSlots.length, offSlots.length, reason: reason);
          for (var i = 0; i < onSlots.length; i++) {
            final a = onSlots[i];
            final b = offSlots[i];
            for (final key in [
              'name',
              'tag',
              'html',
              'left',
              'width',
              'height',
              'font',
              'userSelect',
            ]) {
              expect(a[key], b[key], reason: '$reason $key');
            }
            expect(
              (a['top'] as num) - (b['top'] as num),
              (a['name'] as String).startsWith('title-') ? 0 : removed,
              reason: '$reason ${a['name']}',
            );
          }
        }
      }
    } finally {
      await browser.close();
      dir.deleteSync(recursive: true);
    }
  });
}

// Add _rowIdentityContract() to main() after the existing contracts.
void _rowIdentityContract() {
  test('caller state survives title removal and restoration', () async {
    final dir = Directory.systemTemp.createTempSync(
      'coui-description-identity-',
    );
    try {
      final entry = File('${dir.path}/entry.dart')
        ..writeAsStringSync(_rowIdentityFixture);
      final js = File('${dir.path}/entry.js');
      final compile = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        '-O2',
        '-Djaspr.flags.release=true',
        '--packages=${File('.dart_tool/package_config.json').absolute.path}',
        entry.path,
        '-o',
        js.path,
      ]);
      expect(
        compile.exitCode,
        0,
        reason: '${compile.stdout}\n${compile.stderr}',
      );
      final html = File('${dir.path}/index.html')
        ..writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml:
                '<div id="identity-proof"></div><script>${js.readAsStringSync()}</script>',
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
          ),
        );
      final browser = await launchCaptureBrowser(width: 1440, height: 1200);
      try {
        final page = await browser.newPage();
        final errors = <String>[];
        page.onError.listen((error) => errors.add('$error'));
        await page.setOfflineMode(true);
        Future<void> settle() => page.evaluate<void>(
          '() => new Promise(r => requestAnimationFrame(() => '
          'requestAnimationFrame(r)))',
        );
        Future<void> click(String id) async {
          // A parent update must not steal focus as a physical control
          // click would.
          await page.evaluate<void>(
            'id => document.getElementById(id).click()',
            args: [id],
          );
          await settle();
        }

        for (final theme in ['light', 'dark']) {
          for (final keyed in [false, true]) {
            for (final copy in [false, true]) {
              final reason = '$theme callerKeys=$keyed copyWith=$copy';
              await page.goto(
                '${html.uri}?theme=$theme&keys=$keyed&copy=$copy',
                wait: .load,
              );
              await page.waitForSelector('#counter-value');
              await page.evaluate<void>('() => document.fonts.ready');
              await settle();
              await page.click('#counter-value');
              await page.click('#counter-bottom');
              await settle();
              await page.evaluate<void>('''
() => {
  window.callerRefs = Object.fromEntries(['value','bottom','row-leading','row-trailing']
    .map(name => [name, document.querySelector('#caller-'+name)]));
  window.callerKeys = Object.fromEntries(Object.entries(window.callerRefs)
    .map(([name, node]) => [name, node.dataset.key]));
  window.rowsRef = document.querySelector('#caller-value').parentElement.parentElement.parentElement;
  const node = document.querySelector('#selection-value');
  node.focus(); window.selectionElement = node; window.selectionAnchor = node.firstChild;
  const range = document.createRange(); range.setStart(node.firstChild,7); range.setEnd(node.firstChild,16);
  const selection = window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
}
''');
              var titled = true;
              Future<void> verify(String phase) async {
                final actual = await page.evaluate<Map<String, dynamic>>('''
() => {
  const card = document.querySelector('#caller-card'), selection = window.getSelection();
  const range = document.createRange(); range.selectNodeContents(card);
  return {
    callers: Object.entries(window.callerRefs).map(([name, before]) => {
      const now = document.querySelector('#caller-'+name);
      return {name, same: now===before, count: Number(now.dataset.count),
        keySame: now.dataset.key===window.callerKeys[name],
        keyIsNull: now.dataset.key==='null'};
    }),
    selection: {text: selection.toString(), anchorSame: selection.anchorNode===window.selectionAnchor,
      anchor: selection.anchorOffset, focus: selection.focusOffset,
      focused: document.activeElement===window.selectionElement},
    rowsSame: document.querySelector('#caller-value').parentElement.parentElement.parentElement===window.rowsRef,
    titlePresent: !!document.querySelector('#caller-leading'),
    order: [...card.querySelectorAll('[id^="caller-"]')].map(node=>node.id),
    copiedText: range.toString(), aria: card.getAttribute('aria-label'), caller: card.dataset.caller,
    theme: document.documentElement.dataset.theme,
  };
}
''');
                final context = '$reason $phase $actual';
                final callers = (actual['callers'] as List<dynamic>)
                    .cast<Map<String, dynamic>>();
                for (final caller in callers) {
                  expect(caller['same'], isTrue, reason: context);
                  expect(
                    caller['count'],
                    ['value', 'bottom'].contains(caller['name']) ? 1 : 0,
                    reason: context,
                  );
                  expect(caller['keySame'], isTrue, reason: context);
                  expect(caller['keyIsNull'], !keyed, reason: context);
                }
                expect(actual['selection'], {
                  'text': 'selection',
                  'anchorSame': true,
                  'anchor': 7,
                  'focus': 16,
                  'focused': true,
                }, reason: context);
                expect(actual['rowsSame'], isTrue, reason: context);
                expect(actual['titlePresent'], titled, reason: context);
                expect(actual['order'], [
                  if (titled) ...['caller-leading', 'caller-trailing'],
                  'caller-row-leading',
                  'caller-value',
                  'caller-row-trailing',
                  'caller-bottom',
                ], reason: context);
                expect(
                  actual['copiedText'],
                  isNot(contains('IGNORED')),
                  reason: context,
                );
                expect(actual['aria'], 'Details', reason: context);
                expect(actual['caller'], 'preserved', reason: context);
                expect(actual['theme'], theme, reason: context);
              }

              await verify('initial');
              for (var i = 0; i < 10; i++) {
                await click('toggle-divider');
                await verify('divider $i');
              }
              for (var i = 0; i < 3; i++) {
                await click('toggle-gap');
                await verify('gap $i');
              }
              for (var i = 0; i < 2; i++) {
                await click('empty-title');
                await verify('empty title $i');
              }
              for (var i = 0; i < 10; i++) {
                titled = !titled;
                await click('toggle-title');
                await verify('title $i');
              }
            }
          }
        }
        expect(errors, isEmpty);
      } finally {
        await browser.close();
      }
    } finally {
      dir.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

const _rowIdentityFixture = r'''
import 'package:coui_web/coui_web.dart' hide runApp;
import 'package:jaspr/client.dart' as client;
void main() {
  client.Jaspr.initializeApp();
  final query = Uri.base.queryParameters;
  final theme = query['theme'] ?? 'light';
  CoUIThemeController.setTheme(theme);
  client.runApp(Component.fragment([
    Document.html(attributes: {'data-theme': theme}),
    CoUIWeb(theme: ThemeData.coui,
      themeMode: theme == 'dark' ? CoreThemeMode.dark : CoreThemeMode.light,
      child: _Probe(keyed: query['keys'] == 'true', copy: query['copy'] == 'true')),
  ]), attachTo: '#identity-proof');
}
class _Probe extends StatefulComponent {
  const _Probe({required this.keyed, required this.copy});
  final bool keyed, copy;
  @override State<_Probe> createState() => _ProbeState();
}
class _ProbeState extends State<_Probe> {
  String? title = 'Title AG09'; bool divider = true; double? gap;
  Component caller(String name) => _Caller(name,
    key: component.keyed ? ValueKey('caller-$name') : null);
  @override Component build(BuildContext context) {
    final card = DescriptionCard(
      id: 'caller-card', attributes: const {'aria-label': 'Details', 'data-caller': 'preserved'},
      title: title, showDivider: divider,
      titleLeading: caller('leading'), titleTrailing: caller('trailing'),
      bottomAction: caller('bottom'), showBottomActionDivider: false,
      rows: [DescriptionRow(label: 'Row AG09', value: 'IGNORED',
        valueWidget: caller('value'), leading: caller('row-leading'), trailing: caller('row-trailing'))],
      descriptionCardStyle: CoreDescriptionCardStyle(
        titleContentGapStyle: gap == null ? null : CoreGapStyle(size: gap)),
    );
    return div([
      button([const Component.text('Toggle divider')], id: 'toggle-divider', onClick: () => setState(() => divider = !divider)),
      button([const Component.text('Toggle title')], id: 'toggle-title', onClick: () => setState(() => title = title == null ? 'Title AG09' : null)),
      button([const Component.text('Empty title')], id: 'empty-title', onClick: () => setState(() => title = title == '' ? 'Title AG09' : '')),
      button([const Component.text('Toggle gap')], id: 'toggle-gap', onClick: () => setState(() => gap = gap == null ? 7.25 : gap == 7.25 ? 0 : null)),
      div([component.copy ? card.copyWith(showDivider: divider) : card], id: 'card-host',
        styles: const Styles(raw: {'width': '720px'})),
    ]);
  }
}
class _Caller extends StatefulComponent {
  const _Caller(this.name, {super.key}); final String name;
  @override State<_Caller> createState() => _CallerState();
}
class _CallerState extends State<_Caller> {
  static int next = 0; late final int serial; int count = 0;
  @override void initState() { super.initState(); serial = next++; }
  @override Component build(BuildContext context) => div([
    button([Component.text('${component.name}:$count')],
      id: 'counter-${component.name}', onClick: () => setState(() => count++)),
    if (component.name == 'value') Component.element(tag: 'span',
      id: 'selection-value', attributes: const {'contenteditable': 'true', 'tabindex': '0'},
      children: const [Component.text('Caller selection value')]),
  ], id: 'caller-${component.name}', attributes: {
    'data-serial': '$serial', 'data-key': '${component.key}', 'data-count': '$count',
  });
}
''';
