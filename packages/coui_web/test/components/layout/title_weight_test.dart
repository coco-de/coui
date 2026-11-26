// Pins which titles state a weight of their own and which take their role's.
//
// The title roles are semi-bold (600). Steps gives every step, the current
// one included, a semi-bold (600) overlay — what sets the current step apart
// is its filled indicator and full-strength colour, not a heavier weight.
// Stepper's vertical labels are semi-bold on every step. Its horizontal
// labels sit on `labelLarge` (500) and state no weight, so the current step
// takes a semi-bold (600) overlay of its own to stay the heavier one. The
// overlays leave the role on its `text-{role}` class and arrive as an inline
// `font-weight`.
//
// Card's header and Footer's section title state no weight, so only the role
// class is emitted and the role's 600 applies.
//
// The Flutter twin (`coui_flutter/test/components/layout/title_weight_test
// .dart`) pins the same weights on the resolved `TextStyle`s.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/layout/card/card_style.dart';
import 'package:coui_web/src/components/layout/footer/footer_style.dart';
import 'package:coui_web/src/components/layout/stepper/stepper_style.dart';
import 'package:coui_web/src/components/layout/steps/steps_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
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

String? _weightOf(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties['font-weight'];

/// What `Steps` hands its resolver for [count] items placed against
/// [currentStep] alone — the same Core rule the widget reads.
List<CoreStepStatus> _statuses({
  required int currentStep,
  required int count,
}) => [
  for (var i = 0; i < count; i++)
    CoreStepStatus.effective(index: i, currentStep: currentStep),
];

const _kRegular = CoreTextStyle(fontWeight: CoreFontWeight.regular);
const _kExtraBold = CoreTextStyle(fontWeight: CoreFontWeight.extraBold);

void main() {
  group('Steps title weight', () {
    for (final vertical in [true, false]) {
      testComponents(
        'every title is 600, the current one too (vertical: $vertical)',
        (
          tester,
        ) async {
          final resolved = resolveSteps(
            _themedContext(tester),
            variant: CoreStepsVariant.numbered,
            vertical: vertical,
            statuses: _statuses(currentStep: 1, count: 3),
          );

          expect(_weightOf(resolved.titles[1]), '600');
          expect(_weightOf(resolved.titles[0]), '600');
          expect(_weightOf(resolved.titles[2]), '600');
          for (final title in resolved.titles) {
            expect(title.className.split(' '), contains('text-title-small'));
            expect(title.className, isNot(contains('font-bold')));
          }
        },
      );
    }

    testComponents('a titleStyle weight override reaches the current step', (
      tester,
    ) async {
      final resolved = resolveSteps(
        _themedContext(tester),
        variant: CoreStepsVariant.numbered,
        vertical: true,
        statuses: _statuses(currentStep: 1, count: 3),
        stepsStyle: const CoreStepsStyle(titleStyle: _kRegular),
      );

      expect(_weightOf(resolved.titles[1]), '400');
      expect(_weightOf(resolved.titles[0]), '400');
    });

    testComponents(
      'a currentTitleStyle override reaches the current step only',
      (tester) async {
        final resolved = resolveSteps(
          _themedContext(tester),
          variant: CoreStepsVariant.numbered,
          vertical: true,
          statuses: _statuses(currentStep: 1, count: 3),
          stepsStyle: const CoreStepsStyle(currentTitleStyle: _kExtraBold),
        );

        expect(_weightOf(resolved.titles[1]), '800');
        expect(_weightOf(resolved.titles[0]), '600');
      },
    );
  });

  group('Stepper label weight', () {
    testComponents('vertical: every label is semi-bold 600', (tester) async {
      final resolved = resolveStepper(
        _themedContext(tester),
        vertical: true,
        enabled: true,
        currentStep: 1,
        stepCount: 3,
      );

      expect(_weightOf(resolved.labels[1]), '600');
      expect(_weightOf(resolved.labels[0]), '600');
      expect(_weightOf(resolved.labels[2]), '600');
    });

    testComponents('horizontal: current is 600, the rest the role 500', (
      tester,
    ) async {
      final resolved = resolveStepper(
        _themedContext(tester),
        vertical: false,
        enabled: true,
        currentStep: 1,
        stepCount: 3,
      );

      expect(_weightOf(resolved.labels[1]), '600');
      expect(_weightOf(resolved.labels[0]), isNull);
      expect(_weightOf(resolved.labels[2]), isNull);
      expect(
        resolved.labels[0].className.split(' '),
        contains('text-label-large'),
      );
      expect(CoreTypography.coui.labelLarge.fontWeight, CoreFontWeight.medium);
    });

    testComponents('a labelStyle weight override reaches the current step', (
      tester,
    ) async {
      final resolved = resolveStepper(
        _themedContext(tester),
        vertical: true,
        enabled: true,
        currentStep: 1,
        stepCount: 3,
        stepperStyle: const CoreStepperStyle(labelStyle: _kRegular),
      );

      expect(_weightOf(resolved.labels[1]), '400');
      expect(_weightOf(resolved.labels[0]), '400');
    });

    testComponents(
      'a labelActiveStyle override reaches the current step only',
      (tester) async {
        final resolved = resolveStepper(
          _themedContext(tester),
          vertical: true,
          enabled: true,
          currentStep: 1,
          stepCount: 3,
          stepperStyle: const CoreStepperStyle(labelActiveStyle: _kExtraBold),
        );

        expect(_weightOf(resolved.labels[1]), '800');
        expect(_weightOf(resolved.labels[0]), '600');
      },
    );
  });

  group('titles that follow their role', () {
    testComponents('Card header emits the titleMedium role and no weight', (
      tester,
    ) async {
      final resolved = resolveCard(
        _themedContext(tester),
        variant: CoreCardVariant.defaultVariant,
        hasMedia: false,
        interactive: false,
      );

      expect(
        resolved.header.className.split(' '),
        contains('text-title-medium'),
      );
      expect(_weightOf(resolved.header), isNull);
      expect(
        CoreTypography.coui.titleMedium.fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    testComponents('Footer section title and company name share the role', (
      tester,
    ) async {
      final resolved = resolveFooter(_themedContext(tester));

      expect(resolved.title.className.split(' '), contains('text-title-small'));
      expect(_weightOf(resolved.title), isNull);
      expect(
        resolved.company.className.split(' '),
        contains('text-title-small'),
      );
      expect(_weightOf(resolved.company), isNull);
      expect(
        CoreTypography.coui.titleSmall.fontWeight,
        CoreFontWeight.semiBold,
      );
    });
  });
}
