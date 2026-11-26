import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/web/ssr_render.dart';

Map<String, String> _inline(dom.Element root) => {
  for (final d in (root.attributes['style'] ?? '').split(';'))
    if (d.indexOf(':') case final i when i >= 0)
      d.substring(0, i).trim(): d.substring(i + 1).trim(),
};
Future<dom.Document> _render(Component child) async {
  final body = await renderComponentBodyHtml(
    CoUIWeb(theme: .coui, enableThemeAnimation: false, child: child),
  );
  return html.parse(body);
}

CoreCheckboxStyle _style(String field, double alpha) {
  final color = CoreColor.token(CoreColors.primary, opacity: alpha);
  return switch (field) {
    'halo' => CoreCheckboxStyle(stateLayerColor: color),
    'ring' => CoreCheckboxStyle(
      focusOutlineStyle: CoreFocusOutlineStyle(borderColor: color),
    ),
    'band' => CoreCheckboxStyle(
      focusOutlineStyle: CoreFocusOutlineStyle(offsetColor: color),
    ),
    _ => throw StateError(field),
  };
}

String _scope(dom.Element root) =>
    root.classes.singleWhere((value) => value.startsWith('co-checkbox-sl-'));
String _css(dom.Element root) =>
    root.querySelectorAll('style').map((e) => e.text).join('\n');
void _chipCloseCase(
  String name,
  CoreColor? foreground, {
  String? expectedClass,
  String? expectedInline,
  CoreColor? nestedOverride,
}) {
  test('Chip close-button $name foreground fallback', () async {
    final document = await _render(
      Chip(
        id: 'chip-close',
        label: 'remove',
        onRemove: () {},
        chipStyle: foreground == null && nestedOverride == null
            ? null
            : CoreChipStyle(
                foregroundColor: foreground,
                closeButtonStyle: nestedOverride == null
                    ? null
                    : CoreButtonStyle(foregroundColor: nestedOverride),
              ),
      ),
    );
    final button = document
        .getElementById('chip-close')!
        .querySelector('button');
    expect(
      button,
      isNotNull,
      reason: 'The public onRemove callback renders the actual close Button.',
    );
    final inline = _inline(button!);
    if (expectedClass != null) expect(button.classes, contains(expectedClass));
    if (expectedInline != null) expect(inline['color'], expectedInline);
    expect(button.querySelector('svg'), isNotNull);
  });
}

void main() {
  for (final field in ['halo', 'ring', 'band']) {
    test(
      'different Checkbox $field opacity keeps distinct paint ownership',
      () async {
        final document = await _render(
          Component.fragment([
            Checkbox(
              id: 'first',
              enabled: true,
              checkboxStyle: _style(field, .2),
            ),
            Checkbox(
              id: 'second',
              enabled: true,
              checkboxStyle: _style(field, .8),
            ),
          ]),
        );
        final a = document.getElementById('first')!;
        final b = document.getElementById('second')!;
        final scopeA = _scope(a);
        final scopeB = _scope(b);
        final cssA = _css(a);
        final cssB = _css(b);
        expect(
          cssA.replaceAll(scopeA, 'OWNER'),
          isNot(cssB.replaceAll(scopeB, 'OWNER')),
          reason:
              'Different authored opacities really emit different '
              'paint declarations.',
        );
        expect(
          scopeA,
          isNot(scopeB),
          reason:
              'Different paint must not select both owners '
              'with one shared class.',
        );
      },
    );
  }
  test('identical Checkbox paint may share its existing scope', () async {
    final document = await _render(
      const Component.fragment([
        Checkbox(id: 'first', enabled: true),
        Checkbox(id: 'second', enabled: true),
      ]),
    );
    final a = document.getElementById('first')!;
    final b = document.getElementById('second')!;
    expect(_scope(a), _scope(b));
    expect(_css(a), _css(b));
  });
  test('Checkbox raw fill and border already forward correctly', () async {
    final document = await _render(
      const Checkbox(
        id: 'control',
        enabled: true,
        checkboxStyle: CoreCheckboxStyle(
          boxBackgroundColor: CoreColor(0xff1255aa),
          boxBorderColor: CoreColor(0xff1255aa),
        ),
      ),
    );
    final box = document
        .getElementById('control')!
        .querySelector('.co-checkbox-box')!;
    final inline = _inline(box);
    expect(inline['background-color'], 'rgb(18, 85, 170)');
    expect(inline['border-color'], 'rgb(18, 85, 170)');
  });
  test('Chip raw fill already forwards correctly', () async {
    final document = await _render(
      Chip(
        id: 'control',
        label: 'chip',
        chipStyle: const CoreChipStyle(backgroundColor: CoreColor(0xff1255aa)),
      ),
    );
    final root = document.getElementById('control')!;
    final box = root.classes.contains('co-chip-body')
        ? root
        : root.querySelector('.co-chip-body')!;
    final inline = _inline(box);
    expect(inline['background-color'], contains('rgb(18, 85, 170)'));
  });
  test('Toggle raw off-track fill already forwards correctly', () async {
    final document = await _render(
      const Toggle(
        id: 'control',
        enabled: true,
        toggleStyle: CoreToggleStyle(trackInactiveColor: CoreColor(0xff1255aa)),
      ),
    );
    final box = document
        .getElementById('control')!
        .querySelector('.co-toggle-track')!;
    final inline = _inline(box);
    expect(inline['background-color'], contains('rgb(18, 85, 170)'));
  });
  _chipCloseCase(
    'token',
    const CoreColor.token(CoreColors.primary),
    expectedClass: 'text-primary',
  );
  _chipCloseCase(
    'token-alpha',
    const CoreColor.token(CoreColors.primary, opacity: .5),
    expectedClass: 'text-primary/50',
  );
  _chipCloseCase(
    'raw-opaque',
    const CoreColor(0xff1255aa),
    expectedInline: 'rgb(18, 85, 170)',
  );
  _chipCloseCase(
    'raw-alpha',
    const CoreColor(0x801255aa),
    expectedInline: 'rgba(18, 85, 170, 0.50)',
  );
  _chipCloseCase(
    'explicit-nested-wins',
    const CoreColor(0xff1255aa),
    nestedOverride: const CoreColor(0xff070809),
    expectedInline: 'rgb(7, 8, 9)',
  );
  _chipCloseCase('default-no-override', null);
}
