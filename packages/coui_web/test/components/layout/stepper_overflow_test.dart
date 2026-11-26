// #5351 — a horizontal step column may not grow past an equal share of
// the row. The Flutter twin computes the share from its layout width and
// checks the rendered row; jaspr_test has no layout, so this pins the
// declarations that state the same share to the browser: every column
// flex-fills the row evenly (`flex-1`) and states a floor of the indicator —
// and nothing above it, so a label that does not fit wraps in its column.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kSteps = <CoreStepItem>[
  CoreStepItem(label: 'Empfängerinformationen'),
  CoreStepItem(label: 'Überweisungsbetragsbestätigung'),
  CoreStepItem(label: 'Zusammenfassungsübersicht'),
];

/// `min-width` of every element that declares one in the stepper's own
/// markup — the step columns (the half-line wrappers state `0`).
List<String> _minWidths() => [
  for (final element in find.tag('div').evaluate())
    if ((element.component as DomComponent).styles?.properties['min-width']
        case final String value when value != '0')
      value,
];

/// The horizontal step columns: the `flex-1` columns that stretch their
/// track and label across them (the vertical content column is `flex-1` too,
/// but does not stretch).
List<DomComponent> _stepColumns() => [
  for (final element in find.tag('div').evaluate())
    if ((element.component as DomComponent).classes?.split(' ')
        case final List<String> classes
        when classes.contains('flex-1') && classes.contains('items-stretch'))
      element.component as DomComponent,
];

void main() {
  group('Stepper step column share', () {
    testComponents('each horizontal step column is an even share of the row, '
        'never narrower than its indicator', (tester) async {
      pumpWithTheme(tester, const Stepper(steps: _kSteps));

      // Same token the Flutter twin reads as `minColumnWidth`.
      const floor = '${CoreStepperStyle.defaultIndicatorSize / kRemDivisor}rem';

      expect(_stepColumns(), hasLength(_kSteps.length));
      expect(_minWidths(), equals([floor, floor, floor]));
    });

    testComponents('no column states a width above its share', (tester) async {
      pumpWithTheme(tester, const Stepper(steps: _kSteps));

      for (final column in _stepColumns()) {
        final raw = column.styles?.properties ?? const <String, String>{};
        expect(raw.containsKey('max-width'), isFalse);
        expect(raw.containsKey('width'), isFalse);
      }
    });

    testComponents('the vertical layout states no share', (tester) async {
      pumpWithTheme(
        tester,
        const Stepper(
          orientation: CoreStepperOrientation.vertical,
          steps: _kSteps,
        ),
      );

      expect(_stepColumns(), isEmpty);
      expect(_minWidths(), isEmpty);
    });
  });
}
