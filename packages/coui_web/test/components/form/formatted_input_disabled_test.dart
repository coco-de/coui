// A disabled field says so in its own colours, not by dimming the enabled
// ones.
//
// The canvas states the pair outright — `color/disabled-container` on the
// fill, `color/disabled-outline` on the border — and this side used to say
// it a different way: `opacity-50` over the enabled tokens. The two are not
// interchangeable. A colour-forcing accessibility mode substitutes colours
// and leaves alpha alone, so a field dimmed by opacity keeps the enabled
// palette and reads as enabled there, while the tokens survive the
// substitution as tokens.
//
// That failure is invisible in every screenshot taken without the mode on,
// which is why it is worth a test rather than a look.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
// The resolver is internal chrome and the barrel does not re-export it.
import 'package:coui_web/src/components/form/formatted_input/formatted_input_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedFormattedInput _resolve(
  BuildContext context, {
  required bool enabled,
  bool focused = false,
}) => resolveFormattedInput(context, enabled: enabled, focused: focused);

void main() {
  group('a disabled FormattedInput carries its own tokens', () {
    testComponents('fill and border are the disabled pair', (tester) async {
      final context = _themedContext(tester);

      final disabled = _resolve(context, enabled: false);
      final className = disabled.root.className;

      expect(
        className,
        contains(
          CoreFormattedInputStyle.defaultDisabledBackgroundColor.tailwindColor,
        ),
        reason: 'the disabled fill token never reached the class list',
      );
      expect(
        className,
        contains(
          CoreFormattedInputStyle.defaultDisabledBorderColor.tailwindColor,
        ),
        reason: 'the disabled border token never reached the class list',
      );
    });

    testComponents('and it is not the enabled chrome dimmed', (tester) async {
      final context = _themedContext(tester);

      final disabled = _resolve(context, enabled: false);

      // The whole point of the change. `opacity-50` would keep the enabled
      // palette underneath, which is what a colour-forcing mode would then
      // substitute and show.
      expect(disabled.root.className, isNot(contains('opacity-50')));
      // The affordance stays: the cursor still says the control is inert.
      expect(disabled.root.className, contains('cursor-not-allowed'));
    });

    testComponents('the enabled chrome is genuinely different', (tester) async {
      final context = _themedContext(tester);

      final enabled = _resolve(context, enabled: true);
      final disabled = _resolve(context, enabled: false);

      // Asserted rather than assumed: if the disabled tokens ever resolved
      // to the enabled ones, both tests above would still pass while the
      // two states rendered identically.
      expect(disabled.root.className, isNot(enabled.root.className));
      expect(
        enabled.root.className,
        contains(CoreFormattedInputStyle.defaultBackgroundColor.tailwindColor),
      );
    });

    testComponents('disabled outranks focus', (tester) async {
      final context = _themedContext(tester);

      // A field can be disabled while it still holds focus. It should not
      // claim the focus ring — the ring says "your typing lands here", and
      // it does not.
      final disabledFocused = _resolve(context, enabled: false, focused: true);
      final disabledResting = _resolve(context, enabled: false);

      expect(disabledFocused.root.className, disabledResting.root.className);
      expect(
        disabledFocused.root.className,
        isNot(
          contains(
            CoreFormattedInputStyle.defaultFocusBorderColor.tailwindColor,
          ),
        ),
      );
    });
  });
}
