// `Card(child: …)` is the Web mirror of Flutter's card with a child straight
// inside the container. The child wrapper used to be a plain block, so an
// inline-level child (the `Text` chain is an inline `span`) opened a line box
// whose strut was the *inherited* body line height: a 13px / 19.5px caption
// came out 21px tall and every card with one grew by the difference.
//
// A single child gets a flex column (the child keeps its own line height, a
// block child still fills the width). Several children — a Web-only API —
// keep the plain block, so inline siblings still flow on one line.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

List<String> _wrapperClasses() {
  final wrappers = find
      .byType(DomComponent)
      .evaluate()
      .map((e) => e.component as DomComponent)
      .where((c) => (c.classes ?? '').split(' ').contains('h-full'))
      // The wrapper is the one directly under the card root.
      .toList();
  return wrappers.first.classes!.split(' ');
}

void main() {
  group('the Card custom-child wrapper', () {
    testComponents('a single child sits in a flex column', (tester) async {
      pumpWithTheme(tester, const Card(child: Component.text('Only')));

      expect(
        _wrapperClasses(),
        containsAll(['flex', 'flex-col', 'items-stretch', 'h-full']),
      );
    });

    testComponents('several children keep the plain block', (tester) async {
      pumpWithTheme(
        tester,
        const Card(
          children: [Component.text('First'), Component.text('Second')],
        ),
      );

      final classes = _wrapperClasses();

      expect(classes, contains('h-full'));
      expect(classes, isNot(contains('flex')));
    });
  });
}
