// The Web half of the FadeScroll selection decision: the fade is a CSS
// `mask-image` on the scroll viewport, and nothing on the way down to the
// text suppresses selection. The browser then masks `::selection` together
// with the glyphs — the same ramp the Flutter `ShaderMask` gives its
// highlight, which `fade_scroll_selection_test.dart` in coui_flutter pins.
// Turning selection off here would leave Flutter selectable and Web not.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

Iterable<DomComponent> _dom(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

Map<String, String> _inline(DomComponent c) => c.styles?.properties ?? const {};

bool _suppressesSelection(DomComponent c) {
  final inline = _inline(c);

  return inline['user-select'] == 'none' ||
      inline['-webkit-user-select'] == 'none' ||
      (c.classes ?? '').split(' ').contains('select-none');
}

void main() {
  group('FadeScroll selection', () {
    testComponents('the fade is a mask on the viewport, not a barrier', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FadeScroll(
          child: div([
            Text('first row'),
            Text('second row'),
          ]),
        ),
      );

      final masked = _dom(
        tester,
      ).where((c) => _inline(c).containsKey('mask-image'));
      expect(masked, hasLength(1));

      expect(_dom(tester).where(_suppressesSelection), isEmpty);
      expect(find.text('first row'), findsOneComponent);
    });
  });
}
