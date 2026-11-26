import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

const _variable = '--focus-border-color';
const _within = 'co-input-focus-border-within';
const _inlineCompetition = 'co-input-focus-border-inline';
const _frame = 'co-text-area-frame-focus-border';
const _frameFocus = ':has(>:first-child>textarea:focus-visible)';
const _normalRule =
    '.$_within:focus-within,.$_frame$_frameFocus'
    '{border-color:var($_variable);}';
const _inlineRule =
    ':where(.$_inlineCompetition:focus-within)'
    '{border-color:var($_variable) !important;}';
const _raw = CoreColor(0xff1255aa);
const _rest = CoreColor(0xff446622);

const _field = 'field';
const _affixedField = 'affixedField';
const _area = 'area';
const _footedArea = 'footedArea';
const List<String> _owners = [_field, _affixedField, _area, _footedArea];

typedef _Recipe = ({
  String name,
  CoreColor color,
  String css,
  double activeWidth,
  bool enabled,
  bool hasAddedBand,
});

const _recipes = <_Recipe>[
  (
    name: 'raw opaque without an added band',
    color: _raw,
    css: 'rgb(18, 85, 170)',
    activeWidth: 1,
    enabled: true,
    hasAddedBand: false,
  ),
  (
    name: 'raw opaque with an added band',
    color: _raw,
    css: 'rgb(18, 85, 170)',
    activeWidth: 1.5,
    enabled: true,
    hasAddedBand: true,
  ),
  (
    name: 'raw alpha',
    color: CoreColor(0x801255aa),
    css: 'rgba(18, 85, 170, 0.50)',
    activeWidth: 1.5,
    enabled: true,
    hasAddedBand: true,
  ),
  (
    name: 'transparent',
    color: CoreColor.transparent,
    css: 'rgba(0, 0, 0, 0.00)',
    activeWidth: 1.5,
    enabled: true,
    hasAddedBand: false,
  ),
  (
    name: 'a distinct focus token',
    color: CoreColor.token(CoreColors.error),
    css: 'rgb(var(--coui-error))',
    activeWidth: 1.5,
    enabled: true,
    hasAddedBand: true,
  ),
  (
    name: 'disabled raw alpha',
    color: CoreColor(0x801255aa),
    css: 'rgba(18, 85, 170, 0.50)',
    activeWidth: 1.5,
    enabled: false,
    hasAddedBand: false,
  ),
];

Map<String, String> _inline(dom.Element element) => {
  for (final declaration in (element.attributes['style'] ?? '').split(';'))
    if (declaration.indexOf(':') case final colon when colon >= 0)
      declaration.substring(0, colon).trim(): declaration
          .substring(colon + 1)
          .trim(),
};

List<String> _markers(dom.Element element) => [
  for (final name in element.classes)
    if ({_within, _inlineCompetition, _frame}.contains(name)) name,
];

List<String> _focusClasses(dom.Element element) => [
  for (final name in element.classes)
    if (name.startsWith('focus-within:border-') ||
        name.startsWith('[&$_frameFocus]:border-'))
      name,
];

Component _subject(
  String owner, {
  CoreColor? focusColor,
  CoreColor? restingColor,
  double activeWidth = 1,
  bool enabled = true,
  bool readOnly = false,
  bool error = false,
  Component? footer,
}) {
  if (owner == _field || owner == _affixedField) {
    final affixed = owner == _affixedField;
    return TextField(
      id: 'subject',
      initialValue: 'Focus stroke witness',
      enabled: enabled,
      readOnly: readOnly,
      errorText: error ? 'Invalid input' : null,
      prefix: affixed ? const Text('Prefix') : null,
      suffix: affixed ? const Text('Suffix') : null,
      textFieldStyle: CoreTextFieldStyle(
        borderWidth: CoreStrokeWidth.stroke1,
        activeBorderWidth: activeWidth,
        borderColor: restingColor,
        focusBorderColor: focusColor,
      ),
    );
  }
  return TextArea(
    id: 'subject',
    initialValue: 'Focus stroke witness',
    rows: 2,
    enabled: enabled,
    readOnly: readOnly,
    errorText: error ? 'Invalid input' : null,
    footer: owner == _footedArea ? footer ?? const Text('Footer') : null,
    textAreaStyle: CoreTextAreaStyle(
      borderWidth: CoreStrokeWidth.stroke1,
      activeBorderWidth: activeWidth,
      borderColor: restingColor,
      focusBorderColor: focusColor,
    ),
  );
}

typedef _Rendered = ({dom.Element root, dom.Element editor, dom.Element box});

Future<_Rendered> _render(String owner, Component component) async {
  final body = await renderComponentBodyHtml(
    CoUIWeb(theme: .coui, enableThemeAnimation: false, child: component),
  );
  final root = html.parse(body).getElementById('subject')!;
  final field = owner == _field || owner == _affixedField;
  final editor = root.querySelector(field ? 'input' : 'textarea')!;
  final box = owner == _footedArea ? editor.parent!.parent! : editor.parent!;
  expect(box.localName, 'div');
  expect(identical(box, root), isFalse);
  expect(_markers(editor), isEmpty);
  expect(_inline(editor), isNot(contains(_variable)));
  if (field) {
    expect(editor.classes, contains('border-0'));
    expect(editor.attributes['value'], 'Focus stroke witness');
  } else {
    expect(_inline(editor)['border-width'], '0');
    expect(editor.text, 'Focus stroke witness');
  }
  return (root: root, editor: editor, box: box);
}

