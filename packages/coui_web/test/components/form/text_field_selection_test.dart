import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  testComponents('raw selection colors reach only the scoped input', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const TextField(
        id: 'selection-check',
        textFieldStyle: CoreTextFieldStyle(
          selectionColor: CoreColor(0x80FF0000),
        ),
      ),
    );
    final input = find.tag('input').evaluate().single.component as DomComponent;
    expect(input.classes, contains('co-text-field-selection-selection-check'));
    final style = find.tag('style').evaluate().single.component as DomComponent;
    final css = (style.children!.first as RawText).text;
    expect(
      css,
      contains('.co-text-field-selection-selection-check::selection'),
    );
    expect(css, contains('255, 0, 0'));
  });
}
