import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

const _selectionClass = 'co-root-selection:co-selectable-selection';
const _rawColors = <(String, CoreColor, String)>[
  ('opaque', CoreColor(0xff1255aa), 'rgb(18, 85, 170)'),
  ('alpha', CoreColor(0x801255aa), 'rgba(18, 85, 170, 0.50)'),
  ('transparent', CoreColor.transparent, 'rgba(0, 0, 0, 0.00)'),
];

Map<String, String> _inline(dom.Element root) => {
  for (final declaration in (root.attributes['style'] ?? '').split(';'))
    if (declaration.indexOf(':') case final colon when colon >= 0)
      declaration.substring(0, colon).trim(): declaration
          .substring(colon + 1)
          .trim(),
};

Future<dom.Element> _root(Component component, String id) async {
  final body = await renderComponentBodyHtml(
    CoUIWeb(theme: .coui, enableThemeAnimation: false, child: component),
  );
  final root = html.parse(body).getElementById(id);
  expect(root, isNotNull);
  return root!;
}

Command _command({
  CoreCommandStyle? style,
  CoreCommandPresentation presentation = .inline,
  Styles? css,
}) => Command(
  id: 'command',
  groups: const [],
  autofocus: false,
  showFooter: false,
  presentation: presentation,
  commandStyle: style,
  css: css,
);

