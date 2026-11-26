import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart' as c;
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/widgets.dart' as fw;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../parity/parity_fonts.dart';

const _menus = [
  c.CoreMenubarMenu(
    label: 'File',
    entries: [c.CoreMenubarEntry.action(label: 'New document')],
  ),
  c.CoreMenubarMenu(
    label: 'Edit',
    entries: [c.CoreMenubarEntry.action(label: 'Cut selection')],
  ),
];

final _records = <Map<String, Object?>>[];

class _Recipe {
  const _Recipe(
    this.id, {
    required this.rest,
    required this.open,
    required this.contract,
    this.style,
    this.theme,
  });

  final String id;
  final c.CoreMenubarStyle? style;
  final c.CoreMenubarTheme? theme;
  final Map<String, Object?> rest;
  final Map<String, Object?> open;
  final String contract;
}

List<_Recipe> _recipes() => [
  const _Recipe(
    'default',
    rest: {'fontWeight': 400, 'fontSize': 14},
    open: {'fontWeight': 500, 'fontSize': 14},
    contract: 'Existing documented resting/open defaults',
  ),
  const _Recipe(
    'label-only',
    style: c.CoreMenubarStyle(
      labelTextStyle: c.CoreTextStyle(
        fontFamily: 'GeistSans',
        fontSize: 16,
        fontWeight: 700,
        lineHeight: 1.5,
        letterSpacing: .125,
        color: c.CoreColor.token(c.CoreColors.error, opacity: .3),
      ),
    ),
    rest: {
      'fontFamily': 'GeistSans',
      'fontWeight': 700,
      'fontSize': 16,
      'heightMultiplier': 1.5,
      'colorA': .3,
    },
    open: {
      'fontFamily': 'GeistSans',
      'fontWeight': 500,
      'fontSize': 16,
      'heightMultiplier': 1.5,
      'colorA': .3,
    },
    contract: 'Existing public label override; default open weight overlays it',
  ),
  _Recipe(
    'trigger-role-only',
    style: c.CoreMenubarStyle(
      triggerButtonStyle: c.CoreButtonStyle(
        labelStyle:
            const c.CoreTextStyle.token(
              c.CoreTextStyles.bodyLarge,
              color: c.CoreColor(0xff116633),
            ).merge(
              const c.CoreTextStyle(fontFamily: 'GeistMono', fontWeight: 600),
            ),
      ),
    ),
    rest: const {
      'fontFamily': 'GeistMono',
      'fontWeight': 600,
      'fontSize': 15,
      'heightMultiplier': 1.5,
      'colorA': 1,
      'colorR': 17,
      'colorG': 102,
      'colorB': 51,
    },
    open: const {
      'fontFamily': 'GeistMono',
      'fontWeight': 500,
      'fontSize': 15,
      'heightMultiplier': 1.5,
      'colorA': 1,
      'colorR': 17,
      'colorG': 102,
      'colorB': 51,
    },
    contract: 'Existing public trigger label slot and typed bodyLarge role',
  ),
  _Recipe(
    'same-layer-role-and-open',
    style: c.CoreMenubarStyle(
      labelTextStyle: const c.CoreTextStyle(
        fontFamily: 'GeistSans',
        fontSize: 18,
        fontWeight: 700,
        lineHeight: 2,
        letterSpacing: .125,
        color: c.CoreColor.token(c.CoreColors.error),
      ),
      triggerButtonStyle: c.CoreButtonStyle(
        labelStyle: const c.CoreTextStyle.token(
          c.CoreTextStyles.bodyLarge,
        ).merge(const c.CoreTextStyle(fontWeight: 600)),
      ),
      openTriggerButtonStyle: const c.CoreButtonStyle(
        labelStyle: c.CoreTextStyle(
          fontWeight: 800,
          color: c.CoreColor.token(c.CoreColors.warning, opacity: .5),
        ),
      ),
    ),
    rest: const {
      'fontFamily': 'GeistSans',
      'fontWeight': 600,
      'fontSize': 18,
      'heightMultiplier': 2,
      'colorA': 1,
    },
    open: const {
      'fontFamily': 'GeistSans',
      'fontWeight': 800,
      'fontSize': 18,
      'heightMultiplier': 2,
      'colorA': .5,
    },
    contract:
        'Same-layer label then trigger; role replaces size/line box; '
        'caller open overlays the existing default open layer',
  ),
  const _Recipe(
    'theme-trigger-widget-label',
    theme: c.CoreMenubarTheme(
      style: c.CoreMenubarStyle(
        triggerButtonStyle: c.CoreButtonStyle(
          labelStyle: c.CoreTextStyle(fontWeight: 600),
        ),
        openTriggerButtonStyle: c.CoreButtonStyle(
          labelStyle: c.CoreTextStyle(color: c.CoreColor(0xff663399)),
        ),
      ),
      variantStyles: {
        c.CoreMenubarVariant.standard: c.CoreMenubarStyle(
          labelTextStyle: c.CoreTextStyle(fontSize: 16),
        ),
      },
    ),
    style: c.CoreMenubarStyle(
      labelTextStyle: c.CoreTextStyle(fontWeight: 700),
      openTriggerButtonStyle: c.CoreButtonStyle(
        labelStyle: c.CoreTextStyle(fontWeight: 800),
      ),
    ),
    rest: {'fontWeight': 700, 'fontSize': 16},
    open: {
      'fontWeight': 800,
      'fontSize': 16,
      'colorR': 102,
      'colorG': 51,
      'colorB': 153,
      'colorA': 1,
    },
    contract:
        'Protect current working widget label over theme trigger; '
        'variant label and partial caller-open inputs remain separate',
  ),
  const _Recipe(
    'theme-label-widget-trigger',
    theme: c.CoreMenubarTheme(
      style: c.CoreMenubarStyle(
        labelTextStyle: c.CoreTextStyle(fontWeight: 600),
      ),
      variantStyles: {
        c.CoreMenubarVariant.standard: c.CoreMenubarStyle(
          triggerButtonStyle: c.CoreButtonStyle(
            labelStyle: c.CoreTextStyle(fontSize: 18),
          ),
        ),
      },
    ),
    style: c.CoreMenubarStyle(
      triggerButtonStyle: c.CoreButtonStyle(
        labelStyle: c.CoreTextStyle(fontWeight: 700),
      ),
    ),
    rest: {'fontWeight': 700, 'fontSize': 18},
    open: {'fontWeight': 500, 'fontSize': 18},
    contract: 'Inverse mixed layers; theme and variant precede the widget',
  ),
  const _Recipe(
    'theme-trigger-only',
    theme: c.CoreMenubarTheme(
      style: c.CoreMenubarStyle(
        triggerButtonStyle: c.CoreButtonStyle(
          labelStyle: c.CoreTextStyle(
            fontFamily: 'GeistMono',
            fontSize: 20,
            fontWeight: 600,
            lineHeight: 1.2,
            color: c.CoreColor(0xff2266aa),
          ),
        ),
      ),
    ),
    rest: {
      'fontFamily': 'GeistMono',
      'fontWeight': 600,
      'fontSize': 20,
      'heightMultiplier': 1.2,
      'colorR': 34,
      'colorG': 102,
      'colorB': 170,
      'colorA': 1,
    },
    open: {
      'fontFamily': 'GeistMono',
      'fontWeight': 500,
      'fontSize': 20,
      'heightMultiplier': 1.2,
      'colorR': 34,
      'colorG': 102,
      'colorB': 170,
      'colorA': 1,
    },
    contract: 'Existing theme nested label slot; default open changes weight',
  ),
];

