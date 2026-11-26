// Pins Web Steps' per-item status, the failed indicator, the list variant
// and the variant theme wiring — on the resolver's paint-ready output and
// on the rendered DOM. The Flutter twin is
// `coui_flutter/test/components/layout/steps_test.dart`.

import 'package:coui_web/coui_web.dart' hide css, events;
import 'package:coui_web/src/components/layout/steps/steps_style.dart';
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

BuildContext _themedContext(ComponentTester tester, {ThemeData? data}) {
  late BuildContext context;
  final capture = _ContextCapture((c) => context = c);
  if (data == null) {
    pumpWithTheme(tester, capture);
  } else {
    tester.pumpComponent(Theme(data: data, child: capture));
  }
  return context;
}

List<String> _classes(String? classes) => (classes ?? '').split(' ');

/// Every rendered element with [tag], in document order.
List<DomComponent> _tags(String tag) => find
    .tag(tag)
    .evaluate()
    .map((element) => element.component as DomComponent)
    .toList();

/// The glyph every rendered `Icon` draws, in document order.
List<IconName> _glyphs() => [
  for (final element in find.byType(Icon).evaluate())
    (element.component as Icon).icon,
];

const _kRun = [
  CoreStepData(title: 'Checkout', trailing: '2s', description: 'hidden'),
  CoreStepData(title: 'Build', trailing: '1m 12s'),
  CoreStepData(title: 'Test', status: CoreStepStatus.failed),
  CoreStepData(title: 'Deploy'),
];

