// The label row of a `FormField` must be exactly as tall as its label.
//
// A plain block `<div>` holds the inline `<label>` in a line box whose strut is
// the field's own body line height (21px). A 13px label has an 18.2px line, so
// the row came out 21px and the input sat 3px below where the Flutter twin
// puts it — every labelled `FormField` on Web. A flex row has no strut: its
// item is the label's own line.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Iterable<DomComponent> _rowsHoldingLabel() => find
    .tag('div')
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>()
    .where(
      (d) => (d.children ?? const []).any(
        (c) => c is FormLabel || (c is DomComponent && c.tag == 'label'),
      ),
    );

void main() {
  group('the FormField label row is a flex row', () {
    testComponents('without an action', (tester) async {
      pumpWithTheme(
        tester,
        const FormField(label: 'Email', child: Text('input')),
      );

      final row = _rowsHoldingLabel().single;
      final classes = (row.classes ?? '').split(' ');
      expect(classes, containsAll(['flex', 'w-full', 'items-center']));
      expect(classes, isNot(contains('justify-between')));
    });

    testComponents('with an action it also spreads its two ends', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FormField(
          label: 'Password',
          labelAction: Text('Forgot?'),
          child: Text('input'),
        ),
      );

      final classes = (_rowsHoldingLabel().single.classes ?? '').split(' ');
      expect(
        classes,
        containsAll(['flex', 'w-full', 'items-center', 'justify-between']),
      );
    });
  });
}
