// A screen reader hears the attributes on the rendered element and nothing
// else — the component can draw correctly and still say nothing. So each
// case below reads the attribute back off the DOM the component emitted:
// an error that appeared after submit, a row that is the chosen one, a
// popup that says which surface it opened.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/control/command/command.dart';
import 'package:coui_web/src/components/form/form_field/form_field.dart';
import 'package:coui_web/src/components/form/item_picker/item_picker.dart';
import 'package:coui_web/src/components/form/validator_hint/validator_hint.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The attribute maps of every rendered element.
Iterable<Map<String, String>> _attributes() => find
    .byComponentPredicate(
      (component) => component is DomComponent && component.attributes != null,
    )
    .evaluate()
    .map((e) => (e.component as DomComponent).attributes!);

/// The attributes of the element carrying [id].
Map<String, String>? _byId(String id) {
  for (final element
      in find
          .byComponentPredicate(
            (component) => component is DomComponent && component.id == id,
          )
          .evaluate()) {
    return (element.component as DomComponent).attributes ?? const {};
  }
  return null;
}

void main() {
  group('a validation message announces itself when it appears', () {
    testComponents('each reported tone takes a live role, neutral none', (
      tester,
    ) async {
      // Tone decides urgency, as it does for Alert: an error interrupts,
      // the other reported tones wait their turn, and a rule that is
      // merely pending is page content, not news.
      const expected = {
        CoreValidatorHintType.error: 'alert',
        CoreValidatorHintType.warning: 'status',
        CoreValidatorHintType.info: 'status',
        CoreValidatorHintType.success: 'status',
        CoreValidatorHintType.neutral: null,
      };
      for (final MapEntry(key: type, value: role) in expected.entries) {
        pumpWithTheme(
          tester,
          ValidatorHint(
            type: type,
            id: 'hint',
            message: const Component.text('hint'),
          ),
        );
        await tester.pump();

        expect(_byId('hint')?['role'], role, reason: '$type');
      }
    });

    testComponents('a caller role still wins', (tester) async {
      // Passthrough: the component states a default, the caller has the
      // last word.
      pumpWithTheme(
        tester,
        const ValidatorHint.error(
          id: 'hint',
          attributes: {'role': 'note'},
          message: Component.text('hint'),
        ),
      );
      await tester.pump();

      expect(_byId('hint')?['role'], 'note');
    });

    testComponents('a FormField error is an alert', (tester) async {
      // The error was linked to the field by `aria-describedby` and that
      // is all — a link is read when the field is reached, not when the
      // message appears. Submit left focus where it was, so nothing read
      // it.
      pumpWithTheme(
        tester,
        const FormField(
          label: 'Email',
          error: 'Enter a valid email',
          child: Component.text('input'),
        ),
      );
      await tester.pump();

      expect(_attributes().where((a) => a['role'] == 'alert'), hasLength(1));
    });
  });

  group('the chosen row says it is chosen', () {
    testComponents('Clickable states selection only when told', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Clickable(
          id: 'row',
          semanticsSelected: true,
          child: Component.text('x'),
        ),
      );
      await tester.pump();
      expect(_byId('row')?['aria-selected'], 'true');

      // Null is not false — a plain button has no selection at all.
      pumpWithTheme(
        tester,
        const Clickable(id: 'row', child: Component.text('x')),
      );
      await tester.pump();
      expect(_byId('row')?.containsKey('aria-selected'), isFalse);
    });

    testComponents('ItemPicker rows carry their state', (tester) async {
      pumpWithTheme(
        tester,
        ItemPicker(
          items: const ['Apple', 'Banana'],
          selectedValue: 'Banana',
          onChanged: (_) {},
        ),
      );
      await tester.pump();

      final options = _attributes()
          .where((a) => a['role'] == 'option')
          .map((a) => a['aria-selected'])
          .toList();
      expect(options, ['false', 'true']);
    });

    testComponents('Command states its cursor row as the selected one', (
      tester,
    ) async {
      // A palette has no value; the row in play is the one Enter would run,
      // and `aria-activedescendant` on the input points at it. The row says
      // the same thing itself — the Flutter twin carries the cursor on the
      // row's `selected` flag through the same Clickable parameter.
      pumpWithTheme(
        tester,
        Command(
          onSelect: (_) {},
          groups: const [
            CoreCommandGroup(
              items: [
                CoreCommandItem(value: 'calendar', label: 'Calendar'),
                CoreCommandItem(value: 'search', label: 'Search'),
              ],
            ),
          ],
        ),
      );
      await tester.pump();

      final options = _attributes()
          .where((a) => a['role'] == 'option')
          .map((a) => a['aria-selected'])
          .toList();
      expect(options, ['true', 'false']);
    });
  });

  group('a popover says which surface it opened', () {
    testComponents('aria-controls names the panel only while open', (
      tester,
    ) async {
      // An id reference to a panel that is not in the document is worse
      // than none, so the closed trigger states nothing.
      pumpWithTheme(
        tester,
        const Popover(
          trigger: Component.text('Open'),
          content: Component.text('Panel'),
        ),
      );
      await tester.pump();

      Map<String, String> trigger() =>
          _attributes().firstWhere((a) => a.containsKey('aria-haspopup'));

      expect(trigger().containsKey('aria-controls'), isFalse);

      await tester.click(
        find.byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.attributes?.containsKey('aria-haspopup') ?? false),
        ),
      );
      await tester.pump();

      expect(trigger()['aria-expanded'], 'true');
      final panelId = trigger()['aria-controls'];
      expect(panelId, isNotNull);
      expect(_byId(panelId!), isNotNull, reason: 'the panel is in the tree');
    });
  });
}