void main() {
  group('resolveSteps — numbered statuses', () {
    testComponents('each status bakes its indicator fill', (tester) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: true,
        statuses: CoreStepStatus.values,
      );

      String fill(int i) => _classes(
        resolved.indicators[i].className,
      ).firstWhere((c) => c.startsWith('bg-'));
      String token(CoreColor c) => 'bg-${c.tailwindColor}';

      expect(fill(0), token(CoreStepsStyle.defaultActiveIndicatorColor));
      expect(fill(1), token(CoreStepsStyle.defaultActiveIndicatorColor));
      expect(fill(2), token(CoreStepsStyle.defaultIndicatorColor));
      expect(fill(3), token(CoreStepsStyle.defaultFailedIndicatorColor));
    });

    testComponents('the failed cross is the check box in onError', (
      tester,
    ) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: true,
        statuses: const [CoreStepStatus.failed],
      );

      expect(resolved.failedIconStyle.size, resolved.iconStyle.size);
      expect(
        resolved.failedIconStyle.color,
        CoreStepsStyle.defaultFailedLabelColor,
      );
    });

    testComponents('the horizontal layout bakes the same per-status fills', (
      tester,
    ) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: false,
        statuses: CoreStepStatus.values,
      );

      String fill(int i) => _classes(
        resolved.indicators[i].className,
      ).firstWhere((c) => c.startsWith('bg-'));
      String token(CoreColor c) => 'bg-${c.tailwindColor}';

      // The horizontal path draws its own indicator rows, but the circle
      // fill per status is the one table the vertical path reads.
      expect(resolved.indicatorRows, hasLength(CoreStepStatus.values.length));
      expect(fill(0), token(CoreStepsStyle.defaultActiveIndicatorColor));
      expect(fill(1), token(CoreStepsStyle.defaultActiveIndicatorColor));
      expect(fill(2), token(CoreStepsStyle.defaultIndicatorColor));
      expect(fill(3), token(CoreStepsStyle.defaultFailedIndicatorColor));
    });

    testComponents('every status takes the same semi-bold title', (
      tester,
    ) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: true,
        statuses: CoreStepStatus.values,
      );

      String? weight(int i) =>
          resolved.titles[i].inlineStyles?.properties['font-weight'];
      expect(
        [for (var i = 0; i < 4; i++) weight(i)],
        [
          '600',
          '600',
          '600',
          '600',
        ],
      );
    });
  });

  group('resolveSteps — progress reads in the primary colour', () {
    testComponents('an upcoming indicator is a ringed circle, the rest are '
        'filled', (tester) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: false,
        statuses: CoreStepStatus.values,
      );

      // done · current · todo · failed
      final ringed = [
        for (final i in resolved.indicators)
          _classes(i.className).contains('border'),
      ];
      expect(ringed, [false, false, true, false]);
      final todo = resolved.indicators[2];
      expect(
        _classes(todo.className),
        containsAll([
          'border',
          'border-${CoreStepsStyle.defaultIndicatorBorderColor.tailwindColor}',
          'bg-${CoreStepsStyle.defaultIndicatorColor.tailwindColor}',
        ]),
      );
      expect(
        todo.inlineStyles?.properties['border-width'],
        strokeWidthCss(CoreStepsStyle.defaultIndicatorBorderWidth),
      );
      for (final i in [0, 1, 3]) {
        expect(
          resolved.indicators[i].inlineStyles?.properties.containsKey(
            'border-width',
          ),
          isFalse,
        );
      }
    });

    testComponents('a raw ring colour goes inline, not onto a class', (
      tester,
    ) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: true,
        statuses: CoreStepStatus.values,
        stepsStyle: const CoreStepsStyle(
          indicatorBorderColor: CoreColor(0xFFFF0000),
          indicatorBorderWidth: 2,
        ),
      );

      final todo = resolved.indicators[2];
      expect(todo.inlineStyles?.properties['border-color'], isNotNull);
      expect(todo.inlineStyles?.properties['border-width'], strokeWidthCss(2));
    });

    for (final vertical in [true, false]) {
      testComponents(
        'only the connector leaving a completed step is primary '
        '(vertical: $vertical)',
        (tester) async {
          final resolved = resolveSteps(
            _themedContext(tester),
            variant: CoreStepsVariant.numbered,
            vertical: vertical,
            statuses: const [
              CoreStepStatus.done,
              CoreStepStatus.current,
              CoreStepStatus.todo,
              CoreStepStatus.todo,
            ],
          );

          String bg(int i) => _classes(
            resolved.connectors[i].className,
          ).firstWhere((c) => c.startsWith('bg-'));
          expect(resolved.connectors, hasLength(3));
          expect(
            bg(0),
            'bg-${CoreStepsStyle.defaultActiveConnectorColor.tailwindColor}',
          );
          expect(
            bg(1),
            'bg-${CoreStepsStyle.defaultConnectorColor.tailwindColor}',
          );
          expect(bg(2), bg(1));
          expect(bg(0), isNot(bg(1)));
        },
      );
    }

    testComponents('an upcoming step reads quieter, a failed one does not', (
      tester,
    ) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: true,
        statuses: CoreStepStatus.values,
      );

      String text(int i) => _classes(
        resolved.titles[i].className,
      ).firstWhere((c) => c.startsWith('text-on-'));
      // done · current · todo · failed
      expect(text(0), 'text-on-surface');
      expect(text(1), 'text-on-surface');
      expect(text(2), 'text-on-surface-variant');
      expect(text(3), 'text-on-surface');
      // The number inside the upcoming circle reads quiet too.
      expect(
        _classes(resolved.indicatorNumbers[2].className),
        contains('text-on-surface-variant'),
      );
    });

    testComponents('the horizontal row carries its own, wider connector gap', (
      tester,
    ) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: false,
        statuses: CoreStepStatus.values,
      );

      expect(resolved.indicatorConnectorGapStyle.size, 4);
      expect(resolved.indicatorConnectorGapHorizontalStyle.size, 8);

      final overridden = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: false,
        statuses: CoreStepStatus.values,
        stepsStyle: const CoreStepsStyle(
          indicatorConnectorGapHorizontalStyle: CoreGapStyle(size: 16),
        ),
      );
      expect(overridden.indicatorConnectorGapHorizontalStyle.size, 16);
      expect(overridden.indicatorConnectorGapStyle.size, 4);
    });
  });

  group('resolveSteps — list variant', () {
    testComponents('a full-width column, no numbered entries', (
      tester,
    ) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.list,
        vertical: false,
        statuses: CoreStepStatus.values,
      );

      expect(
        _classes(resolved.root.className),
        containsAll(['flex', 'flex-col', 'w-full']),
      );
      expect(resolved.indicators, isEmpty);
      expect(resolved.connectors, isEmpty);
    });

    testComponents('forwards the row slot raw', (tester) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.list,
        vertical: true,
        statuses: CoreStepStatus.values,
        stepsStyle: const CoreStepsStyle(
          stepItemStyle: CoreStepItemStyle(minHeight: 40),
        ),
      );

      expect(
        resolved.stepItemStyle,
        CoreStepsStyle.defaultStepItemStyle.merge(
          const CoreStepItemStyle(minHeight: 40),
        ),
      );
    });

    testComponents('theme variantStyles reach only their variant', (
      tester,
    ) async {
      const data = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          steps: CoreStepsTheme(
            variantStyles: {
              CoreStepsVariant.list: CoreStepsStyle(
                stepItemStyle: CoreStepItemStyle(minHeight: 44),
              ),
            },
          ),
        ),
      );
      final context = _themedContext(tester, data: data);

      final list = resolveSteps(
        context,
        variant: CoreStepsVariant.list,
        vertical: true,
        statuses: const [CoreStepStatus.todo],
      );
      final numbered = resolveSteps(
        context,
        variant: CoreStepsVariant.numbered,
        vertical: true,
        statuses: const [CoreStepStatus.todo],
      );

      expect(list.stepItemStyle.minHeight, 44);
      expect(numbered.stepItemStyle.minHeight, isNull);
    });
  });

  group('Steps rendering', () {
    testComponents("an item's status wins, the rest follow currentStep", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Steps(
          currentStep: 1,
          items: [
            CoreStepData(title: 'a'),
            CoreStepData(title: 'b', status: CoreStepStatus.failed),
            CoreStepData(title: 'c'),
          ],
        ),
      );

      // a: before currentStep → done → check; b: stated failed → cross;
      // c: after → to do, its number.
      expect(_glyphs(), [LucideIcons.check, LucideIcons.x]);
      expect(find.text('3'), findsOneComponent);
      expect(_tags('div').first.attributes?['role'], isNull);
    });

    testComponents('horizontal: a stated failed status draws its cross', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Steps(
          vertical: false,
          items: [
            CoreStepData(title: 'a', status: CoreStepStatus.done),
            CoreStepData(title: 'b', status: CoreStepStatus.failed),
            CoreStepData(title: 'c'),
          ],
        ),
      );

      // The horizontal build is its own path (`_buildHorizontalStep`), so
      // the stated status has to reach its indicators as well.
      expect(_glyphs(), [LucideIcons.check, LucideIcons.x]);
      expect(find.text('3'), findsOneComponent);
      expect(_tags('div').first.attributes?['role'], isNull);
    });

    testComponents('list: a list of StepItem entries, current marked', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Steps(
          items: _kRun,
          currentStep: 1,
          variant: CoreStepsVariant.list,
        ),
      );

      final root = _tags('div').first;
      expect(root.attributes?['role'], 'list');
      final rows = [
        for (final element in find.byType(StepItem).evaluate())
          element.component as StepItem,
      ];
      expect(
        [for (final r in rows) r.status],
        [
          CoreStepStatus.done,
          CoreStepStatus.current,
          CoreStepStatus.failed,
          CoreStepStatus.todo,
        ],
      );
      expect(_glyphs(), [
        LucideIcons.circleCheck,
        LucideIcons.circleDot,
        LucideIcons.circleX,
        LucideIcons.circle,
      ]);

      final entries = _tags(
        'div',
      ).where((d) => d.attributes?['role'] == 'listitem').toList();
      expect(entries, hasLength(_kRun.length));
      expect(
        [for (final e in entries) e.attributes?['aria-current']],
        [
          null,
          'step',
          null,
          null,
        ],
      );
      expect(find.text('hidden'), findsNothing);
      expect(find.text('1m 12s'), findsOneComponent);
    });
  });
}
