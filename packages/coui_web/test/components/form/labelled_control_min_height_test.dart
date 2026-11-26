// #5350 — Web twin of the Flutter `labelled_control_min_height_test`. A
// theme can floor a labelled SwitchField / Checkbox row; the default
// emits nothing, so the row renders as it always has (D17, #5306).
// jaspr_test has no layout, so this pins the declaration the browser
// lays the row out from.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// `min-height` of every DOM element that declares one.
List<String> _minHeights() => [
  for (final element in find.byType(DomComponent).evaluate())
    if ((element.component as DomComponent).styles?.properties['min-height']
        case final String value)
      value,
];

void main() {
  const floor = CoreA11ySize.touchTarget;
  const expected = '${floor / kRemDivisor}rem';

  testComponents('no floor is declared by default', (tester) async {
    pumpWithTheme(
      tester,
      div([
        SwitchField(label: '도착 알림', value: true),
        const Checkbox(label: '미해소만 보기'),
      ]),
    );

    expect(_minHeights(), isEmpty);
  });

  testComponents('a stated floor lands on each pressable row', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      div([
        SwitchField(
          label: '도착 알림',
          value: true,
          switchFieldStyle: const CoreSwitchFieldStyle(minHeight: floor),
        ),
        const Checkbox(
          label: '미해소만 보기',
          checkboxStyle: CoreCheckboxStyle(minHeight: floor),
        ),
      ]),
    );

    expect(_minHeights(), equals([expected, expected]));
  });
}