void _expectNormalReader(String owner, dom.Element box, String value) {
  expect(_inline(box)[_variable], value);
  expect(_markers(box), [if (owner == _footedArea) _frame else _within]);
  expect(_focusClasses(box), isEmpty);
  // This is the configured consumer of the actual box's value, not a
  // computed-style substitute. Browser focus/cascade has a separate live gate.
  expect(ThemeConfig.defaults().cssVariables.split(_normalRule), hasLength(2));
}

void main() {
  test(
    'shared border readers keep state predicates and bounded importance',
    () {
      final css = ThemeConfig.defaults().cssVariables;
      expect(css.split(_normalRule), hasLength(2));
      expect(css.split(_inlineRule), hasLength(2));
      // Whole :where is deliberate: beating our own normal inline border
      // must not give this important declaration extra selector specificity.
      expect(
        css,
        isNot(contains('.$_inlineCompetition:where(:focus-within)')),
      );
    },
  );

  for (final owner in _owners) {
    for (final recipe in _recipes) {
      test(
        '$owner publishes ${recipe.name} on its border box',
        () async {
          final rendered = await _render(
            owner,
            _subject(
              owner,
              focusColor: recipe.color,
              activeWidth: recipe.activeWidth,
              enabled: recipe.enabled,
            ),
          );
          final box = rendered.box;
          expect(_inline(box)[_variable], recipe.css);
          if (!recipe.enabled) {
            expect(rendered.editor.attributes, contains('disabled'));
            expect(_markers(box), isEmpty);
          } else if (recipe.color.token != null) {
            expect(_markers(box), isEmpty);
            expect(_focusClasses(box), [
              if (owner == _footedArea)
                '[&$_frameFocus]:border-error'
              else
                'focus-within:border-error',
            ]);
          } else {
            _expectNormalReader(owner, box, recipe.css);
          }
          // The Native reference observes the added band independently of
          // the border reader. Raw colour is not a transparency predicate.
          expect(
            _inline(box).containsKey('--coui-active-boundary'),
            recipe.hasAddedBand,
          );
        },
      );
    }

    test('$owner leaves the default focus token path intact', () async {
      final rendered = await _render(owner, _subject(owner));
      expect(_markers(rendered.box), isEmpty);
      expect(_inline(rendered.box), isNot(contains(_variable)));
      expect(_focusClasses(rendered.box), [
        if (owner == _footedArea)
          '[&$_frameFocus]:border-primary'
        else
          'focus-within:border-primary',
      ]);
    });
  }

  for (final owner in [_field, _affixedField]) {
    for (final (name, color, expected) in <(String, CoreColor?, String)>[
      ('raw', _raw, 'rgb(18, 85, 170)'),
      (
        'token',
        const CoreColor.token(CoreColors.error),
        'rgb(var(--coui-error))',
      ),
      ('variant fallback', null, 'rgb(var(--coui-primary))'),
    ]) {
      test(
        '$owner reads $name focus over its own inline rest',
        () async {
          final rendered = await _render(
            owner,
            _subject(owner, restingColor: _rest, focusColor: color),
          );
          expect(_inline(rendered.box)['border-color'], 'rgb(68, 102, 34)');
          expect(_inline(rendered.box)[_variable], expected);
          expect(_markers(rendered.box), [_inlineCompetition]);
          expect(_focusClasses(rendered.box), isEmpty);
          expect(
            _inline(rendered.box),
            isNot(contains('--coui-active-boundary')),
          );
          expect(
            ThemeConfig.defaults().cssVariables.split(_inlineRule),
            hasLength(2),
          );
        },
      );
    }

    test(
      '$owner error text alone does not require an important reader',
      () async {
        final rendered = await _render(
          owner,
          _subject(owner, focusColor: _raw, error: true),
        );
        expect(rendered.root.text, contains('Invalid input'));
        expect(_inline(rendered.box)['border-color'], isNull);
        _expectNormalReader(owner, rendered.box, 'rgb(18, 85, 170)');
      },
    );
  }

  test('disabled inline-rest field has no focused paint marker', () async {
    final rendered = await _render(
      _field,
      _subject(
        _field,
        focusColor: _raw,
        restingColor: _rest,
        enabled: false,
      ),
    );
    expect(rendered.editor.attributes, contains('disabled'));
    expect(_markers(rendered.box), isEmpty);
  });

  for (final owner in [_field, _footedArea]) {
    test(
      '$owner readonly remains eligible for its focus border',
      () async {
        final rendered = await _render(
          owner,
          _subject(owner, focusColor: _raw, readOnly: true),
        );
        expect(rendered.editor.attributes, contains('readonly'));
        expect(rendered.editor.attributes, isNot(contains('disabled')));
        _expectNormalReader(owner, rendered.box, 'rgb(18, 85, 170)');
      },
    );
  }

  for (final footerEditor in [false, true]) {
    test(
      'footer ${footerEditor ? 'textarea' : 'button'} '
      'stays outside the focus owner row',
      () async {
        final rendered = await _render(
          _footedArea,
          _subject(
            _footedArea,
            focusColor: _raw,
            footer: footerEditor
                ? const textarea([], id: 'footer-control')
                : const button([Component.text('Send')], id: 'footer-control'),
          ),
        );
        _expectNormalReader(
          _footedArea,
          rendered.box,
          'rgb(18, 85, 170)',
        );
        expect(rendered.box.children.first, same(rendered.editor.parent));
        expect(
          rendered.editor.parent!.querySelector('#footer-control'),
          isNull,
        );
        expect(rendered.box.querySelector('#footer-control'), isNotNull);
        expect(
          ThemeConfig.defaults().cssVariables,
          contains('.$_frame$_frameFocus{'),
        );
        expect(
          ThemeConfig.defaults().cssVariables,
          isNot(contains('.$_frame:focus-within{')),
        );
      },
    );
  }
}