Map<String, Object?>? _coreText(c.CoreTextStyle? style) => style == null
    ? null
    : {
        'token': style.token?.toString(),
        'fontFamily': style.fontFamily,
        'fontSize': style.fontSize,
        'fontWeight': style.fontWeight,
        'lineHeight': style.lineHeight,
        'lineHeightPx': style.lineHeightPx,
        'letterSpacing': style.letterSpacing,
        'color': style.color?.toString(),
      };

Map<String, Object?>? _coreStyle(c.CoreMenubarStyle? style) => style == null
    ? null
    : {
        'label': _coreText(style.labelTextStyle),
        'triggerLabel': _coreText(style.triggerButtonStyle?.labelStyle),
        'openLabel': _coreText(style.openTriggerButtonStyle?.labelStyle),
      };

Map<String, Object?> _style(fw.TextStyle? style) {
  final color = style?.color;
  final rgb = color?.toARGB32();
  return {
    'fontFamily': style?.fontFamily,
    'fontWeight': style?.fontWeight?.value,
    'fontSize': style?.fontSize,
    'heightMultiplier': style?.height,
    'letterSpacing': style?.letterSpacing,
    'colorA': color?.a,
    'colorR': rgb == null ? null : (rgb >> 16) & 255,
    'colorG': rgb == null ? null : (rgb >> 8) & 255,
    'colorB': rgb == null ? null : rgb & 255,
  };
}

