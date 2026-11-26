// Pins what each step state looks like in the Web `Stepper`, and what a
// disabled stepper is.
//
// A completed step is the `primary` fill with the `onPrimary` check, the
// current one the `surface` inside a `primary` ring with `onSurface` ink, an
// upcoming one the `surface` inside an `outlineVariant` ring with
// `onSurfaceVariant` ink, and the line that leaves a completed step is
// `primary`. A disabled stepper
// is a palette of its own — `disabledContainer` / `disabledOutline` /
// `disabledContent` — not a dimmed copy: nothing in its markup states an
// opacity, and it is not wrapped in the `Clickable` whose disabled opacity
// would dim it twice.
//
// `enabled` follows `onStepChanged` when it is left `null`, so a stepper that
// cannot navigate is drawn disabled.
//
// The Flutter twin (`coui_flutter/test/components/layout/
// stepper_state_test.dart`) pins the same colours on the resolved values.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/stepper/stepper_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedStepper _resolve(
  ComponentTester tester, {
  required bool enabled,
  bool vertical = false,
  CoreStepperStyle? style,
}) => resolveStepper(
  _themedContext(tester),
  vertical: vertical,
  enabled: enabled,
  currentStep: 1,
  stepCount: 3,
  stepperStyle: style,
);

List<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toList();

String? _inline(WebElementChrome chrome, String property) =>
    chrome.inlineStyles?.properties[property];

const _kCurrentRing = 'rgb(var(--coui-primary))';
const _kRing = 'rgb(var(--coui-outline-variant))';
const _kDisabledRing = 'rgb(var(--coui-disabled-outline))';

