import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

const _foreground = CoreColor(0xff1255aa);
const _foregroundCSS = 'rgb(18, 85, 170)';
const _labelCases = <(String, CoreColor, String?, String?)>[
  ('token', CoreColor.token(CoreColors.primary), 'text-primary', null),
  (
    'token alpha',
    CoreColor.token(CoreColors.primary, opacity: .5),
    'text-primary/50',
    null,
  ),
  ('raw', CoreColor(0xff774411), null, 'rgb(119, 68, 17)'),
  ('raw alpha', CoreColor(0x80774411), null, 'rgba(119, 68, 17, 0.50)'),
  ('transparent', CoreColor.transparent, null, 'rgba(0, 0, 0, 0.00)'),
];

Map<String, String> _inline(dom.Element element) => {
  for (final declaration in (element.attributes['style'] ?? '').split(';'))
    if (declaration.indexOf(':') case final colon when colon >= 0)
      declaration.substring(0, colon).trim(): declaration
          .substring(colon + 1)
          .trim(),
};

DisclosureBadge _badge({
  CoreColor? labelColor,
  CoreColor? foreground = _foreground,
  Styles? css,
}) => DisclosureBadge(
  id: 'subject',
  css: css,
  kind: .commitment,
  label: 'Label',
  disclosureBadgeStyle: CoreDisclosureBadgeStyle(
    foregroundColor: foreground,
    labelStyle: labelColor == null ? null : CoreTextStyle(color: labelColor),
  ),
);

Future<dom.Element> _render(Component subject, String name) async {
  final body = await renderComponentBodyHtml(
    CoUIWeb(theme: .coui, enableThemeAnimation: false, child: subject),
  );
  final output = Platform.environment['COMPACT_COLOR_OUTPUT'];
  if (output != null) {
    final directory = Directory(output)..createSync(recursive: true);
    File(
      '${directory.path}/${name.replaceAll(' ', '-')}.html',
    ).writeAsStringSync(body);
  }
  return html.parse(body).getElementById('subject')!;
}

void main() {
  for (final (name, color, expectedClass, expectedInline) in _labelCases) {
    test('explicit $name label wins over raw foreground', () async {
      final root = await _render(_badge(labelColor: color), name);
      expect(root.text, contains('Label'));
      if (expectedClass != null) {
        expect(root.classes, contains(expectedClass));
        // A raw foreground must not mask the expressly authored label
        // token at the real text owner. The marker keeps its own color.
        expect(_inline(root)['color'], isNull);
      } else {
        expect(_inline(root)['color'], expectedInline);
      }
      final marker = root.querySelector('[aria-hidden="true"]')!;
      expect(_inline(marker)['background-color'], _foregroundCSS);
    });
  }

  test('foreground remains when label color is absent', () async {
    final root = await _render(_badge(), 'foreground');
    expect(_inline(root)['color'], _foregroundCSS);
  });

  test('caller CSS remains final', () async {
    final root = await _render(
      _badge(
        labelColor: const CoreColor.token(CoreColors.primary),
        css: const Styles(raw: {'color': 'rgb(7, 8, 9)'}),
      ),
      'caller',
    );
    expect(_inline(root)['color'], 'rgb(7, 8, 9)');
  });

  test('no-override default remains available', () async {
    final root = await _render(_badge(foreground: null), 'default');
    expect(root.text, contains('Label'));
    expect(_inline(root)['color'], isNull);
  });
}
