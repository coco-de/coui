@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

class _Case {
  const _Case(
    this.id, {
    required this.empty,
    required this.enabled,
    this.border,
    this.disabled,
    this.themeBorder,
    this.themeDisabled,
  });
  final String id;
  final bool empty;
  final bool enabled;
  final CoreColor? border;
  final CoreColor? disabled;
  final CoreColor? themeBorder;
  final CoreColor? themeDisabled;
  CoreColorPickerStyle get style =>
      CoreColorPickerStyle(borderColor: border, disabledBorderColor: disabled);
  CoreColorPickerStyle get themeStyle => CoreColorPickerStyle(
    borderColor: themeBorder,
    disabledBorderColor: themeDisabled,
  );
}

const _palette = <String, CoreColor>{
  'token': CoreColor.token(CoreColors.primary),
  'rawOpaque': CoreColor(0xFF123456),
  'rawAlpha': CoreColor(0x80446688),
};
const _borders = <String, CoreColor>{
  'token': CoreColor.token(CoreColors.outline),
  'rawOpaque': CoreColor(0xFFAA3355),
  'rawAlpha': CoreColor(0x80884422),
};
List<_Case> _cases() => [
  for (final empty in [false, true])
    for (final enabled in [true, false]) ...[
      _Case('default-$empty-$enabled', empty: empty, enabled: enabled),
      for (final b in _borders.entries)
        for (final d in _palette.entries)
          _Case(
            '${b.key}-${d.key}-$empty-$enabled',
            empty: empty,
            enabled: enabled,
            border: b.value,
            disabled: d.value,
          ),
      for (final override in [false, true])
        _Case(
          'theme-$override-$empty-$enabled',
          empty: empty,
          enabled: enabled,
          themeBorder: const CoreColor(0xFF227799),
          themeDisabled: const CoreColor(0xFF339955),
          disabled: override ? const CoreColor(0xFF8844CC) : null,
        ),
    ],
];

List<int> _expected(
  _Case c,
  bool enabled,
  String theme, {
  bool remapped = false,
}) {
  final color = enabled
      ? (c.border ?? c.themeBorder ?? CoreColorPickerStyle.defaultBorderColor)
      : (c.disabled ??
            c.themeDisabled ??
            CoreColorPickerStyle.defaultDisabledBorderColor);
  if (remapped && color.token == CoreColors.primary) return [1, 2, 3, 255];
  final scheme = theme == 'dark'
      ? CoreThemePresets.dark.colorScheme
      : CoreThemePresets.light.colorScheme;
  final resolved = scheme.resolve(color);
  return [
    resolved.red,
    resolved.green,
    resolved.blue,
    (resolved.effectiveOpacity * 255).round(),
  ];
}

Future<String> _body(String theme) => renderComponentBodyHtml(
  Component.fragment([
    Style(styles: docsContentTheme().styles),
    CoUIWeb(
      theme: .coui,
      themeMode: theme == 'dark' ? CoreThemeMode.dark : CoreThemeMode.light,
      child: div([
        for (final c in _cases())
          Theme(
            data: ThemeData(
              coreComponentTheme: CoreComponentTheme(
                colorPicker: CoreColorPickerTheme(style: c.themeStyle),
              ),
            ),
            child: ColorPicker(
              id: c.id,
              color: c.empty ? '' : '#446688',
              enabled: c.enabled,
              onChanged: (_) {},
              showHexInput: false,
              showLabel: false,
              colorPickerStyle: c.style,
            ),
          ),
      ]),
    ),
  ]),
);
// Read the emitted trigger's native :disabled state. The empty swatch's
// actual SVG stroke inherits the trigger's currentColor; it is not a border.
const _read = '''
() => [...document.querySelectorAll('[id]')]
  .filter(root => /^(default|token|rawOpaque|rawAlpha|theme)-/.test(root.id))
  .map(root => {
    const button = root.querySelector('button');
    const rect = button.querySelector('rect');
    const style = getComputedStyle(button);
    const box = button.getBoundingClientRect();
    const edge = rect ? getComputedStyle(rect).stroke : style.borderTopColor;
    const channels = edge.match(/[0-9.]+/g).map(Number);
    return {id: root.id, empty: !!rect, disabled: button.disabled,
      rgba: [...channels.slice(0, 3), Math.round((channels[3] ?? 1) * 255)],
      opacity: parseFloat(style.opacity), size: [box.width, box.height]};
  })
''';

void main() {
  test(
    'ColorPicker forwards disabled edge colours '
    'without overriding enabled or sibling edges',
    () async {
      final dir = Directory.systemTemp.createTempSync(
        'coui-color-picker-edge-',
      );
      final browser = await launchCaptureBrowser(width: 800, height: 600);
      final cases = {for (final c in _cases()) c.id: c};
      try {
        final page = await browser.newPage();
        final errors = <String>[];
        page.onError.listen((e) => errors.add('$e'));
        await page.setOfflineMode(true);
        for (final theme in ['light', 'dark']) {
          final body = await _body(theme);
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
          await page.evaluate<void>('()=>document.fonts.ready');
          Future<void> check(
            bool Function(_Case) enabled, {
            bool remapped = false,
          }) async {
            final rows = await page.evaluate<List<dynamic>>(_read);
            expect(rows, hasLength(cases.length));
            for (final raw in rows) {
              final row = raw as Map<String, dynamic>;
              final c = cases[row['id']]!;
              final on = enabled(c);
              expect(row['empty'], c.empty);
              expect(row['disabled'], !on);
              expect(
                row['rgba'],
                _expected(c, on, theme, remapped: remapped),
                reason: '$theme ${c.id} enabled=$on',
              );
              expect(
                row['opacity'],
                on || c.empty ? 1 : CoreClickableStyle.defaultDisabledOpacity,
              );
              expect(row['size'], [
                CoreColorPickerStyle.defaultSwatchSize,
                CoreColorPickerStyle.defaultSwatchSize,
              ]);
            }
          }

          await check((c) => c.enabled);
          // Reuse the same buttons through both native CSS states. Multiple raw
          // values coexist, so leaking a variable between instances fails.
          await page.evaluate<void>(
            '''
() => {
  for (const button of document.querySelectorAll('button')) {
    button.disabled = !button.disabled;
  }
}''',
          );
          await check((c) => !c.enabled);
          await page.evaluate<void>(
            '''
() => {
  for (const button of document.querySelectorAll('button')) {
    button.disabled = !button.disabled;
  }
}''',
          );
          await check((c) => c.enabled);
          await page.evaluate<void>(
            '''
() => {
  document.documentElement.style.setProperty('--coui-primary', '1 2 3');
  for (const button of document.querySelectorAll('button')) {
    button.disabled = true;
  }
}''',
          );
          await check((_) => false, remapped: true);
          await page.evaluate<void>(
            '''
() => {
  for (const button of document.querySelectorAll('button')) {
    button.disabled = false;
  }
}''',
          );
          await check((_) => true, remapped: true);
        }
        expect(errors, isEmpty);
      } finally {
        await browser.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}
