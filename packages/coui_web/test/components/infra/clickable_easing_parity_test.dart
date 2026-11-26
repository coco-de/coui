import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

// Regression for #3467/#3521: `Clickable`'s press/focus transition used to
// ride three different curves depending on path — Tailwind's own default
// `cubic-bezier(0.4,0,0.2,1)` on the untouched default path, raw `ease` for
// the scoped-rule override's transform, and raw `ease-in-out` for its
// box-shadow. All three now state `CoreEasing.move`
// (`var(--easing-ease-in-out)`).

ResolvedClickable? _seenDefault;

class _CaptureDefault extends StatelessComponent {
  const _CaptureDefault({required this.style});

  final CoreClickableStyle? style;

  @override
  Component build(BuildContext context) {
    _seenDefault = resolveClickable(
      context,
      enabled: true,
      focusOutline: true,
      enableFeedback: true,
      clickableStyle: style,
    );
    return const Component.text('x');
  }
}

ResolvedClickableRules? _seenRules;

class _CaptureRules extends StatelessComponent {
  const _CaptureRules({required this.style});

  final CoreClickableStyle? style;

  @override
  Component build(BuildContext context) {
    _seenRules = resolveClickableRules(
      context,
      scopeId: 'co-clickable-test',
      enabled: true,
      focusOutline: true,
      enableFeedback: true,
      clickableStyle: style,
    );
    return const Component.text('x');
  }
}

void main() {
  const standardEasingVar = 'var(--easing-ease-in-out)';

  testComponents(
    'default path (no override) states CoreEasing.move inline, not '
    "Tailwind's own default curve",
    (tester) async {
      pumpWithTheme(tester, const _CaptureDefault(style: null));
      await tester.pump();

      final props = _seenDefault!.root.inlineStyles?.properties ?? const {};
      expect(props['transition-timing-function'], standardEasingVar);
    },
  );

  testComponents(
    'override path (custom duration) scoped rule states the same curve as '
    'the default path — transform and box-shadow no longer diverge',
    (tester) async {
      // A duration override is enough to flip `pseudoOverridden` and switch
      // Clickable onto the scoped-rule path (see `_resolveClickableValues`).
      const overridden = CoreClickableStyle(
        duration: Duration(milliseconds: 250),
      );

      pumpWithTheme(tester, const _CaptureRules(style: overridden));
      await tester.pump();
      final rulesCss = _seenRules!.css;

      expect(rulesCss, isNotEmpty);
      // Every entry of the `transition:` shorthand carries the identical
      // curve — the bug this regression guards was `ease` for transform vs
      // `ease-in-out` for box-shadow. The ring's outline colour and its
      // band's box-shadow ride the same clock as each other.
      expect(
        'transform '.allMatches(rulesCss).length +
            'outline-color '.allMatches(rulesCss).length +
            'box-shadow '.allMatches(rulesCss).length,
        3,
      );
      expect(rulesCss.split(standardEasingVar).length - 1, 3);
      // Neither raw CSS keyword survives — only the token-routed variable.
      expect(rulesCss, isNot(contains('ease,')));
      expect(rulesCss, isNot(contains('ease-in-out;')));

      // The override path also gets the same inline
      // `transition-timing-function` from `resolveClickable` — belt and
      // suspenders, since inline always outranks the scoped rule anyway.
      pumpWithTheme(tester, const _CaptureDefault(style: overridden));
      await tester.pump();
      final props = _seenDefault!.root.inlineStyles?.properties ?? const {};
      expect(props['transition-timing-function'], standardEasingVar);
    },
  );
}
