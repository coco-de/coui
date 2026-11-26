// Pins what each step state looks like in `Stepper`, and what a disabled
// stepper is.
//
// A completed step is the `primary` fill with the `onPrimary` check, the
// current one the `surface` inside a `primary` ring with `onSurface` ink, an
// upcoming one the `surface` inside an `outlineVariant` ring with
// `onSurfaceVariant` ink, and the line that leaves a completed step is
// `primary`. A disabled stepper
// is a palette of its own — `disabledContainer` / `disabledOutline` /
// `disabledContent` — not a dimmed copy: it states no opacity and drops the
// `Clickable` whose disabled opacity would dim it twice.
//
// `enabled` follows `onStepChanged` when it is left `null`, so a stepper that
// cannot navigate is drawn disabled.
//
// The Web twin (`coui_web/test/components/layout/stepper_state_test.dart`)
// pins the same colours on the emitted classes and inline declarations.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _app(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kSteps = [
  CoreStepItem(label: 'Account', description: 'Create account'),
  CoreStepItem(label: 'Profile', description: 'Set up profile'),
  CoreStepItem(label: 'Complete', description: 'All done'),
];

CoreColor _token(CoreColorToken token) => CoreColor.token(token);

class _Resolved {
  _Resolved(this.stepper, this.color);

  final ResolvedStepper stepper;

  /// What a token reads as in the test theme.
  final material.Color Function(CoreColor) color;
}

Future<_Resolved> _resolve(
  WidgetTester tester, {
  required bool enabled,
  CoreStepperOrientation orientation = CoreStepperOrientation.horizontal,
  CoreStepperStyle? style,
}) async {
  late ResolvedStepper stepper;
  late material.Color Function(CoreColor) color;
  await tester.pumpWidget(
    _app(
      material.Builder(
        builder: (context) {
          stepper = resolveStepper(
            context,
            orientation: orientation,
            enabled: enabled,
            stepperStyle: style,
          );
          final scheme = Theme.of(context).colorScheme;
          color = (c) => scheme.resolve(c).toValue();
          return const material.SizedBox();
        },
      ),
    ),
  );

  return _Resolved(stepper, color);
}

