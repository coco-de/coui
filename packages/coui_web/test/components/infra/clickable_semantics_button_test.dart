// A screen reader announces the role, and nothing in a widget test looks
// wrong when the role is missing — the element renders, the click works.
// So the only way `semanticsButton` can be shown to reach the page is to
// read the attribute back off the rendered element.
library;

import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The value of [attribute] on the first rendered element carrying it.
String? _renderedAttribute(String attribute) {
  final finder = find.byComponentPredicate(
    (component) => component is DomComponent && component.attributes != null,
  );

  for (final element in finder.evaluate()) {
    final value = (element.component as DomComponent).attributes?[attribute];
    if (value != null) return value;
  }

  return null;
}

void main() {
  group('semanticsButton decides whether the button role is announced', () {
    testComponents('the default announces a button', (tester) async {
      // Most things built on Clickable are buttons, and a control a reader
      // cannot identify is unreachable rather than merely unlabelled.
      pumpWithTheme(tester, Clickable(child: Component.text('x')));
      await tester.pump();

      expect(_renderedAttribute('role'), equals('button'));
    });

    testComponents('turning it off drops the role', (tester) async {
      // The off switch a composing control uses when it is something more
      // specific — a checkbox announcing "button" is worse than the
      // generic role being absent.
      pumpWithTheme(
        tester,
        Clickable(semanticsButton: false, child: Component.text('x')),
      );
      await tester.pump();

      expect(_renderedAttribute('role'), isNull);
    });

    testComponents('turning it off keeps the element focusable', (
      tester,
    ) async {
      // Focusability and role are separate: a checkbox stops calling
      // itself a button but is still reached by Tab. Dropping tabindex
      // alongside the role would make every composed control unreachable
      // by keyboard, which no test asserting only the role would catch.
      pumpWithTheme(
        tester,
        Clickable(semanticsButton: false, child: Component.text('x')),
      );
      await tester.pump();

      expect(_renderedAttribute('tabindex'), equals('0'));
    });
  });
}
