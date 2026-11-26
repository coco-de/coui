// A radio entry's glyph is a value the entry states (`CoreMenuRadioMark`),
// not what makes it a radio: whichever glyph it draws, the row is a
// `menuitemradio` that selects and never deselects.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

Finder _row(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byComponentPredicate(
    (c) =>
        c is DomComponent &&
        (c.attributes?['role']?.startsWith('menuitem') ?? false),
  ),
);

List<IconName> _marks(String label) => [
  for (final element
      in find
          .descendant(of: _row(label), matching: find.byType(Icon))
          .evaluate())
    (element.component as Icon).icon,
];

String? _role(String label) =>
    (_row(label).evaluate().first.component as DomComponent)
        .attributes?['role'];

void main() {
  testComponents('the selected radio row draws the mark its entry states', (
    tester,
  ) async {
    final values = <bool>[];
    tester.pumpComponent(
      Theme.defaults(
        child: Menu(
          items: [
            CoreMenuItem.radio('Dot', selected: true, onChanged: (_) {}),
            CoreMenuItem.radio(
              'Check',
              selected: true,
              radioMark: CoreMenuRadioMark.check,
              onChanged: values.add,
            ),
            CoreMenuItem.radio(
              'Off',
              radioMark: CoreMenuRadioMark.check,
              onChanged: (_) {},
            ),
            CoreMenuItem.checkbox('Box', checked: true, onChanged: (_) {}),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(_marks('Dot'), [LucideIcons.circleDot]);
    expect(_marks('Check'), [LucideIcons.check]);
    expect(_marks('Off'), isEmpty);
    // The glyph does not decide the role: a check-marked radio is a radio.
    expect(_role('Dot'), 'menuitemradio');
    expect(_role('Check'), 'menuitemradio');
    expect(_role('Off'), 'menuitemradio');
    expect(_role('Box'), 'menuitemcheckbox');
    // …and it only selects: a checkbox would report `false` here.
    tester.dispatchEvent(_row('Check').first, 'click');
    await tester.pump();
    expect(values, [true]);
  });
}
