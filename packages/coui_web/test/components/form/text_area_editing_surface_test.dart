import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The rendered `<textarea>`, which is where the editing surface lives.
DomComponent _textarea(ComponentTester tester) =>
    find.tag('textarea').evaluate().single.component as DomComponent;

void main() {
  // A declared parameter that nothing wires is worse than an absent one:
  // the API promises a callback the element never fires. These assert the
  // wiring, which is the half a resolver test cannot see.
  group('TextArea editing callbacks reach the element', () {
    // The handlers are asserted by presence rather than by firing: a
    // `jaspr` event callback takes a real DOM `Event`, and this harness
    // renders without a DOM to build one from.
    testComponents('onTap listens on click', (tester) async {
      pumpWithTheme(tester, TextArea(onTap: () {}));

      expect(_textarea(tester).events?.containsKey('click'), isTrue);
    });

    testComponents('onEditingComplete listens on change', (tester) async {
      // `change` is the commit event for a `<textarea>`: Enter inserts a
      // newline here, so there is no key to key on.
      pumpWithTheme(tester, TextArea(onEditingComplete: () {}));

      expect(_textarea(tester).events?.containsKey('change'), isTrue);
    });

    testComponents('inputFormatters listen on input even without onChanged', (
      tester,
    ) async {
      // The formatter has to run on every edit whether or not the caller
      // also asked to be told about it.
      pumpWithTheme(
        tester,
        TextArea(inputFormatters: [CoreInputFormatters.toUpperCase()]),
      );

      expect(_textarea(tester).events?.containsKey('input'), isTrue);
    });

    testComponents('and a plain area wires none of them', (tester) async {
      // Only `focus` / `blur` (the focus-ring model) are unconditional.
      pumpWithTheme(tester, TextArea());
      final events = _textarea(tester).events ?? const {};

      expect(events.containsKey('click'), isFalse);
      expect(events.containsKey('change'), isFalse);
      expect(events.containsKey('input'), isFalse);
    });
  });

  // `onHeightChanged` / `onWidthChanged` fire from a `ResizeObserver`, which
  // needs a real DOM this harness does not have. What *is* observable without
  // one is the half that has to hold first: the observer can only ever attach
  // to an element it can find, so the `<textarea>` has to carry an id exactly
  // when a resize callback is wired. This group is the only assertion on
  // those two callbacks.
  group('TextArea resize callbacks make the element addressable', () {
    testComponents('an area with no callback carries no id', (tester) async {
      // The baseline the rest of the group differs from: nothing looks the
      // element up, so nothing names it.
      pumpWithTheme(tester, const TextArea());
      await tester.pump();

      expect(_textarea(tester).id, isNull);
    });

    testComponents('an expandable height with a callback gets an id', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TextArea(expandableHeight: true, onHeightChanged: (_) {}),
      );
      await tester.pump();

      expect(_textarea(tester).id, isNotNull);
    });

    testComponents('an expandable width with a callback gets an id', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TextArea(expandableWidth: true, onWidthChanged: (_) {}),
      );
      await tester.pump();

      expect(_textarea(tester).id, isNotNull);
    });

    testComponents('a callback without the matching axis stays unobserved', (
      tester,
    ) async {
      // The gate is the pair, not the callback: a height callback on a
      // non-expandable area can never fire, so nothing is attached and the
      // element keeps the markup an area without the callback has — no id.
      pumpWithTheme(tester, TextArea(onHeightChanged: (_) {}));
      await tester.pump();

      expect(_textarea(tester).id, isNull);
    });

    testComponents('a callback for the other axis stays unobserved', (
      tester,
    ) async {
      // A width callback on a height-only area is not the pair either.
      pumpWithTheme(
        tester,
        TextArea(expandableHeight: true, onWidthChanged: (_) {}),
      );
      await tester.pump();

      expect(_textarea(tester).id, isNull);
    });

    testComponents('an expandable axis without a callback stays unobserved', (
      tester,
    ) async {
      pumpWithTheme(tester, const TextArea(expandableHeight: true));
      await tester.pump();

      expect(_textarea(tester).id, isNull);
    });
  });

  group('TextArea outside-pointer containment', () {
    testComponents('onTapOutside forces a root id to test containment', (
      tester,
    ) async {
      // The listener skips events inside this id. Without it every pointer
      // down would read as outside, including one on the field itself.
      pumpWithTheme(tester, TextArea(onTapOutside: () {}));
      final root = find.tag('div').evaluate().first.component as DomComponent;

      expect(root.id, isNotNull);
    });

    testComponents('a caller id still wins', (tester) async {
      pumpWithTheme(tester, TextArea(id: 'notes', onTapOutside: () {}));
      final root = find.tag('div').evaluate().first.component as DomComponent;

      expect(root.id, equals('notes'));
    });

    testComponents('and a plain area stays id-less', (tester) async {
      pumpWithTheme(tester, TextArea());
      final root = find.tag('div').evaluate().first.component as DomComponent;

      expect(root.id, isNull);
    });
  });
}
