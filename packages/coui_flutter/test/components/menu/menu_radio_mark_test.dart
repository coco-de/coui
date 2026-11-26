// A radio entry's glyph is a value the entry states (`CoreMenuRadioMark`),
// not what makes it a radio: whichever glyph it draws it selects and never
// deselects, and it announces itself as one choice of a group.

import 'dart:ui' show CheckedState;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

Finder _glyph(String label, IconName icon) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(MenuItem)),
  matching: find.byWidgetPredicate((w) => w is Icon && w.icon == icon),
);

void main() {
  test('a radio entry draws the dot unless it says otherwise', () {
    const plain = CoreMenuItem<Widget>.radio('A');
    expect(plain.radioMark, CoreMenuRadioMark.dot);
    expect(CoreMenuRadioMark.defaultMark, CoreMenuRadioMark.dot);
    expect(CoreMenuRadioMark.dot.icon, LucideIcons.circleDot);
    expect(CoreMenuRadioMark.check.icon, LucideIcons.check);
    const checked = CoreMenuItem<Widget>.radio(
      'A',
      shortcut: '#',
      radioMark: CoreMenuRadioMark.check,
    );
    expect(checked.kind, CoreMenuItemKind.radio);
    expect(checked.shortcut, '#');
  });

  testWidgets('the selected radio row draws the mark its entry states', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Menu(
        items: [
          CoreMenuItem.radio('Dot', selected: true, onChanged: (_) {}),
          CoreMenuItem.radio(
            'Check',
            selected: true,
            radioMark: CoreMenuRadioMark.check,
            onChanged: (_) {},
          ),
          CoreMenuItem.radio(
            'Off',
            radioMark: CoreMenuRadioMark.check,
            onChanged: (_) {},
          ),
        ],
      ),
    );
    expect(_glyph('Dot', LucideIcons.circleDot), findsOneWidget);
    expect(_glyph('Dot', LucideIcons.check), findsNothing);
    expect(_glyph('Check', LucideIcons.check), findsOneWidget);
    expect(_glyph('Check', LucideIcons.circleDot), findsNothing);
    // An unselected row draws no mark at all.
    expect(_glyph('Off', LucideIcons.check), findsNothing);
  });

  testWidgets('a check-marked radio still only selects', (tester) async {
    final values = <bool>[];
    await pumpTestApp(
      tester,
      Menu(
        items: [
          CoreMenuItem.radio(
            'Check',
            selected: true,
            radioMark: CoreMenuRadioMark.check,
            onChanged: values.add,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Check'));
    final _ = await tester.pumpAndSettle();
    // A checkbox would report `false` here; a radio never deselects.
    expect(values, [true]);
  });

  testWidgets('toggle rows announce their kind and whether they are on', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpTestApp(
      tester,
      Menu(
        items: [
          CoreMenuItem.radio(
            'Chosen',
            selected: true,
            radioMark: CoreMenuRadioMark.check,
            onChanged: (_) {},
          ),
          CoreMenuItem.radio('Other', onChanged: (_) {}),
          CoreMenuItem.checkbox('Grid', checked: true, onChanged: (_) {}),
          CoreMenuItem.action('Plain', onPressed: () {}),
        ],
      ),
    );
    // The row's role node encloses the node that carries its label and tap.
    SemanticsData data(String label) =>
        tester.getSemantics(find.text(label)).parent!.getSemanticsData();

    final chosen = data('Chosen');
    expect(chosen.role, SemanticsRole.menuItemRadio);
    expect(chosen.flagsCollection.isChecked, CheckedState.isTrue);
    expect(chosen.flagsCollection.isInMutuallyExclusiveGroup, isTrue);

    final other = data('Other');
    expect(other.role, SemanticsRole.menuItemRadio);
    expect(other.flagsCollection.isChecked, CheckedState.isFalse);
    expect(other.flagsCollection.isInMutuallyExclusiveGroup, isTrue);

    final grid = data('Grid');
    expect(grid.role, SemanticsRole.menuItemCheckbox);
    expect(grid.flagsCollection.isChecked, CheckedState.isTrue);
    expect(grid.flagsCollection.isInMutuallyExclusiveGroup, isFalse);

    expect(data('Plain').role, SemanticsRole.menuItem);
    handle.dispose();
  });
}