void main() {
  group('Stepper step colours (enabled)', () {
    testComponents('a completed circle is primary and bare, the current one a '
        'surface in a primary ring, an upcoming one a surface in a quieter '
        'ring', (tester) async {
      final r = _resolve(tester, enabled: true);

      expect(_classes(r.indicators[0]), contains('bg-primary'));
      expect(_inline(r.indicators[0], 'border-style'), isNull);
      // `currentStep` is 1 here.
      expect(_classes(r.indicators[1]), contains('bg-surface'));
      expect(_classes(r.indicators[1]), isNot(contains('bg-primary')));
      expect(_inline(r.indicators[1], 'border-style'), 'solid');
      expect(
        _inline(r.indicators[1], 'border-width'),
        contains('stroke-width'),
      );
      expect(_inline(r.indicators[1], 'border-color'), _kCurrentRing);
      expect(_classes(r.indicators[2]), contains('bg-surface'));
      expect(_inline(r.indicators[2], 'border-style'), 'solid');
      expect(_inline(r.indicators[2], 'border-color'), _kRing);
    });

    testComponents('the completed line is primary, the upcoming one '
        'outlineVariant', (tester) async {
      final r = _resolve(tester, enabled: true);

      expect(r.connectorDividerStyles[0].color, isA<CoreColor>());
      expect(
        r.connectorDividerStyles[0].color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        r.connectorDividerStyles[1].color,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    testComponents('the check is onPrimary, the numbers follow the fill they '
        'sit on', (tester) async {
      final r = _resolve(tester, enabled: true);

      expect(
        r.indicatorIconStyles[0].color,
        const CoreColor.token(CoreColors.onPrimary),
      );
      // The current number sits on the surface, inside the ring — not on a
      // primary fill.
      expect(_classes(r.indicatorNumbers[1]), contains('text-on-surface'));
      expect(
        _classes(r.indicatorNumbers[1]),
        isNot(contains('text-on-primary')),
      );
      expect(_classes(r.indicatorNumbers[1]), contains('text-label-medium'));
      expect(_inline(r.indicatorNumbers[1], 'font-weight'), '600');
      expect(
        _classes(r.indicatorNumbers[2]),
        contains('text-on-surface-variant'),
      );
    });

    testComponents('only an upcoming label reads in onSurfaceVariant', (
      tester,
    ) async {
      for (final vertical in [true, false]) {
        final r = _resolve(tester, enabled: true, vertical: vertical);

        expect(_classes(r.labels[0]), contains('text-on-surface'));
        expect(_classes(r.labels[1]), contains('text-on-surface'));
        expect(_classes(r.labels[2]), contains('text-on-surface-variant'));
        expect(_classes(r.labels[2]), isNot(contains('text-on-surface')));
      }
    });

    testComponents('a caller-stated ring colour wins over the current and '
        'upcoming defaults', (tester) async {
      final r = _resolve(
        tester,
        enabled: true,
        style: const CoreStepperStyle(
          indicatorBorderColor: CoreColor.token(CoreColors.error),
        ),
      );

      for (final i in [1, 2]) {
        expect(
          _inline(r.indicators[i], 'border-color'),
          'rgb(var(--coui-error))',
        );
      }
    });

    testComponents('the current step has its own fill, ring and number, and '
        'leaves the others alone', (tester) async {
      final r = _resolve(
        tester,
        enabled: true,
        style: const CoreStepperStyle(
          indicatorCurrentColor: CoreColor.token(CoreColors.primaryContainer),
          indicatorCurrentBorderColor: CoreColor.token(CoreColors.error),
          indicatorNumberActiveStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.error),
          ),
        ),
      );

      expect(_classes(r.indicators[1]), contains('bg-primary-container'));
      expect(
        _inline(r.indicators[1], 'border-color'),
        'rgb(var(--coui-error))',
      );
      expect(_classes(r.indicatorNumbers[1]), contains('text-error'));
      // Completed and upcoming are what they were.
      expect(_classes(r.indicators[0]), contains('bg-primary'));
      expect(_inline(r.indicators[2], 'border-color'), _kRing);
    });

    testComponents('a caller-stated ring width reaches the current ring', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        enabled: true,
        style: const CoreStepperStyle(indicatorBorderWidth: 3),
      );

      for (final i in [1, 2]) {
        expect(_inline(r.indicators[i], 'border-width'), contains('3'));
      }
    });

    testComponents('spacing: none beside a horizontal connector, none above '
        'and below a vertical one, 2 between label and description', (
      tester,
    ) async {
      final horizontal = _resolve(tester, enabled: true);
      final vertical = _resolve(tester, enabled: true, vertical: true);

      expect(
        _inline(horizontal.connectorStart, 'margin-inline-end'),
        'var(--coui-space-0)',
      );
      expect(
        _inline(horizontal.connectorEnd, 'margin-inline-start'),
        'var(--coui-space-0)',
      );
      expect(
        _inline(vertical.connectorWrappers[0], 'margin-top'),
        'var(--coui-space-0)',
      );
      expect(
        _inline(vertical.connectorWrappers[0], 'margin-bottom'),
        'var(--coui-space-0)',
      );
      expect(horizontal.descriptionGapStyle.size, CoreSpace.space2);
    });
  });

  group('Stepper step colours (disabled)', () {
    testComponents('every circle, line and word takes its disabled colour', (
      tester,
    ) async {
      final r = _resolve(tester, enabled: false);

      expect(_classes(r.indicators[0]), contains('bg-disabled-container'));
      // The surface either way — only the ring turns disabled.
      for (final i in [1, 2]) {
        expect(_classes(r.indicators[i]), contains('bg-surface'));
        expect(_inline(r.indicators[i], 'border-color'), _kDisabledRing);
      }
      for (final line in r.connectorDividerStyles) {
        expect(line.color, const CoreColor.token(CoreColors.disabledOutline));
      }
      expect(
        r.indicatorIconStyles[0].color,
        const CoreColor.token(CoreColors.disabledContent),
      );
      for (final chrome in [
        ...r.indicatorNumbers.skip(1),
        ...r.labels,
        ...r.descriptions,
      ]) {
        expect(_classes(chrome), contains('text-disabled-content'));
      }
    });

    testComponents('the current label keeps its weight in the disabled ink', (
      tester,
    ) async {
      final r = _resolve(tester, enabled: false);

      expect(_inline(r.labels[1], 'font-weight'), '600');
      expect(_inline(r.labels[0], 'font-weight'), isNull);
    });

    testComponents('a disabled stepper states no opacity', (tester) async {
      final r = _resolve(tester, enabled: false);

      for (final chrome in [
        r.root,
        ...r.stepWrappers,
        ...r.indicators,
        ...r.labels,
        ...r.connectorWrappers,
        r.track,
        r.connectorStart,
        r.connectorEnd,
      ]) {
        expect(
          chrome.inlineStyles?.properties.containsKey('opacity') ?? false,
          isFalse,
        );
        expect(_classes(chrome).any((c) => c.startsWith('opacity-')), isFalse);
      }
    });

    testComponents('the disabled colours are fields a caller can restate', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        enabled: false,
        style: const CoreStepperStyle(
          indicatorDisabledColor: CoreColor.token(CoreColors.error),
          connectorDisabledColor: CoreColor.token(CoreColors.error),
          indicatorDisabledBorderColor: CoreColor.token(CoreColors.error),
          disabledForegroundColor: CoreColor.token(CoreColors.error),
        ),
      );

      expect(_classes(r.indicators[0]), contains('bg-error'));
      for (final i in [1, 2]) {
        expect(
          _inline(r.indicators[i], 'border-color'),
          'rgb(var(--coui-error))',
        );
      }
      expect(
        r.connectorDividerStyles[0].color,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        r.indicatorIconStyles[0].color,
        const CoreColor.token(CoreColors.error),
      );
      expect(_classes(r.labels[2]), contains('text-error'));
    });
  });

  group('Stepper enabled', () {
    const steps = [
      CoreStepItem(label: 'One'),
      CoreStepItem(label: 'Two'),
      CoreStepItem(label: 'Three'),
    ];

    int clickables() => find
        .tag('div')
        .evaluate()
        .where(
          (e) => (e.component as DomComponent).attributes?['role'] == 'button',
        )
        .length;

    testComponents('left null it follows onStepChanged', (tester) async {
      pumpWithTheme(tester, Stepper(steps: steps, onStepChanged: (_) {}));
      expect(clickables(), steps.length);

      pumpWithTheme(tester, const Stepper(steps: steps));
      expect(clickables(), 0);
    });

    testComponents('false drops the Clickable even with a handler', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Stepper(steps: steps, onStepChanged: (_) {}, enabled: false),
      );

      expect(clickables(), 0);
    });
  });

  group('Stepper vertical description', () {
    testComponents('the resolver hands the widget the label↔description gap', (
      tester,
    ) async {
      final r = _resolve(tester, enabled: true, vertical: true);

      expect(
        r.descriptionGapStyle,
        CoreStepperStyle.defaultDescriptionGapStyle,
      );
    });
  });
}
