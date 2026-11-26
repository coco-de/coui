import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';
import '../../src/web/ssr_render.dart';

const _rest = CoreColor(0xff446622);
const _hover = CoreColor(0xff884422);
const _fill = CoreColor(0xff102030);
final _recipes =
    <
      ({
        String name,
        CoreTextAreaStyle style,
        bool enabled,
        CoreColor rest,
        CoreColor fill,
        CoreColor? hover,
      })
    >[
      (
        name: 'default',
        style: const CoreTextAreaStyle(),
        enabled: true,
        rest: CoreTextAreaStyle.defaultNormalVariant.borderColor,
        fill: CoreTextAreaStyle.defaultNormalVariant.backgroundColor,
        hover: null,
      ),
      (
        name: 'raw-rest',
        style: const CoreTextAreaStyle(borderColor: _rest),
        enabled: true,
        rest: _rest,
        fill: CoreTextAreaStyle.defaultNormalVariant.backgroundColor,
        hover: null,
      ),
      (
        name: 'alpha-rest',
        style: const CoreTextAreaStyle(borderColor: CoreColor(0x80446622)),
        enabled: true,
        rest: const CoreColor(0x80446622),
        fill: CoreTextAreaStyle.defaultNormalVariant.backgroundColor,
        hover: null,
      ),
      (
        name: 'transparent-rest',
        style: const CoreTextAreaStyle(borderColor: CoreColor.transparent),
        enabled: true,
        rest: CoreColor.transparent,
        fill: CoreTextAreaStyle.defaultNormalVariant.backgroundColor,
        hover: null,
      ),
      (
        name: 'raw-hover',
        style: const CoreTextAreaStyle(
          borderColor: CoreColor.token(CoreColors.error),
          hoverBorderColor: _hover,
        ),
        enabled: true,
        rest: const CoreColor.token(CoreColors.error),
        fill: CoreTextAreaStyle.defaultNormalVariant.backgroundColor,
        hover: _hover,
      ),
      (
        name: 'disabled-default',
        style: const CoreTextAreaStyle(),
        enabled: false,
        rest: CoreTextAreaStyle.defaultNormalVariant.disabledBorderColor,
        fill: CoreTextAreaStyle.defaultNormalVariant.disabledBackgroundColor,
        hover: null,
      ),
      (
        name: 'disabled-raw',
        style: const CoreTextAreaStyle(
          borderColor: _rest,
          backgroundColor: _fill,
        ),
        enabled: false,
        rest: _rest,
        fill: _fill,
        hover: null,
      ),
      (
        name: 'transparent-hover',
        style: const CoreTextAreaStyle(
          borderColor: CoreColor.token(CoreColors.error),
          hoverBorderColor: CoreColor.transparent,
        ),
        enabled: true,
        rest: const CoreColor.token(CoreColors.error),
        fill: CoreTextAreaStyle.defaultNormalVariant.backgroundColor,
        hover: CoreColor.transparent,
      ),
      (
        name: 'disabled-token-idle',
        style: const CoreTextAreaStyle(
          borderColor: CoreColor.token(CoreColors.error),
        ),
        enabled: false,
        rest: const CoreColor.token(CoreColors.error),
        fill: CoreTextAreaStyle.defaultNormalVariant.disabledBackgroundColor,
        hover: CoreTextAreaStyle.defaultNormalVariant.disabledBorderColor,
      ),
    ];
Map<String, String> _styles(dom.Element e) => {
  for (final item in (e.attributes['style'] ?? '').split(';'))
    if (item.contains(':'))
      item.substring(0, item.indexOf(':')).trim(): item
          .substring(item.indexOf(':') + 1)
          .trim(),
};
dom.Element _box(dom.Element root) {
  final editor = root.querySelector('textarea')!;
  for (var p = editor.parent; p != null && p != root.parent; p = p.parent) {
    final style = _styles(p);
    if (style.containsKey('border-width') && style['border-style'] == 'solid') {
      return p;
    }
  }
  throw StateError('No structurally border-bearing editor ancestor');
}