void main() {
  group('Stepper step colours (enabled)', () {
    testWidgets('a completed circle is primary and bare, the current one a '
        'surface in a primary ring, an upcoming one a surface in a quieter '
        'ring', (tester) async {
      final r = await _resolve(tester, enabled: true);
      final completed = r.stepper.indicatorCompletedContainerStyle;
      final current = r.stepper.indicatorCurrentContainerStyle;
      final inactive = r.stepper.indicatorInactiveContainerStyle;

      expect(completed.backgroundColor, _token(CoreColors.primary));
      expect(completed.borderWidth, 0);
      expect(current.backgroundColor, _token(CoreColors.surface));
      expect(current.borderColor, _token(CoreColors.primary));
      expect(current.borderWidth, CoreStrokeWidth.stroke1);
      expect(inactive.backgroundColor, _token(CoreColors.surface));
      expect(inactive.borderColor, _token(CoreColors.outlineVariant));
      expect(inactive.borderWidth, CoreStrokeWidth.stroke1);
    });

    testWidgets('the completed line is primary, the upcoming one '
        'outlineVariant', (tester) async {
      final r = await _resolve(tester, enabled: true);

      expect(
        r.stepper.connectorActiveDividerStyle.color,
        _token(CoreColors.primary),
      );
      expect(
        r.stepper.connectorInactiveDividerStyle.color,
        _token(CoreColors.outlineVariant),
      );
    });

    testWidgets('the check is onPrimary, the numbers follow the fill they '
        'sit on', (tester) async {
      final r = await _resolve(tester, enabled: true);

      expect(
        r.stepper.indicatorIconStyle.color,
        _token(CoreColors.onPrimary),
      );
      // The current number sits on the surface, inside the ring — not on a
      // primary fill.
      expect(
        r.stepper.indicatorNumberActiveTextStyle.color,
        r.color(_token(CoreColors.onSurface)),
      );
      expect(
        r.stepper.indicatorNumberInactiveTextStyle.color,
        r.color(_token(CoreColors.onSurfaceVariant)),
      );
      expect(
        r.stepper.indicatorNumberActiveTextStyle.fontWeight,
        material.FontWeight.w600,
      );
    });

    testWidgets('only an upcoming label reads in onSurfaceVariant', (
      tester,
    ) async {
      for (final orientation in CoreStepperOrientation.values) {
        final r = await _resolve(
          tester,
          enabled: true,
          orientation: orientation,
        );
        final onSurface = r.color(_token(CoreColors.onSurface));

        expect(r.stepper.labelActiveTextStyle.color, onSurface);
        expect(r.stepper.labelInactiveTextStyle.color, onSurface);
        expect(
          r.stepper.labelUpcomingTextStyle.color,
          r.color(_token(CoreColors.onSurfaceVariant)),
        );
      }
    });

    testWidgets('a caller-stated ring colour wins over the current and '
        'upcoming defaults', (tester) async {
      final r = await _resolve(
        tester,
        enabled: true,
        style: const CoreStepperStyle(
          indicatorBorderColor: CoreColor.token(CoreColors.error),
        ),
      );

      expect(
        r.stepper.indicatorCurrentContainerStyle.borderColor,
        _token(CoreColors.error),
      );
      expect(
        r.stepper.indicatorInactiveContainerStyle.borderColor,
        _token(CoreColors.error),
      );
    });

    testWidgets('the current step has its own fill, ring and number, and '
        'leaves the others alone', (tester) async {
      final r = await _resolve(
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
      final current = r.stepper.indicatorCurrentContainerStyle;

      expect(current.backgroundColor, _token(CoreColors.primaryContainer));
      expect(current.borderColor, _token(CoreColors.error));
      expect(
        r.stepper.indicatorNumberActiveTextStyle.color,
        r.color(_token(CoreColors.error)),
      );
      // Completed and upcoming are what they were.
      expect(
        r.stepper.indicatorCompletedContainerStyle.backgroundColor,
        _token(CoreColors.primary),
      );
      expect(
        r.stepper.indicatorInactiveContainerStyle.borderColor,
        _token(CoreColors.outlineVariant),
      );
    });

    testWidgets('a caller-stated ring width reaches the current ring', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        enabled: true,
        style: const CoreStepperStyle(indicatorBorderWidth: 3),
      );

      expect(r.stepper.indicatorCurrentContainerStyle.borderWidth, 3);
      expect(r.stepper.indicatorInactiveContainerStyle.borderWidth, 3);
    });

    testWidgets('spacing: none beside a horizontal connector, none above and '
        'below a vertical one, 2 between label and description', (
      tester,
    ) async {
      final r = await _resolve(tester, enabled: true);

      expect(r.stepper.connectorMargin, 0);
      expect(r.stepper.connectorMarginVertical, 0);
      expect(r.stepper.descriptionGapStyle.size, CoreSpace.space2);
    });
  });

  group('Stepper step colours (disabled)', () {
    testWidgets('every circle, line and word takes its disabled colour', (
      tester,
    ) async {
      final r = await _resolve(tester, enabled: false);
      final completed = r.stepper.indicatorCompletedContainerStyle;
      final current = r.stepper.indicatorCurrentContainerStyle;
      final inactive = r.stepper.indicatorInactiveContainerStyle;
      final ink = r.color(_token(CoreColors.disabledContent));

      expect(completed.backgroundColor, _token(CoreColors.disabledContainer));
      // The surface either way — only the ring turns disabled.
      for (final outlined in [current, inactive]) {
        expect(outlined.backgroundColor, _token(CoreColors.surface));
        expect(outlined.borderColor, _token(CoreColors.disabledOutline));
        expect(outlined.borderWidth, CoreStrokeWidth.stroke1);
      }
      for (final line in [
        r.stepper.connectorActiveDividerStyle,
        r.stepper.connectorInactiveDividerStyle,
      ]) {
        expect(line.color, _token(CoreColors.disabledOutline));
      }
      expect(
        r.stepper.indicatorIconStyle.color,
        _token(CoreColors.disabledContent),
      );
      for (final text in [
        r.stepper.indicatorNumberActiveTextStyle,
        r.stepper.indicatorNumberInactiveTextStyle,
        r.stepper.labelActiveTextStyle,
        r.stepper.labelInactiveTextStyle,
        r.stepper.labelUpcomingTextStyle,
        r.stepper.descriptionTextStyle,
      ]) {
        expect(text.color, ink);
      }
    });

    testWidgets('the current label keeps its weight in the disabled ink', (
      tester,
    ) async {
      final r = await _resolve(tester, enabled: false);

      expect(
        r.stepper.labelActiveTextStyle.fontWeight,
        material.FontWeight.w600,
      );
      expect(
        r.stepper.labelInactiveTextStyle.fontWeight,
        material.FontWeight.w500,
      );
    });

    testWidgets('the disabled colours are fields a caller can restate', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        enabled: false,
        style: const CoreStepperStyle(
          indicatorDisabledColor: CoreColor.token(CoreColors.error),
          connectorDisabledColor: CoreColor.token(CoreColors.error),
          indicatorDisabledBorderColor: CoreColor.token(CoreColors.error),
          disabledForegroundColor: CoreColor.token(CoreColors.error),
        ),
      );
      final error = _token(CoreColors.error);

      expect(r.stepper.indicatorCompletedContainerStyle.backgroundColor, error);
      expect(r.stepper.indicatorCurrentContainerStyle.borderColor, error);
      expect(r.stepper.indicatorInactiveContainerStyle.borderColor, error);
      expect(r.stepper.connectorActiveDividerStyle.color, error);
      expect(r.stepper.indicatorIconStyle.color, error);
      expect(
        r.stepper.labelUpcomingTextStyle.color,
        r.color(error),
      );
    });
  });

  group('Stepper rendered circles', () {
    // The resolver hands over three bundles; the widget has to pick the right
    // one for each step. Read off the `OutlinedContainer` each circle is
    // composed from, in reading order — the ring and fill a step is drawn
    // with are what tell its state apart.
    List<CoreOutlinedContainerStyle> circles(WidgetTester tester) => [
      for (final box in tester.widgetList<OutlinedContainer>(
        find.descendant(
          of: find.byType(Stepper),
          matching: find.byType(OutlinedContainer),
        ),
      ))
        box.containerStyle!,
    ];

    for (final orientation in CoreStepperOrientation.values) {
      testWidgets('each step is drawn with its own state ($orientation)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            material.SizedBox(
              width: 600,
              child: Stepper(
                steps: _kSteps,
                currentStep: 1,
                orientation: orientation,
                enabled: true,
              ),
            ),
          ),
        );
        final [completed, current, upcoming] = circles(tester);

        // Completed: the primary fill, no ring.
        expect(completed.backgroundColor, _token(CoreColors.primary));
        expect(completed.borderWidth, 0);
        // Current: the surface inside a primary ring.
        expect(current.backgroundColor, _token(CoreColors.surface));
        expect(current.borderColor, _token(CoreColors.primary));
        expect(current.borderWidth, CoreStrokeWidth.stroke1);
        // Upcoming: the surface inside the quieter ring.
        expect(upcoming.backgroundColor, _token(CoreColors.surface));
        expect(upcoming.borderColor, _token(CoreColors.outlineVariant));
        expect(upcoming.borderWidth, CoreStrokeWidth.stroke1);
      });
    }

    testWidgets('moving the current step moves the ring with it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const material.SizedBox(
            width: 600,
            child: Stepper(steps: _kSteps, currentStep: 2, enabled: true),
          ),
        ),
      );
      final [first, second, third] = circles(tester);

      expect(first.backgroundColor, _token(CoreColors.primary));
      expect(second.backgroundColor, _token(CoreColors.primary));
      expect(third.borderColor, _token(CoreColors.primary));
      expect(third.backgroundColor, _token(CoreColors.surface));
    });
  });

  group('Stepper enabled', () {
    testWidgets('left null it follows onStepChanged', (tester) async {
      await tester.pumpWidget(
        _app(
          material.SizedBox(
            width: 600,
            child: Stepper(steps: _kSteps, onStepChanged: (_) {}),
          ),
        ),
      );
      // One Clickable per step.
      expect(find.byType(Clickable), findsNWidgets(_kSteps.length));

      await tester.pumpWidget(
        _app(
          const material.SizedBox(width: 600, child: Stepper(steps: _kSteps)),
        ),
      );
      expect(find.byType(Clickable), findsNothing);
    });

    testWidgets('false drops the Clickable even with a handler — no second '
        'dimming on top of the disabled palette', (tester) async {
      await tester.pumpWidget(
        _app(
          material.SizedBox(
            width: 600,
            child: Stepper(
              steps: _kSteps,
              onStepChanged: (_) {},
              enabled: false,
            ),
          ),
        ),
      );

      expect(find.byType(Clickable), findsNothing);
      expect(find.byType(material.Opacity), findsWidgets);
      // The only Opacity left is the invisible width reservation.
      for (final opacity in tester.widgetList<material.Opacity>(
        find.byType(material.Opacity),
      )) {
        expect(opacity.opacity, 0);
      }
    });

    testWidgets('true without a handler keeps the enabled palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const material.SizedBox(
            width: 600,
            child: Stepper(steps: _kSteps, enabled: true),
          ),
        ),
      );

      expect(find.byType(Clickable), findsNothing);
      expect(
        tester.widgetList<Text>(find.text('Account')).last.style?.color,
        isNot(
          Theme.of(
            tester.element(find.byType(Stepper)),
          ).colorScheme.resolve(_token(CoreColors.disabledContent)).toValue(),
        ),
      );
    });

    testWidgets('a disabled stepper does not navigate', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        _app(
          material.SizedBox(
            width: 600,
            child: Stepper(
              steps: _kSteps,
              enabled: false,
              onStepChanged: (i) => tapped = i,
            ),
          ),
        ),
      );
      await tester.tap(find.text('1'), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isNull);
    });
  });

  group('Stepper vertical description', () {
    testWidgets('a Gap sits between each label and its description', (
      tester,
    ) async {
      late ResolvedStepper resolved;
      await tester.pumpWidget(
        _app(
          material.Builder(
            builder: (context) {
              resolved = resolveStepper(
                context,
                orientation: CoreStepperOrientation.vertical,
                enabled: true,
              );
              return const material.SizedBox(
                width: 400,
                child: Stepper(
                  orientation: CoreStepperOrientation.vertical,
                  steps: _kSteps,
                  enabled: true,
                ),
              );
            },
          ),
        ),
      );

      final gaps = tester
          .widgetList<Gap>(find.byType(Gap))
          .where((g) => g.gapStyle == resolved.descriptionGapStyle);
      expect(gaps.length, _kSteps.length);
    });
  });
}
