import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

const _foreground = CoreColor(0xffd20c22);
const _foregroundCss = 'rgb(210, 12, 34)';
const _description = 'Surface description';
const _title = 'Surface title';
const _colors = <(String, CoreColor, String?, String?)>[
  ('token', CoreColor.token(CoreColors.error), 'text-error', null),
  (
    'token-alpha',
    CoreColor.token(CoreColors.error, opacity: .5),
    'text-error/50',
    null,
  ),
  ('raw', CoreColor(0xff1255aa), null, 'rgb(18, 85, 170)'),
  ('raw-alpha', CoreColor(0x801255aa), null, 'rgba(18, 85, 170, 0.50)'),
  ('transparent', CoreColor.transparent, null, 'rgba(0, 0, 0, 0.00)'),
];

Map<String, String> _inline(dom.Element element) => {
  for (final declaration in (element.attributes['style'] ?? '').split(';'))
    if (declaration.indexOf(':') case final colon when colon >= 0)
      declaration.substring(0, colon).trim(): declaration
          .substring(colon + 1)
          .trim(),
};

// The parent of the public text leaf is the actual typography owner. This
// follows rendered text rather than a resolver's private classes or fields.
dom.Element _slot(dom.Element root, String text) => root
    .querySelectorAll('*')
    .singleWhere((el) => el.children.isEmpty && el.text == text)
    .parent!;

Component _surface(
  String family, {
  CoreColor? descriptionColor,
  CoreColor? titleColor,
  CoreColor? foreground = _foreground,
  Styles? css,
}) => switch (family) {
  'banner' => Banner(
    id: 'subject',
    message: const Text(_title),
    description: const Text(_description),
    action: const Text('Surface action'),
    bannerStyle: CoreBannerStyle(
      foregroundColor: foreground,
      titleStyle: titleColor == null ? null : CoreTextStyle(color: titleColor),
      descriptionStyle: descriptionColor == null
          ? null
          : CoreTextStyle(color: descriptionColor),
    ),
  ),
  'alert' => Alert(
    id: 'subject',
    title: _title,
    description: _description,
    action: const Text('Surface action'),
    css: css,
    alertStyle: CoreAlertStyle(
      foregroundColor: foreground,
      titleStyle: titleColor == null ? null : CoreTextStyle(color: titleColor),
      descriptionStyle: descriptionColor == null
          ? null
          : CoreTextStyle(color: descriptionColor),
    ),
  ),
  _ => Toast(
    id: 'subject',
    message: _title,
    description: _description,
    action: const Text('Surface action'),
    toastStyle: CoreToastStyle(
      messageStyle: titleColor == null
          ? null
          : CoreTextStyle(color: titleColor),
      descriptionStyle: descriptionColor == null
          ? null
          : CoreTextStyle(color: descriptionColor),
    ),
  ),
};

Future<dom.Element> _render(Component subject, String name) async {
  final body = await renderComponentBodyHtml(
    CoUIWeb(theme: .coui, enableThemeAnimation: false, child: subject),
  );
  final output = Platform.environment['SURFACE_COLOR_OUTPUT'];
  if (output != null) {
    final directory = Directory(output)..createSync(recursive: true);
    File('${directory.path}/$name.html').writeAsStringSync(body);
  }
  return html.parse(body).getElementById('subject')!;
}

void _expectExplicitColor(
  dom.Element slot,
  String? expectedClass,
  String? expectedInline,
) {
  if (expectedClass != null) {
    expect(slot.classes, contains(expectedClass));
    // An explicitly authored token cannot compete with a raw fallback at
    // the same text owner. Unrelated typography declarations remain valid.
    expect(_inline(slot)['color'], isNull);
    final colorClasses = slot.classes.where(
      (name) =>
          name.startsWith('text-') &&
          !{'text-body-small', 'text-label-large'}.contains(name),
    );
    // Check public color composition without depending on the fallback's
    // exact variant color or any new private state variable.
    expect(
      colorClasses.where((name) => name.startsWith('text-inverse-')),
      isEmpty,
    );
  } else {
    expect(_inline(slot)['color'], expectedInline);
  }
}

void main() {
  for (final family in ['banner', 'alert', 'toast']) {
    for (final (name, color, colorClass, inlineColor) in _colors) {
      test('$family explicit $name description owns its color', () async {
        final root = await _render(
          _surface(family, descriptionColor: color),
          '$family-$name',
        );
        _expectExplicitColor(
          _slot(root, _description),
          colorClass,
          inlineColor,
        );
        if (family != 'toast') {
          expect(_inline(root)['color'], _foregroundCss);
        }
        expect(root.text, contains('Surface action'));
      });
    }

    test('$family no nested color keeps its foreground', () async {
      final root = await _render(_surface(family), '$family-foreground');
      if (family != 'toast') {
        expect(_inline(root)['color'], _foregroundCss);
        expect(_inline(_slot(root, _description))['color'], _foregroundCss);
      } else {
        expect(_inline(_slot(root, _description))['color'], isNull);
        expect(
          _slot(root, _description).classes,
          contains('text-inverse-on-surface/75'),
        );
      }
    });

    test('$family default text remains available', () async {
      final root = await _render(
        _surface(family, foreground: null),
        '$family-default',
      );
      expect(root.text, contains(_title));
      expect(root.text, contains(_description));
      expect(_inline(_slot(root, _description))['color'], isNull);
    });
  }

  test('alert explicit title token wins over raw foreground', () async {
    final root = await _render(
      _surface('alert', titleColor: const CoreColor.token(CoreColors.error)),
      'alert-title-token',
    );
    _expectExplicitColor(_slot(root, _title), 'text-error', null);
    expect(_inline(root)['color'], _foregroundCss);
  });

  test('alert caller root color remains final', () async {
    final root = await _render(
      _surface(
        'alert',
        descriptionColor: const CoreColor.token(CoreColors.error),
        css: const Styles(raw: {'color': 'rgb(7, 8, 9)'}),
      ),
      'alert-caller',
    );
    expect(_inline(root)['color'], 'rgb(7, 8, 9)');
  });

  test('banner explicit child text style remains final', () async {
    final root = await _render(
      const Banner(
        id: 'subject',
        message: Text(_title),
        description: Text(
          _description,
          style: TextStyle(color: 'error'),
        ),
        bannerStyle: CoreBannerStyle(
          foregroundColor: _foreground,
          descriptionStyle: CoreTextStyle(color: CoreColor(0xff1255aa)),
        ),
      ),
      'banner-child',
    );
    final leaf = root
        .querySelectorAll('*')
        .singleWhere(
          (el) => el.children.isEmpty && el.text == _description,
        );
    expect(leaf.classes, contains('text-error'));
    expect(_inline(leaf)['color'], isNull);
  });
}
