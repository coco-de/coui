import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

const foreground = CoreColor(0xff1255aa);
const labelCases = <(String, CoreColor, String?, String?)>[
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
Map<String, String> inline(dom.Element root) => {
  for (final value in (root.attributes['style'] ?? '').split(';'))
    if (value.indexOf(':') case final colon when colon >= 0)
      value.substring(0, colon).trim(): value.substring(colon + 1).trim(),
};
Future<dom.Element> render({
  CoreColor? label,
  CoreColor? ink = foreground,
  Styles? css,
}) async {
  final body = await renderComponentBodyHtml(
    CoUIWeb(
      theme: .coui,
      enableThemeAnimation: false,
      child: Tag(
        id: 'tag',
        css: css,
        tagStyle: CoreTagStyle(
          foregroundColor: ink,
          labelStyle: label == null ? null : CoreTextStyle(color: label),
        ),
        child: const Component.fragment([
          Text('Label'),
          Icon(LucideIcons.heart, id: 'icon'),
        ]),
      ),
    ),
  );
  return html.parse(body).getElementById('tag')!;
}

void main() {
  for (final (name, color, expectedClass, expectedInline) in labelCases) {
    test(
      'Tag explicit $name label owns color without a competing raw foreground',
      () async {
        final root = await render(label: color);
        expect(root.text, contains('Label'));
        expect(root.children.length, 2);
        expect(root.querySelector('#icon'), isNotNull);
        if (expectedClass != null) {
          expect(root.classes, contains(expectedClass));
          expect(inline(root)['color'], isNull);
        } else {
          expect(inline(root)['color'], expectedInline);
        }
        // An unspecified Web Icon keeps its existing currentColor path.
        expect(inline(root.querySelector('#icon')!)['color'], isNull);
      },
    );
  }
  test(
    'Tag foreground remains the fallback without explicit label color',
    () async {
      final root = await render();
      expect(inline(root)['color'], 'rgb(18, 85, 170)');
    },
  );
  test('Tag caller root CSS remains final', () async {
    final root = await render(
      label: const CoreColor.token(CoreColors.primary),
      css: const Styles(raw: {'color': 'rgb(7, 8, 9)'}),
    );
    expect(inline(root)['color'], 'rgb(7, 8, 9)');
  });
  test('Tag no-override default remains available', () async {
    final root = await render(ink: null);
    expect(root.text, contains('Label'));
    expect(inline(root)['color'], isNull);
  });
}
