import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(
  material.Widget child, {
  CoreComponentTheme? componentTheme,
}) => material.MaterialApp(
  home: Theme(
    data: componentTheme == null
        ? const ThemeData()
        : ThemeData(coreComponentTheme: componentTheme),
    child: child,
  ),
);

Finder _glyph(IconName name) =>
    find.byWidgetPredicate((widget) => widget is Icon && widget.icon == name);

/// The fill an indicator circle is drawn with — the box `Steps` composes.
List<CoreColor?> _indicatorFills(WidgetTester tester) => [
  for (final box in tester.widgetList<OutlinedContainer>(
    find.byType(OutlinedContainer),
  ))
    box.containerStyle?.backgroundColor,
];

void main() {
  group('Steps', () {
    const items = [
      CoreStepData(title: 'Create Account', description: 'Sign up'),
      CoreStepData(title: 'Verify Email'),
      CoreStepData(title: 'Complete Profile'),
    ];

    testWidgets('renders vertical layout with titles and descriptions', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(const Steps(items: items, currentStep: 1)),
      );

      expect(find.byType(Steps), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Verify Email'), findsOneWidget);
      expect(find.text('Complete Profile'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('renders horizontal layout', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Steps(items: items, currentStep: 1, vertical: false),
        ),
      );

      expect(find.byType(Steps), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('completed steps render a check icon', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(const Steps(items: items, currentStep: 2)),
      );

      // Steps 0 and 1 are completed (index < currentStep) → check icons;
      // step 2 (current) still shows its number.
      expect(find.byType(Icon), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('resolver resolves indicator colours from the scheme', (
      tester,
    ) async {
      late ResolvedSteps resolved;
      final _ = await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveSteps(
                context,
                variant: CoreStepsVariant.numbered,
              );
              return const Steps(items: items, currentStep: 1);
            },
          ),
        ),
      );

      // Active (primary) and inactive (surfaceContainer) fills differ —
      // pre-EMIT `CoreColor` tokens forwarded to the composed
      // `OutlinedContainer`, which runs the scheme-resolve itself.
      expect(
        resolved.activeIndicatorContainerStyle.backgroundColor,
        isNot(equals(resolved.inactiveIndicatorContainerStyle.backgroundColor)),
      );
      expect(resolved.checkIconStyle.color, isNotNull);
      expect(resolved.activeConnectorStyle.color, isNotNull);
    });

    group('status', () {
      testWidgets("an item's own status wins over currentStep", (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Steps(
              items: [
                CoreStepData(title: 'a', status: CoreStepStatus.done),
                CoreStepData(title: 'b', status: CoreStepStatus.failed),
                CoreStepData(title: 'c'),
              ],
            ),
          ),
        );

        // a: stated done → check; b: stated failed → cross; c: index 2 after
        // currentStep 0 → to do, its number.
        expect(_glyph(LucideIcons.check), findsOneWidget);
        expect(_glyph(LucideIcons.x), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(_indicatorFills(tester), [
          CoreStepsStyle.defaultActiveIndicatorColor,
          CoreStepsStyle.defaultFailedIndicatorColor,
          CoreStepsStyle.defaultIndicatorColor,
        ]);
      });

      testWidgets('a failed cross is drawn in the failed label colour', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            const Steps(
              items: [CoreStepData(title: 'a', status: CoreStepStatus.failed)],
            ),
          ),
        );

        final cross = tester.widget<Icon>(_glyph(LucideIcons.x));
        expect(cross.iconStyle?.color, CoreStepsStyle.defaultFailedLabelColor);
      });

      testWidgets('horizontal layout takes the stated status too', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            const Steps(
              vertical: false,
              items: [
                CoreStepData(title: 'a', status: CoreStepStatus.done),
                CoreStepData(title: 'b', status: CoreStepStatus.failed),
                CoreStepData(title: 'c'),
              ],
            ),
          ),
        );

        // The horizontal build is its own path (`_buildHorizontal`), so the
        // stated status has to reach its indicators as well.
        expect(find.byType(Divider), findsNWidgets(2));
        expect(_glyph(LucideIcons.check), findsOneWidget);
        expect(_glyph(LucideIcons.x), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(_indicatorFills(tester), [
          CoreStepsStyle.defaultActiveIndicatorColor,
          CoreStepsStyle.defaultFailedIndicatorColor,
          CoreStepsStyle.defaultIndicatorColor,
        ]);
        final cross = tester.widget<Icon>(_glyph(LucideIcons.x));
        expect(cross.iconStyle?.color, CoreStepsStyle.defaultFailedLabelColor);
      });
    });

    group('progress reads in the primary colour', () {
      late ResolvedSteps resolved;
      Widget app(Steps steps) => _buildApp(
        Builder(
          builder: (context) {
            resolved = resolveSteps(
              context,
              variant: CoreStepsVariant.numbered,
            );
            return steps;
          },
        ),
      );

      List<CoreColor?> connectorColors(WidgetTester tester) => [
        for (final d in tester.widgetList<Divider>(find.byType(Divider)))
          d.dividerStyle?.color,
      ];

      testWidgets('an upcoming indicator is the page fill inside a ring', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(const Steps(items: items, currentStep: 1)),
        );

        final boxes = tester
            .widgetList<OutlinedContainer>(find.byType(OutlinedContainer))
            .map((b) => b.containerStyle!)
            .toList();
        // done / current are filled and draw no ring; the upcoming one is the
        // surface fill with an outlineVariant ring of one stroke.
        expect(boxes[0].borderWidth, 0);
        expect(boxes[1].borderWidth, 0);
        expect(boxes[2].backgroundColor, CoreStepsStyle.defaultIndicatorColor);
        expect(
          CoreStepsStyle.defaultIndicatorColor,
          const CoreColor.token(CoreColors.surface),
        );
        expect(
          boxes[2].borderColor,
          const CoreColor.token(CoreColors.outlineVariant),
        );
        expect(boxes[2].borderWidth, CoreStrokeWidth.stroke1);
        expect(resolved.inactiveIndicatorContainerStyle.borderWidth, 1);
      });

      testWidgets(
        'the ring and fill of an upcoming indicator are overridable',
        (
          tester,
        ) async {
          await tester.pumpWidget(
            app(
              const Steps(
                items: items,
                stepsStyle: CoreStepsStyle(
                  indicatorBorderColor: CoreColor.token(CoreColors.primary),
                  indicatorBorderWidth: 2,
                ),
              ),
            ),
          );

          final upcoming = tester
              .widgetList<OutlinedContainer>(find.byType(OutlinedContainer))
              .last
              .containerStyle!;
          expect(
            upcoming.borderColor,
            const CoreColor.token(CoreColors.primary),
          );
          expect(upcoming.borderWidth, 2);
        },
      );

      for (final vertical in [true, false]) {
        testWidgets('only the connector leaving a completed step is primary '
            '(vertical: $vertical)', (tester) async {
          await tester.pumpWidget(
            app(Steps(items: items, currentStep: 1, vertical: vertical)),
          );
          // step 0 done → its connector filled in; step 1 current → its
          // connector still the quiet one.
          expect(connectorColors(tester), [
            CoreStepsStyle.defaultActiveConnectorColor,
            CoreStepsStyle.defaultConnectorColor,
          ]);
          expect(
            CoreStepsStyle.defaultActiveConnectorColor,
            const CoreColor.token(CoreColors.primary),
          );
          expect(
            CoreStepsStyle.defaultConnectorColor,
            const CoreColor.token(CoreColors.outlineVariant),
          );
        });
      }

      testWidgets('both connectors fill in once both steps are done', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(const Steps(items: items, currentStep: 2)),
        );
        expect(connectorColors(tester), [
          CoreStepsStyle.defaultActiveConnectorColor,
          CoreStepsStyle.defaultActiveConnectorColor,
        ]);
      });

      testWidgets('the connector colours are overridable', (tester) async {
        await tester.pumpWidget(
          app(
            const Steps(
              items: items,
              currentStep: 1,
              stepsStyle: CoreStepsStyle(
                activeConnectorColor: CoreColor.token(CoreColors.success),
                connectorColor: CoreColor.token(CoreColors.warning),
              ),
            ),
          ),
        );
        expect(connectorColors(tester), [
          const CoreColor.token(CoreColors.success),
          const CoreColor.token(CoreColors.warning),
        ]);
      });

      testWidgets('an upcoming step reads quieter; the rest stay full', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(const Steps(items: items, currentStep: 1)),
        );

        Color? colorOf(String text) =>
            tester.widget<Text>(find.text(text)).style?.color;
        expect(colorOf('Create Account'), resolved.titleColor);
        expect(colorOf('Verify Email'), resolved.titleColor);
        expect(colorOf('Complete Profile'), resolved.inactiveTitleColor);
        expect(resolved.inactiveTitleColor, isNot(resolved.titleColor));
        // The number inside an upcoming indicator reads quiet too.
        expect(colorOf('3'), resolved.inactiveLabelColor);
        expect(resolved.inactiveLabelColor, resolved.inactiveTitleColor);
        // A failed step keeps the full-strength title.
        expect(CoreStepsStyle.defaultInactiveTitleColor, isNotNull);
      });

      testWidgets('a failed step keeps the full-strength title', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(
            const Steps(
              items: [
                CoreStepData(title: 'Publish', status: CoreStepStatus.failed),
              ],
            ),
          ),
        );
        expect(
          tester.widget<Text>(find.text('Publish')).style?.color,
          resolved.titleColor,
        );
      });

      testWidgets('numbers and titles are semi-bold, the current one too', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(const Steps(items: items, currentStep: 1)),
        );
        FontWeight? weightOf(String text) =>
            tester.widget<Text>(find.text(text)).style?.fontWeight;
        expect(weightOf('2'), FontWeight.w600);
        expect(weightOf('3'), FontWeight.w600);
        expect(weightOf('Verify Email'), FontWeight.w600);
      });
    });

    group('the gap around a connector', () {
      testWidgets('horizontal: 8 on either side of the line', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Center(
              child: SizedBox(
                width: 600,
                child: Steps(items: items, currentStep: 1, vertical: false),
              ),
            ),
          ),
        );

        final circle = tester.getRect(find.byType(OutlinedContainer).first);
        final line = tester.getRect(find.byType(Divider).first);
        expect(line.left - circle.right, 8);
        // The line stops 8 short of the step that follows it.
        final next = tester.getRect(find.byType(OutlinedContainer).at(1));
        final step = tester.getRect(find.byType(Expanded).first);
        expect(line.right, lessThanOrEqualTo(next.left - 8));
        expect(step.width, greaterThan(circle.width));
      });

      testWidgets('vertical: 4 above and below the line', (tester) async {
        await tester.pumpWidget(
          _buildApp(const Steps(items: items, currentStep: 1)),
        );

        final circle = tester.getRect(find.byType(OutlinedContainer).first);
        final line = tester.getRect(find.byType(Divider).first);
        final next = tester.getRect(find.byType(OutlinedContainer).at(1));
        expect(line.top - circle.bottom, 4);
        expect(next.top - line.bottom, 4);
      });

      testWidgets('the horizontal gap is its own field', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Center(
              child: SizedBox(
                width: 600,
                child: Steps(
                  items: items,
                  vertical: false,
                  stepsStyle: CoreStepsStyle(
                    indicatorConnectorGapHorizontalStyle: CoreGapStyle(
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final circle = tester.getRect(find.byType(OutlinedContainer).first);
        final line = tester.getRect(find.byType(Divider).first);
        expect(line.left - circle.right, 16);
      });
    });

    group('list variant', () {
      const runItems = [
        CoreStepData(title: 'Checkout', trailing: '2s', description: 'hidden'),
        CoreStepData(title: 'Build', trailing: '1m 12s'),
        CoreStepData(title: 'Test', status: CoreStepStatus.failed),
        CoreStepData(title: 'Deploy'),
      ];

      testWidgets('stacks one StepItem per step, flush, without numbers', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            const Center(
              child: SizedBox(
                width: 320,
                child: Steps(
                  items: runItems,
                  currentStep: 1,
                  variant: CoreStepsVariant.list,
                ),
              ),
            ),
          ),
        );

        final rows = tester
            .widgetList<StepItem>(find.byType(StepItem))
            .toList();
        expect(
          [for (final r in rows) r.status],
          [
            CoreStepStatus.done,
            CoreStepStatus.current,
            CoreStepStatus.failed,
            CoreStepStatus.todo,
          ],
        );
        expect(
          [for (final r in rows) r.trailing],
          ['2s', '1m 12s', null, null],
        );
        // No numbered chrome, and the description is not drawn.
        expect(find.byType(OutlinedContainer), findsNothing);
        expect(find.byType(Divider), findsNothing);
        expect(find.text('hidden'), findsNothing);
        // Rows stack flush at their own 32, filling the width.
        final first = tester.getRect(find.byType(StepItem).first);
        final second = tester.getRect(find.byType(StepItem).at(1));
        expect(first.height, 32);
        expect(second.top, first.bottom);
        expect(first.width, 320);
      });

      testWidgets('ignores vertical: false', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Center(
              child: SizedBox(
                width: 320,
                child: Steps(
                  items: runItems,
                  vertical: false,
                  variant: CoreStepsVariant.list,
                ),
              ),
            ),
          ),
        );

        final first = tester.getRect(find.byType(StepItem).first);
        final second = tester.getRect(find.byType(StepItem).at(1));
        expect(second.top, first.bottom);
        expect(second.left, first.left);
      });

      testWidgets('forwards stepItemStyle to every row', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Center(
              child: SizedBox(
                width: 320,
                child: Steps(
                  items: runItems,
                  variant: CoreStepsVariant.list,
                  stepsStyle: CoreStepsStyle(
                    stepItemStyle: CoreStepItemStyle(minHeight: 40),
                  ),
                ),
              ),
            ),
          ),
        );

        for (final row in tester.widgetList<StepItem>(find.byType(StepItem))) {
          expect(row.stepItemStyle?.minHeight, 40);
        }
        expect(tester.getSize(find.byType(StepItem).first).height, 40);
      });

      testWidgets('theme variantStyles reach only their variant', (
        tester,
      ) async {
        const theme = CoreComponentTheme(
          steps: CoreStepsTheme(
            variantStyles: {
              CoreStepsVariant.list: CoreStepsStyle(
                stepItemStyle: CoreStepItemStyle(minHeight: 44),
              ),
              CoreStepsVariant.numbered: CoreStepsStyle(
                failedIndicatorColor: CoreColor.token(CoreColors.warning),
              ),
            },
          ),
        );

        await tester.pumpWidget(
          _buildApp(
            const Center(
              child: SizedBox(
                width: 320,
                child: Steps(items: runItems, variant: CoreStepsVariant.list),
              ),
            ),
            componentTheme: theme,
          ),
        );
        expect(tester.getSize(find.byType(StepItem).first).height, 44);

        await tester.pumpWidget(
          _buildApp(
            const Steps(
              items: [CoreStepData(title: 'a', status: CoreStepStatus.failed)],
            ),
            componentTheme: theme,
          ),
        );
        expect(_indicatorFills(tester), [
          const CoreColor.token(CoreColors.warning),
        ]);
      });

      testWidgets('announces a list of entries, the current one selected', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _buildApp(
            const Center(
              child: SizedBox(
                width: 320,
                child: Steps(
                  items: runItems,
                  currentStep: 1,
                  variant: CoreStepsVariant.list,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final list = tester
            .getSemantics(find.byType(CoUISemantics).first)
            .getSemanticsData();
        expect(list.role, SemanticsRole.list);
        final entries = [
          for (var i = 1; i <= runItems.length; i++)
            tester
                .getSemantics(find.byType(CoUISemantics).at(i))
                .getSemanticsData(),
        ];
        expect(
          [for (final e in entries) e.role],
          [
            for (var i = 0; i < runItems.length; i++) SemanticsRole.listItem,
          ],
        );
        expect(
          [for (final e in entries) e.flagsCollection.isSelected],
          [Tristate.none, Tristate.isTrue, Tristate.none, Tristate.none],
        );
        handle.dispose();
      });
    });
  });
}
