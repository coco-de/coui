import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

const _marker = 'co-text-area-frame-active-boundary';
const _focus = ':has(>:first-child>textarea:focus-visible)';
const _variable = '--coui-active-boundary';
const _rule = '.$_marker$_focus{box-shadow:var($_variable);}';
const _wide = CoreTextAreaStyle(activeBorderWidth: CoreStrokeWidth.stroke1_5);

Map<String, String> _inline(dom.Element element) => {
  for (final declaration in (element.attributes['style'] ?? '').split(';'))
    if (declaration.indexOf(':') case final colon when colon >= 0)
      declaration.substring(0, colon).trim(): declaration
          .substring(colon + 1)
          .trim(),
};

Component _area(String name) => TextArea(
  id: 'subject',
  initialValue: 'Main editing surface',
  rows: 2,
  enabled: name != 'disabled',
  readOnly: name == 'readonly',
  errorText: name == 'error' ? 'Invalid input' : null,
  prefix: name == 'no-footer-affix' ? const Text('Prefix') : null,
  suffix: name == 'no-footer-affix' ? const Text('Suffix') : null,
  footer: name.startsWith('no-footer')
      ? null
      : name == 'footer-textarea'
      ? const textarea([], id: 'footer-editor')
      : name == 'footer-button'
      ? const button([Component.text('Send')], id: 'footer-button')
      : const Text('Footer content'),
  css: name == 'caller-css'
      ? const Styles(raw: {'box-shadow': 'inset 0 0 0 3px rgb(7, 8, 9)'})
      : null,
  textAreaStyle: switch (name) {
    'default' => null,
    'raw-alpha' => const CoreTextAreaStyle(
      activeBorderWidth: CoreStrokeWidth.stroke1_5,
      focusBorderColor: CoreColor(0x801255aa),
    ),
    'equal' => const CoreTextAreaStyle(
      activeBorderWidth: CoreStrokeWidth.stroke1,
    ),
    'smaller' => const CoreTextAreaStyle(
      borderWidth: CoreStrokeWidth.stroke2,
      activeBorderWidth: CoreStrokeWidth.stroke1,
    ),
    'transparent' => const CoreTextAreaStyle(
      activeBorderWidth: CoreStrokeWidth.stroke1_5,
      focusBorderColor: CoreColor.transparent,
    ),
    _ => _wide,
  },
);

void main() {
  const names = [
    'default',
    'wide-token',
    'raw-alpha',
    'disabled',
    'error',
    'readonly',
    'equal',
    'smaller',
    'transparent',
    'no-footer-wide',
    'no-footer-affix',
    'footer-button',
    'footer-textarea',
    'caller-css',
  ];
  for (final name in names) {
    test(
      'public TextArea $name keeps its focused boundary at the actual box',
      () async {
        final body = await renderComponentBodyHtml(
          CoUIWeb(
            theme: .coui,
            enableThemeAnimation: false,
            child: _area(name),
          ),
        );
        final output = Platform.environment['TEXTAREA_PROTOCOL_OUTPUT'];
        if (output != null) {
          Directory(output).createSync(recursive: true);
          File('$output/$name.html').writeAsStringSync(body);
        }
        final document = html.parse(body);
        final editing = document.querySelector('textarea')!;
        final hasFooter = !name.startsWith('no-footer');
        final box = hasFooter ? editing.parent!.parent! : editing.parent!;
        final layer = _inline(box)[_variable];
        final active = !{
          'default',
          'disabled',
          'equal',
          'smaller',
          'transparent',
        }.contains(name);
        expect(editing.text, 'Main editing surface');
        expect(layer != null, active);
        if (name != 'caller-css') expect(_inline(box)['box-shadow'], isNull);
        if (name == 'disabled') {
          expect(editing.attributes, contains('disabled'));
        }
        if (name == 'readonly') {
          expect(editing.attributes, contains('readonly'));
        }
        if (name == 'raw-alpha') {
          expect(layer, contains('rgba(18, 85, 170, 0.50)'));
        }
        if (name == 'error') expect(body, contains('Invalid input'));
        if (name == 'footer-button') {
          expect(box.querySelector('#footer-button'), isNotNull);
          expect(editing.parent!.querySelector('#footer-button'), isNull);
        }
        if (name == 'footer-textarea') {
          expect(box.querySelector('#footer-editor'), isNotNull);
          expect(editing.parent!.querySelector('#footer-editor'), isNull);
        }
        if (name == 'caller-css') {
          expect(body, contains('inset 0 0 0 3px rgb(7, 8, 9)'));
        }
        // Form-only contract: the actual box publishes its existing layer for
        // one fixed paint rule. Raw property Tailwind utilities are forbidden.
        // Browser focus and the caller cascade require a separate live gate.
        expect(box.classes.any((c) => c.contains('[box-shadow:')), isFalse);
        expect(box.classes.contains(_marker), hasFooter && active);
        if (hasFooter && active) {
          expect(box.classes, isNot(contains('coui-active-boundary-within')));
          expect(ThemeConfig.defaults().cssVariables, contains(_rule));
        } else if (!hasFooter && active) {
          expect(box.classes, contains('coui-active-boundary-within'));
        }
      },
    );
  }
}
