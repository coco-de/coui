import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

const _selectionVar = '--co-selectable-selection-color';
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

Future<dom.Document> _render(String name, Component component) async {
  final body = await renderComponentBodyHtml(
    CoUIWeb(theme: .coui, enableThemeAnimation: false, child: component),
  );
  final output = Platform.environment['RAW_PSEUDO_BODY_DIR'];
  if (output != null) {
    final dir = Directory(output)..createSync(recursive: true);
    File('${dir.path}/$name.html').writeAsStringSync(body);
  }
  return html.parse(body);
}

List<String> _paintClasses(dom.Element root) => [
  for (final name in root.classes)
    if (name == _selectionClass) name,
];

void _expectSharedRootPaint(dom.Element root, String color) {
  expect(_inline(root)[_selectionVar], color);
  // A raw pseudo declaration must use the documented shared paint path.
  // Its value still comes from the actual instance's inline property.
  expect(
    root.classes.where((name) => name.startsWith('[&::selection]:')),
    isEmpty,
  );
  expect(_paintClasses(root), hasLength(1));
  // The actual configured utility sheet owns this rule, alongside the
  // caller utilities. Root-only semantics are a named variant, not a
  // descendant selector or a stronger selector in the early token sheet.
  final config = ThemeConfig.defaults();
  const variant = 'addVariant("co-root-selection","&::selection");';
  const utility =
      'addUtilities({".co-selectable-selection":{'
      'backgroundColor:"var($_selectionVar)"}});';
  expect(config.tailwindConfig.split(variant), hasLength(2));
  expect(config.tailwindConfig.split(utility), hasLength(2));
  expect(utility, isNot(contains('!important')));
  expect(variant, isNot(contains(' *')));
  expect(
    config.cssVariables,
    isNot(contains('.co-selectable-selection::selection')),
  );
}

void main() {
  for (final (name, color, expected) in _rawColors) {
    test(
      'raw $name selection uses one shared root paint declaration',
      () async {
        final document = await _render(
          name,
          SelectableText(
            'selectable',
            id: 'selection-owner',
            selectableTextStyle: CoreSelectableTextStyle(selectionColor: color),
          ),
        );
        final root = document.getElementById('selection-owner')!;
        expect(root.text, 'selectable');
        _expectSharedRootPaint(root, expected);
      },
    );
  }

  test('default and token owners retain their existing classes', () async {
    final document = await _render(
      'token-controls',
      const Frame(
        children: [
          SelectableText('default', id: 'default-owner'),
          SelectableText(
            'token',
            id: 'token-owner',
            selectableTextStyle: CoreSelectableTextStyle(
              selectionColor: CoreColor.token(CoreColors.tertiary, opacity: .5),
            ),
          ),
        ],
      ),
    );
    for (final (id, expected) in [
      ('default-owner', 'selection:bg-primary-container'),
      ('token-owner', 'selection:bg-tertiary/50'),
    ]) {
      final root = document.getElementById(id)!;
      expect(root.classes, contains(expected));
      expect(_inline(root), isNot(contains(_selectionVar)));
      expect(_paintClasses(root), isEmpty);
    }
  });

  test(
    'rich raw parent and nested token keep independent declarations',
    () async {
      final document = await _render(
        'raw-outer-token-inner',
        const SelectableText.rich(
          id: 'raw-parent',
          selectableTextStyle: CoreSelectableTextStyle(
            selectionColor: CoreColor(0xff1255aa),
          ),
          children: [
            Component.text('outer '),
            SelectableText(
              'inner',
              id: 'token-child',
              selectableTextStyle: CoreSelectableTextStyle(
                selectionColor: CoreColor.token(CoreColors.tertiary),
              ),
            ),
          ],
        ),
      );
      final child = document.getElementById('token-child')!;
      expect(child.classes, contains('selection:bg-tertiary'));
      expect(_inline(child), isNot(contains(_selectionVar)));
      expect(_paintClasses(child), isEmpty);
      _expectSharedRootPaint(
        document.getElementById('raw-parent')!,
        'rgb(18, 85, 170)',
      );
    },
  );

  test(
    'nested raw owner does not replace its token parent declaration',
    () async {
      final document = await _render(
        'token-outer-raw-inner',
        const SelectableText.rich(
          id: 'token-parent',
          selectableTextStyle: CoreSelectableTextStyle(
            selectionColor: CoreColor.token(CoreColors.tertiary),
          ),
          children: [
            Component.text('outer '),
            SelectableText(
              'inner',
              id: 'raw-child',
              selectableTextStyle: CoreSelectableTextStyle(
                selectionColor: CoreColor(0x801255aa),
              ),
            ),
          ],
        ),
      );
      final parent = document.getElementById('token-parent')!;
      expect(parent.classes, contains('selection:bg-tertiary'));
      expect(_inline(parent), isNot(contains(_selectionVar)));
      expect(_paintClasses(parent), isEmpty);
      _expectSharedRootPaint(
        document.getElementById('raw-child')!,
        'rgba(18, 85, 170, 0.50)',
      );
    },
  );

  test('caller channels and rich leaf DOM remain present', () async {
    final document = await _render(
      'caller-rich',
      const SelectableText.rich(
        id: 'caller-owner',
        classes: 'selection:bg-error !selection:bg-primary caller-class',
        css: Styles(raw: {'color': 'rgb(7, 8, 9)'}),
        selectableTextStyle: CoreSelectableTextStyle(
          selectionColor: CoreColor(0xff1255aa),
        ),
        children: [
          Component.element(
            tag: 'span',
            id: 'rich-leaf',
            children: [Component.text('rich')],
          ),
        ],
      ),
    );
    final root = document.getElementById('caller-owner')!;
    expect(
      root.classes,
      containsAll([
        'selection:bg-error',
        '!selection:bg-primary',
        'caller-class',
      ]),
    );
    expect(_inline(root)['color'], 'rgb(7, 8, 9)');
    expect(root.querySelector('#rich-leaf')!.text, 'rich');
    _expectSharedRootPaint(root, 'rgb(18, 85, 170)');
  });
}