void main() {
  for (final (name, color, expected) in <(String, CoreColor?, String)>[
    ('default', null, 'selection:bg-primary-container'),
    (
      'token',
      const CoreColor.token(CoreColors.tertiary),
      'selection:bg-tertiary',
    ),
    (
      'token alpha',
      const CoreColor.token(CoreColors.tertiary, opacity: .5),
      'selection:bg-tertiary/50',
    ),
    (
      'fractional token alpha',
      const CoreColor.token(CoreColors.tertiary, opacity: .625),
      'selection:bg-tertiary/62',
    ),
    (
      'small token alpha',
      const CoreColor.token(CoreColors.tertiary, opacity: .005),
      'selection:bg-tertiary/0',
    ),
  ]) {
    test('SelectableText preserves $name classes', () async {
      final root = await _root(
        SelectableText(
          'selectable',
          id: 'selectable',
          selectableTextStyle: color == null
              ? null
              : CoreSelectableTextStyle(selectionColor: color),
        ),
        'selectable',
      );
      expect(root.classes, contains(expected));
      expect(root.classes, isNot(contains(_selectionClass)));
      expect(_inline(root), isNot(contains('--co-selectable-selection-color')));
    });
  }

  for (final (name, color, value) in _rawColors) {
    test('SelectableText renders $name raw selection color', () async {
      final root = await _root(
        SelectableText(
          'selectable',
          id: 'selectable',
          selectableTextStyle: CoreSelectableTextStyle(selectionColor: color),
        ),
        'selectable',
      );
      expect(root.text, 'selectable');
      expect(root.classes, contains(_selectionClass));
      expect(_inline(root)['--co-selectable-selection-color'], value);
      expect(
        root.classes.where((name) => name.startsWith('selection:bg-')),
        isEmpty,
      );
    });
  }

  test(
    'rich raw selection leaves the nested token declaration intact',
    () async {
      final root = await _root(
        const SelectableText.rich(
          id: 'selectable',
          selectableTextStyle: CoreSelectableTextStyle(
            selectionColor: CoreColor(0xff1255aa),
          ),
          enableInteractiveSelection: false,
          children: [
            Component.text('outer '),
            SelectableText(
              'inner',
              id: 'nested',
              selectableTextStyle: CoreSelectableTextStyle(
                selectionColor: CoreColor.token(CoreColors.tertiary),
              ),
            ),
          ],
        ),
        'selectable',
      );
      expect(root.classes, contains('select-none'));
      expect(root.classes, contains(_selectionClass));
      final nested = root.querySelector('#nested')!;
      expect(nested.classes, contains('selection:bg-tertiary'));
      expect(nested.classes, isNot(contains(_selectionClass)));
      expect(
        _inline(nested),
        isNot(contains('--co-selectable-selection-color')),
      );
    },
  );

  test('raw selection preserves caller text CSS and classes', () async {
    final root = await _root(
      const SelectableText(
        'selectable',
        id: 'selectable',
        classes: 'caller-selection',
        css: Styles(raw: {'color': 'rgb(7, 8, 9)'}),
        selectableTextStyle: CoreSelectableTextStyle(
          selectionColor: CoreColor(0xff1255aa),
        ),
      ),
      'selectable',
    );
    expect(root.classes, contains('caller-selection'));
    expect(_inline(root)['color'], 'rgb(7, 8, 9)');
    expect(
      _inline(root)['--co-selectable-selection-color'],
      'rgb(18, 85, 170)',
    );
  });

  for (final (presentation, borderClass, borderWidth) in [
    (CoreCommandPresentation.inline, 'border-outline-variant', '1'),
    (CoreCommandPresentation.dialog, 'border-outline-subtle', '1'),
    (CoreCommandPresentation.fullscreen, null, '0'),
  ]) {
    test('Command preserves ${presentation.name} defaults', () async {
      final root = await _root(
        _command(presentation: presentation),
        'command',
      );
      expect(root.classes, contains('bg-surface-bright'));
      if (borderClass != null) expect(root.classes, contains(borderClass));
      expect(
        _inline(root)['border-width'],
        'var(--coui-stroke-width-$borderWidth)',
      );
      expect(_inline(root)['--coui-surface-rgb'], 'var(--coui-surface-bright)');
      expect(_inline(root), isNot(contains('background-color')));
      expect(_inline(root), isNot(contains('border-color')));
    });
  }

  for (final (alpha, suffix) in [(.5, '50'), (.625, '62')]) {
    test('Command preserves token alpha $alpha on both panel slots', () async {
      final root = await _root(
        _command(
          style: CoreCommandStyle(
            backgroundColor: CoreColor.token(
              CoreColors.primary,
              opacity: alpha,
            ),
            borderColor: CoreColor.token(CoreColors.tertiary, opacity: alpha),
          ),
        ),
        'command',
      );
      expect(root.classes, contains('bg-primary/$suffix'));
      expect(root.classes, contains('border-tertiary/$suffix'));
      expect(_inline(root)['--coui-surface-rgb'], 'var(--coui-primary)');
      expect(_inline(root), isNot(contains('background-color')));
      expect(_inline(root), isNot(contains('border-color')));
    });
  }

  for (final (name, color, value) in _rawColors) {
    test(
      'Command emits $name panel colors without new utility classes',
      () async {
        final root = await _root(
          _command(
            style: CoreCommandStyle(backgroundColor: color, borderColor: color),
          ),
          'command',
        );
        final declarations = _inline(root);
        expect(declarations['border-color'], value);
        expect(declarations['border-width'], 'var(--coui-stroke-width-1)');
        expect(
          declarations['border-style'],
          'var(--coui-surface-edge-style,solid)',
        );
        expect(root.classes, contains('coui-surface-clip'));
        expect(root.classes, isNot(contains('border')));
        expect(
          root.classes.where((name) => name.startsWith('border-')),
          isEmpty,
        );
        expect(root.classes.where((name) => name.startsWith('bg-')), isEmpty);
        expect(declarations, isNot(contains('--coui-surface-rgb')));
        if (name == 'transparent') {
          expect(declarations, isNot(contains('background-color')));
        } else {
          expect(declarations['background-color'], value);
        }
      },
    );
  }

  test('Command retains zero-width raw border emission boundary', () async {
    final root = await _root(
      _command(
        style: const CoreCommandStyle(
          borderWidth: 0,
          borderColor: CoreColor(0xff1255aa),
        ),
      ),
      'command',
    );
    expect(_inline(root), isNot(contains('border-color')));
    expect(root.classes, isNot(contains('coui-surface-clip')));
  });

  for (final token in [false, true]) {
    test(
      'Command caller CSS overrides ${token ? 'token' : 'raw'} panel colors',
      () async {
        final color = token
            ? const CoreColor.token(CoreColors.primary)
            : const CoreColor(0xff1255aa);
        final root = await _root(
          _command(
            style: CoreCommandStyle(backgroundColor: color, borderColor: color),
            css: const Styles(
              raw: {
                'background-color': 'rgb(7, 8, 9)',
                'border-color': 'rgb(9, 8, 7)',
              },
            ),
          ),
          'command',
        );
        expect(_inline(root)['background-color'], 'rgb(7, 8, 9)');
        expect(_inline(root)['border-color'], 'rgb(9, 8, 7)');
      },
    );
  }
}
