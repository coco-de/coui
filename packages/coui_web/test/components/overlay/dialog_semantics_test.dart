// A dialog names itself.
//
// The panel is `role="dialog"`, and a dialog with no name opens as an unnamed
// region: a screen reader says it is a dialog and nothing about which. The
// name is the title the caller already wrote, pointed at by `aria-labelledby`
// — no new string, so no locale has anything to translate. jaspr_test has no
// browser, so this reads the attributes the browser would be given.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Iterable<DomComponent> _doms() => find
    .byType(DomComponent)
    .evaluate()
    .map((element) => element.component as DomComponent);

Iterable<DomComponent> _panels() =>
    _doms().where((c) => c.attributes?['role'] == 'dialog');

DomComponent _panel() => _panels().single;

void main() {
  group('a dialog names itself', () {
    testComponents('by pointing at its title', (tester) async {
      pumpWithTheme(
        tester,
        const Dialog(
          title: Component.text('Delete item'),
          content: Component.text('This cannot be undone.'),
        ),
      );

      final id = _panel().attributes?['aria-labelledby'];
      expect(id, isNotNull);
      expect(
        find.descendant(
          of: find.byComponentPredicate(
            (c) => c is DomComponent && c.id == id,
          ),
          matching: find.text('Delete item'),
        ),
        findsOneComponent,
        reason: 'the element the panel points at holds the title',
      );
    });

    testComponents('and says it is a modal dialog', (tester) async {
      pumpWithTheme(
        tester,
        const Dialog(
          title: Component.text('Delete item'),
          content: Component.text('This cannot be undone.'),
        ),
      );

      expect(_panel().attributes?['role'], CoreSemanticRole.dialog.name);
      expect(_panel().attributes?['aria-modal'], 'true');
    });

    testComponents('the name is the title and not the body', (tester) async {
      pumpWithTheme(
        tester,
        const Dialog(
          title: Component.text('Delete item'),
          content: Component.text('This cannot be undone.'),
        ),
      );

      final id = _panel().attributes?['aria-labelledby'];
      // The negative control: the body is not inside the element the name
      // comes from.
      expect(
        find.descendant(
          of: find.byComponentPredicate(
            (c) => c is DomComponent && c.id == id,
          ),
          matching: find.text('This cannot be undone.'),
        ),
        findsNothing,
      );
    });

    testComponents('unless the caller has already named it', (tester) async {
      pumpWithTheme(
        tester,
        const Dialog(
          title: Component.text('Delete item'),
          content: Component.text('This cannot be undone.'),
          attributes: {'aria-label': 'Account removal'},
        ),
      );

      final attributes = _panel().attributes ?? const <String, String>{};
      expect(attributes['aria-label'], 'Account removal');
      expect(attributes.containsKey('aria-labelledby'), isFalse);
    });

    testComponents('a dialog with no title is not given a name', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Dialog(content: Component.text('This cannot be undone.')),
      );

      expect(
        (_panel().attributes ?? const <String, String>{}).containsKey(
          'aria-labelledby',
        ),
        isFalse,
      );
    });

    testComponents('two dialogs do not name themselves by one title', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const div([
          Dialog(
            title: Component.text('First'),
            content: Component.text('A'),
          ),
          Dialog(
            title: Component.text('Second'),
            content: Component.text('B'),
          ),
        ]),
      );

      final ids = _panels()
          .map((panel) => panel.attributes?['aria-labelledby'])
          .toList();
      expect(ids, hasLength(2));
      expect(ids.first, isNot(ids.last));
    });
  });

  group('a dialog action with no handler', () {
    // The action keeps its place and tells a screen reader it is not
    // available; the rendered attributes are what is read.
    testComponents('stays in place and is marked disabled', (tester) async {
      pumpWithTheme(
        tester,
        Dialog(
          title: const Component.text('Delete item'),
          content: const Component.text('This cannot be undone.'),
          actions: [Button(child: const Component.text('Delete'))],
        ),
      );

      final action = _doms().singleWhere((c) => c.tag == 'button');
      expect(find.text('Delete'), findsOneComponent);
      expect(action.attributes?['aria-disabled'], 'true');
      expect(action.attributes?.containsKey('disabled'), isTrue);
    });

    testComponents('a live action is not', (tester) async {
      pumpWithTheme(
        tester,
        Dialog(
          title: const Component.text('Delete item'),
          content: const Component.text('This cannot be undone.'),
          actions: [
            Button(onPressed: () {}, child: const Component.text('Delete')),
          ],
        ),
      );

      final action = _doms().singleWhere((c) => c.tag == 'button');
      expect(action.attributes?.containsKey('aria-disabled'), isFalse);
      expect(action.attributes?.containsKey('disabled'), isFalse);
    });
  });
}
