/// A glyph with more than one stroke (`house` is two paths) takes ONE colour
/// from the button, on every stroke.
///
/// The button gives its glyph a colour through the cascade (`color` on the
/// icon's `<svg>`, strokes spelled `currentColor`), so every mark reads the
/// same value. The only way to leave one mark behind is a stroke that states
/// a colour of its own — these tests read the rendered markup for exactly that.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

DomComponent _glyph() =>
    find.tag('svg').evaluate().single.component as DomComponent;

String _body() =>
    (find.byType(RawText).evaluate().single.component as RawText).text;

void main() {
  for (final enabled in [true, false]) {
    testComponents(
      'the ${enabled ? 'enabled' : 'disabled'} button paints every stroke',
      (tester) async {
        pumpWithTheme(
          tester,
          Button(
            enabled: enabled,
            leading: const Icon(LucideIcons.house),
            child: const Text('Add'),
          ),
        );

        final body = _body();

        // The glyph really has more than one stroke.
        expect(RegExp('<path').allMatches(body).length, greaterThan(1));
        // None of them states a colour of its own — the one the svg element
        // carries reaches all of them through `currentColor`.
        expect(
          RegExp('stroke="(?!currentColor|none)').hasMatch(body),
          isFalse,
        );
        expect(RegExp('(?:stroke|fill)="#').hasMatch(body), isFalse);
        expect(_glyph().tag, 'svg');
      },
    );
  }
}
