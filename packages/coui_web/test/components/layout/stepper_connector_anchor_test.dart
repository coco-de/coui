// Pins the Web horizontal connector to the indicator's centre, and the shape
// of the track it sits in.
//
// A horizontal step is a column of one track — a half-line wrapper, the
// circle, a half-line wrapper — over its label, and every column is an equal
// share of the row. The connector between two steps is the trailing half of
// one and the leading half of the next; the first step's leading half and the
// last step's trailing half are empty wrappers that keep their width.
//
// The wrapper used to carry `align-self: flex-start` + `margin-top:
// indicatorSize/2`, which puts the wrapper's TOP at the indicator centre. The
// line inside is only its thickness tall, so its centre landed half a
// thickness low — the same defect the Flutter twin had, from the same
// mistake about which edge to anchor.
//
// Asserted on the emitted declarations rather than a rendered pixel because
// jaspr_test has no layout. The Flutter twin's test measures real rects; this
// one pins the construction that produces them, and the two together are what
// keeps the platforms saying the same thing.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kSteps = <CoreStepItem>[
  CoreStepItem(label: 'One'),
  CoreStepItem(label: 'Two'),
];

/// Inline declarations of every connector wrapper — the flex children that
/// are neither a step column nor the root. The two axes spell the growth
/// differently — `1 1 0%` for a horizontal half-line, `1 1 auto` for the
/// vertical connector — so match the prefix rather than either literal.
List<Map<String, String>> _connectorStyles() => [
  for (final element in find.tag('div').evaluate())
    if ((element.component as DomComponent).styles?.properties
        case final Map<String, String> raw
        when (raw['flex'] ?? '').startsWith('1'))
      raw,
];

void main() {
  group('Stepper connector anchor', () {
    testComponents('the horizontal half-lines centre in an indicator band', (
      tester,
    ) async {
      pumpWithTheme(tester, const Stepper(steps: _kSteps));

      final wrappers = _connectorStyles();
      // A leading and a trailing half for every step.
      expect(wrappers, hasLength(_kSteps.length * 2));

      for (final styles in wrappers) {
        expect(
          styles['align-items'],
          equals('center'),
          reason: 'the line centres inside the band',
        );
        expect(
          styles.containsKey('height'),
          isTrue,
          reason: 'the band is the indicator height, not a top offset',
        );
        expect(
          styles.containsKey('margin-top'),
          isFalse,
          reason:
              'a margin-top offset anchors the wrapper top, which lands '
              'the line half a thickness below the indicator centre',
        );
      }
    });

    testComponents('the band height matches the indicator height', (
      tester,
    ) async {
      pumpWithTheme(tester, const Stepper(steps: _kSteps));

      // Same token both sides read, expressed the way this file emits it.
      const expected =
          '${CoreStepperStyle.defaultIndicatorSize / kRemDivisor}rem';
      for (final styles in _connectorStyles()) {
        expect(styles['height'], equals(expected));
      }
    });

    testComponents('each half-line holds connectorMargin off the circle, on '
        'its own side of the row', (tester) async {
      pumpWithTheme(
        tester,
        const Stepper(
          steps: _kSteps,
          stepperStyle: CoreStepperStyle(connectorMargin: 8),
        ),
      );

      final wrappers = _connectorStyles();
      // Reading order: step one's leading half, its trailing half, step two's
      // leading half, … — leading halves sit before the circle, so the circle
      // is at their end.
      for (var i = 0; i < wrappers.length; i++) {
        final leading = i.isEven;
        expect(
          wrappers[i][leading ? 'margin-inline-end' : 'margin-inline-start'],
          equals(spaceCss(8)),
        );
        expect(
          wrappers[i].containsKey(
            leading ? 'margin-inline-start' : 'margin-inline-end',
          ),
          isFalse,
          reason: 'the outer end of a half-line meets its neighbour, no gap',
        );
      }
    });

    testComponents('the first and last steps carry no line beyond '
        'themselves', (tester) async {
      pumpWithTheme(
        tester,
        const Stepper(
          steps: [
            CoreStepItem(label: 'One'),
            CoreStepItem(label: 'Two'),
            CoreStepItem(label: 'Three'),
          ],
        ),
      );

      // Two connectors between three steps, two halves each. The first
      // step's leading wrapper and the last step's trailing wrapper are
      // there — they keep the circle centred — but empty.
      expect(find.byType(Divider).evaluate(), hasLength(4));
      final wrappers = [
        for (final element in find.tag('div').evaluate())
          if ((element.component as DomComponent).styles?.properties['flex']
              case '1 1 0%')
            element,
      ];
      expect(wrappers, hasLength(6));
    });

    testComponents('each half-line takes the colour of the connector it '
        'belongs to', (tester) async {
      pumpWithTheme(
        tester,
        const Stepper(
          currentStep: 1,
          enabled: true,
          steps: [
            CoreStepItem(label: 'One'),
            CoreStepItem(label: 'Two'),
            CoreStepItem(label: 'Three'),
          ],
        ),
      );

      // Tree order: step one's trailing half, step two's leading half, step
      // two's trailing half, step three's leading half. The connector between
      // steps one and two is behind the current step (completed); the one
      // between two and three is ahead of it.
      const primary = CoreColor.token(CoreColors.primary);
      const quiet = CoreColor.token(CoreColors.outlineVariant);
      expect(
        [
          for (final element in find.byType(Divider).evaluate())
            (element.component as Divider).dividerStyle?.color,
        ],
        orderedEquals(const [primary, primary, quiet, quiet]),
      );
    });

    testComponents('the half-lines flex-fill and may shrink below their line', (
      tester,
    ) async {
      pumpWithTheme(tester, const Stepper(steps: _kSteps));

      for (final styles in _connectorStyles()) {
        expect(styles['flex'], equals('1 1 0%'));
        expect(styles['min-width'], equals('0'));
      }
    });

    testComponents('the vertical connector is untouched', (tester) async {
      pumpWithTheme(
        tester,
        const Stepper(
          steps: _kSteps,
          orientation: CoreStepperOrientation.vertical,
        ),
      );

      final wrappers = _connectorStyles();
      // One connector between two steps.
      expect(wrappers, hasLength(1));
      expect(
        wrappers.single['align-items'],
        isNull,
        reason: 'the vertical connector was already correct',
      );
      expect(wrappers.single.containsKey('min-height'), isTrue);
    });
  });
}