bool _delivered(
  dom.Element box,
  CoreColor color,
  String css, {
  bool hovered = false,
}) {
  final styles = _styles(box);
  if (!hovered && styles['border-color'] == color.toValue()) return true;
  if (color.token != null &&
      box.classes.contains(
        '${hovered ? 'hover:' : ''}border-${color.tailwindColor}',
      )) {
    return true;
  }
  for (final entry in styles.entries) {
    if (!entry.key.startsWith('--') || entry.value != color.toValue()) continue;
    final rules = RegExp(r'([^{}]+)\{([^{}]+)\}').allMatches(css);
    for (final rule in rules) {
      final selector = rule.group(1)!;
      final declaration = rule.group(2)!;
      if (!declaration.contains('border-color:var(${entry.key})')) continue;
      if (!box.classes.any((c) => selector.contains('.$c'))) continue;
      if (hovered &&
          (!selector.contains(':hover') || selector.contains(':not(:hover)'))) {
        continue;
      }
      if (!hovered &&
          selector.contains(':hover') &&
          !selector.contains(':not(:hover)')) {
        continue;
      }
      return true;
    }
  }
  return false;
}

void main() {
  for (final footer in [false, true]) {
    for (final recipe in _recipes) {
      test(
        '${footer ? 'footer' : 'no-footer'} ${recipe.name} '
        'public box colour delivery',
        () async {
          final body = await renderComponentBodyHtml(
            CoUIWeb(
              theme: .coui,
              child: div(styles: const Styles(raw: {'width': '320px'}), [
                TextArea(
                  id: 'subject',
                  initialValue: 'hello',
                  enabled: recipe.enabled,
                  textAreaStyle: recipe.style,
                  footer: footer
                      ? Button(onPressed: () {}, child: const Text('Footer'))
                      : null,
                ),
              ]),
            ),
          );
          final root = html.parseFragment(body).querySelector('#subject')!;
          final box = _box(root);
          final styles = _styles(box);
          final css = ThemeConfig.defaults().cssVariables;
          expect(
            _delivered(box, recipe.rest, css),
            isTrue,
            reason:
                'Rest border must reach the actual box, '
                'not an invalid border-#hex utility.',
          );
          expect(
            styles['background-color'],
            recipe.fill.toValue(),
            reason:
                'The whole disabled box uses its dedicated fill '
                'unless caller overrides it.',
          );
          if (recipe.hover != null) {
            expect(
              _delivered(box, recipe.hover!, css, hovered: true),
              isTrue,
              reason:
                  'Existing public hover colour must reach '
                  'its actual box state rule.',
            );
          }
        },
      );
    }
  }
  for (final footer in [false, true]) {
    test('fractional token rest class remains51 footer=$footer', () async {
      final body = await renderComponentBodyHtml(
        CoUIWeb(
          theme: .coui,
          child: TextArea(
            id: 'subject',
            initialValue: 'hello',
            textAreaStyle: const CoreTextAreaStyle(
              borderColor: CoreColor.token(CoreColors.error, opacity: 0.505),
            ),
            footer: footer ? const Text('Footer') : null,
          ),
        ),
      );
      final root = html.parseFragment(body).querySelector('#subject')!;
      expect(_box(root).classes, contains('border-error/51'));
      expect(
        root.querySelector('textarea')!.classes,
        contains('border-error/51'),
      );
      expect(_box(root).classes, isNot(contains('border-error/50')));
    });
    test('mixed fractional token rest and raw hover footer=$footer', () async {
      final body = await renderComponentBodyHtml(
        CoUIWeb(
          theme: .coui,
          child: TextArea(
            id: 'subject',
            initialValue: 'hello',
            textAreaStyle: const CoreTextAreaStyle(
              borderColor: CoreColor.token(CoreColors.error, opacity: 0.505),
              hoverBorderColor: CoreColor(0xff884422),
            ),
            footer: footer ? const Text('Footer') : null,
          ),
        ),
      );
      final root = html.parseFragment(body).querySelector('#subject')!;
      final owner = _box(root);
      expect(owner.classes, contains('border-error/51'));
      expect(owner.classes, isNot(contains('border-error/50')));
      expect(
        root.querySelector('textarea')!.classes,
        contains('border-error/51'),
      );
    });
  }
}