Map<String, Object?> _label(
  WidgetTester tester,
  fw.GlobalKey key,
  String text,
) {
  final finder = find.descendant(
    of: find.byKey(key),
    matching: find.byWidgetPredicate(
      (widget) => widget is fw.RichText && widget.text.toPlainText() == text,
    ),
  );
  expect(finder, findsOneWidget);
  final object = tester.renderObject<rendering.RenderParagraph>(finder);
  final span = object.text as fw.TextSpan;
  return {
    'text': span.toPlainText(),
    'renderIdentity': identityHashCode(object),
    'attached': object.attached,
    'size': [object.size.width, object.size.height],
    'actualSpanInput': _style(span.style),
  };
}

void _assertFields(
  Map<String, Object?> actual,
  Map<String, Object?> expected,
) {
  final selected = {for (final key in expected.keys) key: actual[key]};
  expect(selected, expected);
}

void main() {
  setUpAll(loadParityFonts);
  tearDownAll(() {
    final path = Platform.environment['MENUBAR_PRIORITY_OBSERVATIONS'];
    if (path != null) File(path).writeAsStringSync(jsonEncode(_records));
  });
  for (final recipe in _recipes()) {
    for (final opened in [false, true]) {
      final state = opened ? 'open' : 'rest';
      testWidgets('${recipe.id} $state', (tester) async {
        final key = fw.GlobalKey();
        addTearDown(() async {
          await tester.pumpWidget(const fw.SizedBox.shrink());
          await tester.pumpAndSettle();
        });
        await pumpTestApp(
          tester,
          c.Menubar(key: key, menus: _menus, menubarStyle: recipe.style),
          theme: c.ThemeData.fromCore(c.CoreThemePresets.light),
          componentTheme: c.CoreComponentTheme(menubar: recipe.theme),
        );
        await tester.pumpAndSettle();
        final beforeState = tester.state(find.byKey(key));
        final before = _label(tester, key, 'File');
        if (opened) {
          await tester.tap(find.text('File'));
          await tester.pumpAndSettle();
        }
        final primary = _label(tester, key, 'File');
        final sibling = _label(tester, key, 'Edit');
        final stateSame = identical(beforeState, tester.state(find.byKey(key)));
        final panelVisible = find.text('New document').evaluate().isNotEmpty;
        _records.add({
          'case': '${recipe.id} $state',
          'contract': recipe.contract,
          'publicInputs': {
            'instance': _coreStyle(recipe.style),
            'themeBase': _coreStyle(recipe.theme?.style),
            'themeVariant': _coreStyle(
              recipe.theme?.variantStyles?[c.CoreMenubarVariant.standard],
            ),
          },
          'openedByPublicTriggerTap': opened,
          'panelVisible': panelVisible,
          'menubarStateRetained': stateSame,
          'beforePrimary': before,
          'actualPrimary': primary,
          'actualRestingSibling': sibling,
          'priorityTargetAsserted': true,
          'recordedPrimaryTarget': opened ? recipe.open : recipe.rest,
          'recordedSiblingTarget': recipe.rest,
          'quantity':
              'Actual RenderParagraph TextSpan input; no root probe '
              'or recreated resolver supplies the observation',
        });
        expect(stateSame, isTrue);
        expect(panelVisible, opened);
        expect(tester.takeException(), isNull);
        _assertFields(
          primary['actualSpanInput']! as Map<String, Object?>,
          opened ? recipe.open : recipe.rest,
        );
        _assertFields(
          sibling['actualSpanInput']! as Map<String, Object?>,
          recipe.rest,
        );
      });
    }
  }
}
