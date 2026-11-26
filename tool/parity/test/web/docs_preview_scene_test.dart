@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_core/shared/size_spec.dart';
import 'package:puppeteer/puppeteer.dart' show Browser, DeviceViewport;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/runtime_capture.dart';
import '../../src/web/web_capture_backend.dart';

void main() {
  late Browser browser;
  late Directory directory;
  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('docs-scene-browser-');
    browser = await launchCaptureBrowser(width: 800, height: 1200);
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });

  test(
    'documentation scenes keep the article containing block at two widths',
    () async {
      final buttons = readDocsScenes('button');
      final fields = readDocsScenes('text-field');
      final inputs = <(String, DocsScene)>[
        for (final tag in ['Preview', 'Anatomy', 'SizeSpec', 'Playground'])
          ('button', buttons.firstWhere((scene) => scene.tag == tag)),
        (
          'text-field',
          fields.firstWhere(
            (scene) =>
                scene.attributes['demo'] == 'text-field/do-helpful-error',
          ),
        ),
        ('text-field', fields.firstWhere((scene) => scene.tag == 'Anatomy')),
      ];
      final observations = <Map<String, Object?>>[];
      for (final (component, scene) in inputs) {
        for (final width in [800, 1000]) {
          final entry = _sceneEntry(component, scene, ParityTheme.light);
          final initialBody = await renderCaptureBodyHtml(
            entry,
            availableWidthPx: width,
          );
          final script = requiresClientCapture(entry)
              ? '<script>${await loadRuntimeCaptureScript()}</script>'
              : '';
          final file = writeHarnessFile(
            entry: entry,
            bodyHtml: '$initialBody$script',
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            fontFaceCss: buildLocalFontFaceCss(),
            iconifyHeadHtml: buildLocalIconifyHeadHtml(),
            harnessDir: directory,
          );
          final page = await browser.newPage();
          try {
            // Hold the responsive CSS branch while varying the article width.
            // Playground retains its authored controls column.
            await page.setViewport(
              const DeviceViewport(width: 1200, height: 1600),
            );
            await page.goto(
              Uri.file(file.absolute.path)
                  .replace(
                    fragment: jsonEncode({
                      'key': entry.key,
                      'component': component,
                      'variant': scene.reference,
                      'width': width,
                      'scene': scene.toJson(),
                    }),
                  )
                  .toString(),
            );
            await page.waitForFunction(
              runtimeCaptureReadyPredicate(entry, width),
            );
            await page.evaluate<void>('() => document.fonts.ready');
            final raw = await page.evaluate<String>(
              '''
(selector) => {
  const target = document.querySelector(selector);
  const host = target.closest('[data-docs-scene]');
  const wrapper = host.closest('[data-parity-key]');
  const body = host.querySelector(':scope > .content');
  const root = body.querySelector(':scope > .docs-stage, :scope > .docs-size-spec, :scope > .docs-playground, :scope > .docs-cards, :scope > .docs-anatomy');
  const card = host.querySelector('.docs-card');
  const stage = card ? card.querySelector(':scope > .docs-stage') : target;
  const grid = host.querySelector('.docs-playground-main');
  const controls = host.querySelector('.docs-playground-controls');
  const table = host.querySelector('.docs-size-spec table');
  const th = table && table.querySelector('th');
  const paragraph = card && card.querySelector('.docs-card-body p');
  const description = host.querySelector('.docs-anatomy-target p');
  const css = node => node && getComputedStyle(node);
  const tokenPx = (node, name) => {
    const value = css(node).getPropertyValue(name).trim();
    let number = Number.parseFloat(value);
    if (value.endsWith('rem')) number *= Number.parseFloat(css(document.documentElement).fontSize);
    else if (!value.endsWith('px')) throw new Error('Unsupported test token unit: ' + value);
    return number + 'px';
  };
  const boxWidth = node => node && node.getBoundingClientRect().width;
  return JSON.stringify({
    wrapperWidth: boxWidth(wrapper), hostWidth: boxWidth(host),
    sceneWidth: boxWidth(root), stageWidth: boxWidth(stage), targetWidth: boxWidth(target),
    isWholeCard: card && target === card, cardCount: host.querySelectorAll('.docs-cards > .docs-card').length,
    cardInnerWidth: card && card.clientWidth,
    cardBody: card && card.querySelector('.docs-card-body').innerText,
    cardClass: card && card.className,
    gridWidth: boxWidth(grid),
    gridColumns: grid && getComputedStyle(grid).gridTemplateColumns.split(' ').map(Number.parseFloat),
    controlsWidth: boxWidth(controls),
    contentCount: host.querySelectorAll(':scope > section.content').length,
    cardNotContent: card && card.parentElement.matches('.docs-cards.not-content'),
    paragraphMarginBottom: paragraph && css(paragraph).marginBottom,
    anatomyNotContent: host.querySelector('.docs-anatomy.not-content') !== null,
    descriptionColor: description && css(description).color,
    expectedDescriptionColor: description && 'rgb(' + css(description).getPropertyValue('--coui-on-surface-subtle').trim().split(' ').filter(Boolean).join(', ') + ')',
    tableWidth: boxWidth(table), tableParentWidth: table && table.parentElement.clientWidth,
    thPaddingTop: th && css(th).paddingTop,
    thExpectedPaddingTop: th && tokenPx(th, '--coui-space-10'),
    thPaddingRight: th && css(th).paddingRight,
    thExpectedPaddingRight: th && tokenPx(th, '--coui-space-24'),
    thFontSize: th && css(th).fontSize,
    // The shell's table header role (docs-shell.css `th`: label-medium).
    thExpectedFontSize: th && tokenPx(th, '--coui-text-label-medium-size'),
  });
}
''',
              args: [entry.probes.single.webSelector],
            );
            observations.add({
              ...((jsonDecode(raw) as Map).cast<String, Object?>()),
              'tag': scene.tag,
              'component': component,
              'width': width,
            });
          } finally {
            await page.close();
          }
        }
      }
      expect(
        observations.map((row) => row['hostWidth']),
        orderedEquals(observations.map((row) => row['width'])),
        reason: jsonEncode(observations),
      );
      for (final row in observations) {
        final width = row['width']! as num;
        expect(row['wrapperWidth'], closeTo(width, 0.05));
        expect(row['sceneWidth'], closeTo(width, 0.05));
        expect(row['contentCount'], 1);
        if (row['tag'] == 'Card') {
          expect(row['targetWidth'], closeTo(width, 0.05));
          expect(row['isWholeCard'], isTrue);
          expect(row['cardCount'], 1);
          expect(row['cardNotContent'], isTrue);
          expect(row['paragraphMarginBottom'], '0px');
          expect(
            row['stageWidth'],
            closeTo(row['cardInnerWidth']! as num, 0.05),
          );
          expect(row['cardBody'], contains('오류 문구에는 고치는 방법을 함께 씁니다.'));
          expect(row['cardClass'], contains('docs-card--do'));
        } else if (row['tag'] == 'SizeSpec') {
          expect(
            row['tableWidth'],
            closeTo(row['tableParentWidth']! as num, 0.05),
          );
          expect(row['thPaddingTop'], row['thExpectedPaddingTop']);
          expect(row['thPaddingRight'], row['thExpectedPaddingRight']);
          expect(row['thFontSize'], row['thExpectedFontSize']);
          expect(row['stageWidth'], closeTo(width, 0.05));
        } else if (row['tag'] == 'Anatomy') {
          expect(row['anatomyNotContent'], isTrue);
          expect(row['stageWidth'], closeTo(width, 0.05));
          if (row['component'] == 'text-field') {
            expect(row['descriptionColor'], row['expectedDescriptionColor']);
          }
        } else if (row['tag'] == 'Playground') {
          final columns = (row['gridColumns']! as List).cast<num>();
          expect(columns, hasLength(2));
          expect(row['stageWidth'], closeTo(columns.first, 0.05));
          expect(row['controlsWidth'], closeTo(columns.last, 0.05));
          expect(row['stageWidth']! as num, lessThan(width));
        } else {
          expect(row['stageWidth'], closeTo(width, 0.05));
        }
      }
      for (var index = 0; index < observations.length; index += 2) {
        expect(
          (observations[index + 1]['stageWidth']! as num) -
              (observations[index]['stageWidth']! as num),
          closeTo(200, 0.05),
        );
      }
    },
  );

  test('an SSR playground is not a completed client capture', () async {
    final scene = readDocsScenes('button').firstWhere(
      (scene) => scene.tag == 'Playground',
    );
    final entry = _sceneEntry('button', scene, ParityTheme.light);
    final initialBody = await renderCaptureBodyHtml(entry);
    final file = writeHarnessFile(
      entry: entry,
      bodyHtml: initialBody,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      fontFaceCss: buildLocalFontFaceCss(),
      iconifyHeadHtml: buildLocalIconifyHeadHtml(),
      harnessDir: directory,
    );
    final config = {
      'key': entry.key,
      'component': entry.component,
      'variant': entry.variant,
      'width': 800,
      'scene': scene.toJson(),
    };
    final predicate = runtimeCaptureReadyPredicate(entry, 800);
    final page = await browser.newPage();
    final errors = <String>[];
    page.onError.listen((error) => errors.add('$error'));
    try {
      await page.goto(
        Uri.file(
          file.absolute.path,
        ).replace(fragment: jsonEncode(config)).toString(),
      );
      expect(
        await page.$('[data-docs-scene="${scene.reference}"]'),
        isNotNull,
      );
      expect(await page.evaluate<bool>(predicate), isFalse);
      await page.addScriptTag(content: await loadRuntimeCaptureScript());
      await page.waitForFunction(predicate);
      expect(await page.evaluate<bool>(predicate), isTrue);
      expect(errors, isEmpty);
    } finally {
      await page.close();
    }
  });

  for (final theme in ParityTheme.values) {
    test(
      'current visible inputs reach real stages and editors, ${theme.name}',
      () async {
        final buttons = readDocsScenes('button');
        final fields = readDocsScenes('text-field');
        final inputs = <(String, DocsScene)>[
          ('button', buttons.firstWhere((scene) => scene.tag == 'Playground')),
          (
            'button',
            buttons.firstWhere(
              (scene) =>
                  scene.tag == 'VariantRow' &&
                  scene.attributes['name'] == 'outline',
            ),
          ),
          ('button', buttons.firstWhere((scene) => scene.tag == 'SizeSpec')),
          (
            'button',
            buttons.firstWhere(
              (scene) => scene.attributes['demo'] == 'button/states',
            ),
          ),
          (
            'text-field',
            fields.firstWhere(
              (scene) =>
                  scene.attributes['demo'] == 'text-field/do-helpful-error',
            ),
          ),
        ];
        for (final (component, scene) in inputs) {
          final entry = _sceneEntry(component, scene, theme);
          final key = entry.key;
          final initialBody = await renderCaptureBodyHtml(entry);
          final script = requiresClientCapture(entry)
              ? '<script>${await loadRuntimeCaptureScript()}</script>'
              : '';
          final file = writeHarnessFile(
            entry: entry,
            bodyHtml: '$initialBody$script',
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
            fontFaceCss: buildLocalFontFaceCss(),
            iconifyHeadHtml: buildLocalIconifyHeadHtml(),
            harnessDir: directory,
          );
          final page = await browser.newPage();
          try {
            final errors = <String>[];
            page.onError.listen((error) => errors.add('$error'));
            await page.goto(
              Uri.file(file.absolute.path)
                  .replace(
                    fragment: jsonEncode({
                      'key': key,
                      'component': component,
                      'variant': scene.reference,
                      'width': 800,
                      'scene': scene.toJson(),
                    }),
                  )
                  .toString(),
            );
            await page.waitForFunction(
              runtimeCaptureReadyPredicate(entry, 800),
            );
            await page.evaluate<void>('() => document.fonts.ready');
            final raw = await page.evaluate<String>(
              '''
(selector) => {
  const root = document.querySelector(selector);
  const buttons = [...root.querySelectorAll('button')];
  const input = root.querySelector('input');
  return JSON.stringify({
    theme: document.documentElement.dataset.theme,
    palette: getComputedStyle(root).getPropertyValue('--coui-on-surface').trim(),
    display: getComputedStyle(root).display,
    text: root.innerText,
    buttons: buttons.map(button => ({text:button.innerText.trim(), height:button.getBoundingClientRect().height})),
    input: input && {type:input.type, value:input.value},
    card: root.matches('.docs-card--preview') && {
      className: root.className,
      body: root.querySelector('.docs-card-body').innerText,
      radius: getComputedStyle(root.querySelector(':scope > .docs-stage')).borderTopLeftRadius,
      margin: getComputedStyle(root.querySelector(':scope > .docs-stage')).marginTop,
      borderColor: getComputedStyle(root.querySelector(':scope > .docs-stage')).borderBottomColor,
      success: getComputedStyle(root).getPropertyValue('--coui-success').trim(),
    },
  });
}
''',
              args: [entry.probes.single.webSelector],
            );
            final result = (jsonDecode(raw) as Map).cast<String, Object?>();
            expect(result['theme'], theme.name);
            final palette = theme == ParityTheme.dark
                ? CoreThemePresets.dark.colorScheme.onSurface
                : CoreThemePresets.light.colorScheme.onSurface;
            expect(
              result['palette'],
              '${palette!.red} ${palette.green} ${palette.blue}',
            );
            if (scene.tag == 'Card') {
              final card = (result['card']! as Map).cast<String, Object?>();
              expect(
                card['className'],
                contains('docs-card--${scene.attributes['tone']}'),
              );
              expect(card['body'], '오류 문구에는 고치는 방법을 함께 씁니다.');
              expect(card['radius'], '0px');
              expect(card['margin'], '0px');
              final channels = (card['success']! as String)
                  .split(RegExp(r'\s+'))
                  .join(', ');
              expect(card['borderColor'], 'rgb($channels)');
            }
            final actualButtons = (result['buttons']! as List)
                .cast<Map<String, Object?>>();
            if (scene.tag == 'Playground') {
              final spec = kDocsPlaygrounds['button']!;
              expect(
                actualButtons.any((node) => node['text'] == spec.label),
                isTrue,
              );
              expect(result['display'], 'flex');
            } else if (scene.tag == 'VariantRow') {
              expect(actualButtons.single['text'], scene.attributes['label']);
            } else if (scene.tag == 'SizeSpec') {
              expect(
                actualButtons.map((node) => node['height']),
                docsSizeSpecFor('button')!.rows.map(
                  (row) => CoreButtonStyle.defaultsBySize[row.size]!.height,
                ),
              );
            } else if (component == 'text-field') {
              expect(
                (result['input']! as Map<String, Object?>)['type'],
                'password',
              );
              expect(
                (result['input']! as Map<String, Object?>)['value'],
                '1234',
              );
              expect(result['text'], contains('8자 이상 입력해 주세요.'));
            } else {
              // The existing Web scene is a state grid. Rendering a primary
              // fallback without an exception does not verify the composite.
              expect(actualButtons.length, greaterThan(1));
              expect(result['display'], 'flex');
            }
            expect(errors, isEmpty);
          } finally {
            await page.close();
          }
        }
      },
    );
  }
}

MatrixEntry _sceneEntry(
  String component,
  DocsScene scene,
  ParityTheme theme,
) {
  final key = '$component-${scene.reference}-${theme.name}-defaultStyle';
  return MatrixEntry(
    component: component,
    variant: scene.reference,
    theme: theme,
    surfaceStyle: CoreSurfaceStyleId.defaultStyle,
    tier: ParityTier.t1,
    probes: captureProbes(
      key: key,
      component: component,
      variant: scene.reference,
      flutterClassName: scene.flutterOwnerType,
      docsScene: scene,
    ),
  );
}
