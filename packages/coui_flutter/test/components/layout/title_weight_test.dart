// Pins which titles state a weight of their own and which take their role's.
//
// The title roles are semi-bold (600). Steps gives every step, the current
// one included, a semi-bold (600) overlay — what sets the current step apart
// is its filled indicator and full-strength colour, not a heavier weight.
// Stepper's vertical labels are semi-bold on every step. Its horizontal
// labels sit on `labelLarge` (500) and state no weight, so the current step
// takes a semi-bold (600) overlay of its own to stay the heavier one.
//
// Card's header and Footer's section title state no weight, so they read the
// role's 600 — the section title and the company name share `titleSmall`, so
// the title can no longer read lighter than the company name beneath it.
//
// The Web twin (`coui_web/test/components/layout/title_weight_test.dart`)
// pins the same weights on the emitted classes and inline overlays.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _app(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// Weight of the visible copy of [text]. Horizontal Stepper labels sit in a
/// width-reservation stack whose two invisible copies come first.
FontWeight? _weightOf(WidgetTester tester, String text) =>
    tester.widgetList<Text>(find.text(text)).last.style?.fontWeight;

const _kStepData = [
  CoreStepData(title: 'Create Account'),
  CoreStepData(title: 'Verify Email'),
  CoreStepData(title: 'Complete Profile'),
];

const _kStepItems = [
  CoreStepItem(label: 'Account'),
  CoreStepItem(label: 'Verify'),
  CoreStepItem(label: 'Profile'),
];

const _kRegular = CoreTextStyle(fontWeight: CoreFontWeight.regular);
const _kExtraBold = CoreTextStyle(fontWeight: CoreFontWeight.extraBold);

void main() {
  group('Steps title weight', () {
    for (final vertical in [true, false]) {
      testWidgets(
        'every title is w600, the current one too (vertical: $vertical)',
        (
          tester,
        ) async {
          await tester.pumpWidget(
            _app(Steps(items: _kStepData, currentStep: 1, vertical: vertical)),
          );

          expect(_weightOf(tester, 'Verify Email'), FontWeight.w600);
          expect(_weightOf(tester, 'Create Account'), FontWeight.w600);
          expect(_weightOf(tester, 'Complete Profile'), FontWeight.w600);
        },
      );
    }

    testWidgets('a titleStyle weight override reaches the current step', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Steps(
            items: _kStepData,
            currentStep: 1,
            stepsStyle: CoreStepsStyle(titleStyle: _kRegular),
          ),
        ),
      );

      expect(_weightOf(tester, 'Verify Email'), FontWeight.w400);
      expect(_weightOf(tester, 'Create Account'), FontWeight.w400);
    });

    testWidgets('a currentTitleStyle override reaches the current step only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Steps(
            items: _kStepData,
            currentStep: 1,
            stepsStyle: CoreStepsStyle(currentTitleStyle: _kExtraBold),
          ),
        ),
      );

      expect(_weightOf(tester, 'Verify Email'), FontWeight.w800);
      expect(_weightOf(tester, 'Create Account'), FontWeight.w600);
    });
  });

  group('Stepper label weight', () {
    testWidgets('vertical: every label is semi-bold w600', (tester) async {
      await tester.pumpWidget(
        _app(
          const material.SizedBox(
            width: 400,
            child: Stepper(
              orientation: CoreStepperOrientation.vertical,
              steps: _kStepItems,
              currentStep: 1,
            ),
          ),
        ),
      );

      expect(_weightOf(tester, 'Verify'), FontWeight.w600);
      expect(_weightOf(tester, 'Account'), FontWeight.w600);
      expect(_weightOf(tester, 'Profile'), FontWeight.w600);
    });

    testWidgets('horizontal: current is w600, the rest the role w500', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const material.SizedBox(
            width: 600,
            child: Stepper(steps: _kStepItems, currentStep: 1),
          ),
        ),
      );

      expect(_weightOf(tester, 'Verify'), FontWeight.w600);
      expect(_weightOf(tester, 'Account'), FontWeight.w500);
      expect(_weightOf(tester, 'Profile'), FontWeight.w500);
    });

    testWidgets('a labelStyle weight override reaches the current step', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const material.SizedBox(
            width: 400,
            child: Stepper(
              orientation: CoreStepperOrientation.vertical,
              steps: _kStepItems,
              currentStep: 1,
              stepperStyle: CoreStepperStyle(labelStyle: _kRegular),
            ),
          ),
        ),
      );

      expect(_weightOf(tester, 'Verify'), FontWeight.w400);
      expect(_weightOf(tester, 'Account'), FontWeight.w400);
    });

    testWidgets('a labelActiveStyle override reaches the current step only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const material.SizedBox(
            width: 400,
            child: Stepper(
              orientation: CoreStepperOrientation.vertical,
              steps: _kStepItems,
              currentStep: 1,
              stepperStyle: CoreStepperStyle(labelActiveStyle: _kExtraBold),
            ),
          ),
        ),
      );

      expect(_weightOf(tester, 'Verify'), FontWeight.w800);
      expect(_weightOf(tester, 'Account'), FontWeight.w600);
    });
  });

  group('titles that follow their role', () {
    testWidgets('Card header resolves to the titleMedium weight w600', (
      tester,
    ) async {
      late ResolvedCard card;
      await tester.pumpWidget(
        _app(
          material.Builder(
            builder: (context) {
              card = resolveCard(
                context,
                variant: CoreCardVariant.defaultVariant,
                mediaPresent: false,
              );
              return const material.SizedBox();
            },
          ),
        ),
      );

      expect(CoreCardStyle.defaultHeaderTextStyle.fontWeight, isNull);
      expect(
        CoreTypography.coui.titleMedium.fontWeight,
        CoreFontWeight.semiBold,
      );
      expect(card.headerTextStyle.fontWeight, FontWeight.w600);
    });

    testWidgets('Footer section title and company name are both w600', (
      tester,
    ) async {
      late ResolvedFooter footer;
      await tester.pumpWidget(
        _app(
          material.Builder(
            builder: (context) {
              footer = resolveFooter(context);
              return const material.SizedBox();
            },
          ),
        ),
      );

      expect(CoreFooterStyle.defaultTitleTextStyle.fontWeight, isNull);
      expect(
        CoreTypography.coui.titleSmall.fontWeight,
        CoreFontWeight.semiBold,
      );
      expect(footer.titleStyle.fontWeight, FontWeight.w600);
      expect(footer.companyStyle.fontWeight, FontWeight.w600);
    });
  });
}
