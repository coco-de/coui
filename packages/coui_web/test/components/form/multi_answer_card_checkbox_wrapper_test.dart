// The checkbox inside a `MultiAnswerCard` is decoration — the card's own
// click owns the press — so it is wrapped to be taken out of pointer events
// and the accessibility tree.
//
// That wrapper must be a flex container. A plain block holding the
// inline-level checkbox keeps a line box whose strut is the card's text line
// height (22.5px here), which made the 18px box 24px tall and the card taller
// than the Flutter twin's by about a pixel and a half per card.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('the MultiAnswerCard checkbox wrapper', () {
    testComponents('is a flex container that ignores the pointer', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const MultiAnswerCard(
          value: 'a',
          selected: true,
          child: Text('Option'),
        ),
      );

      final wrappers = find
          .tag('div')
          .evaluate()
          .map((e) => e.component)
          .whereType<DomComponent>()
          .where((d) => d.attributes?['aria-hidden'] == 'true');
      final classes = wrappers.single.classes!.split(' ');

      expect(classes, containsAll(['flex', 'pointer-events-none']));
    });
  });
}
