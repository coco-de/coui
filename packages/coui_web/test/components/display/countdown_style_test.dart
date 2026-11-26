// The digit of a Web Countdown: the `headline-large` role class and the
// on-surface ink class, read both off the resolver and off the `<span>` the
// widget actually renders, with tabular figures on the same element.
//
// The widget is one number; a unit box, a unit word and a width floor around
// it are the caller's. The number's tabular figures are what keep it from
// moving while it counts.
import 'package:coui_web/coui_web.dart';
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

Set<String> _classes(String? classes) =>
    (classes ?? '').split(' ').where((c) => c.isNotEmpty).toSet();

/// The `<span>` the countdown rendered — found by its numeric font feature.
DomComponent _countdownSpan() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere(
      (c) => c.tag == 'span' && _classes(c.classes).contains('tabular-nums'),
    );

void main() {
  group('Countdown digit typography (Web)', () {
    testComponents('resolves the headline-large role and on-surface ink', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final root = resolveCountdown(context).root;
      final classes = _classes(root.className);
      expect(classes, contains('text-headline-large'));
      expect(classes, contains('text-on-surface'));
      expect(classes, containsAll(['inline-block', 'tabular-nums']));
      // The role carries size, weight, line-height and tracking.
      final inline = root.inlineStyles?.properties ?? const <String, String>{};
      expect(inline.keys, isNot(contains('font-size')));
      expect(inline.keys, isNot(contains('font-weight')));
      expect(inline.keys, isNot(contains('letter-spacing')));
    });

    testComponents('the role is the one the Core default names', (
      tester,
    ) async {
      final context = _themedContext(tester);

      // Flutter materialises this same default; Web emits its class.
      final role = CoreCountdownStyle.defaultLabelStyle.token!;
      expect(role, CoreTextStyles.headlineLarge);
      expect(
        _classes(resolveCountdown(context).root.className),
        contains('text-${role.name}'),
      );
    });
  });

  group('Countdown rendered span (Web)', () {
    testComponents('the span wears the role, the ink and tabular figures', (
      tester,
    ) async {
      pumpWithTheme(tester, const Countdown(value: 12));

      final classes = _classes(_countdownSpan().classes);
      expect(
        classes,
        containsAll([
          'text-headline-large',
          'text-on-surface',
          'tabular-nums',
          'inline-block',
        ]),
      );
    });

    testComponents('the chrome does not depend on the digits shown', (
      tester,
    ) async {
      pumpWithTheme(tester, const Countdown(value: 8));
      final one = _classes(_countdownSpan().classes);

      pumpWithTheme(tester, const Countdown(value: 88));
      final two = _classes(_countdownSpan().classes);

      pumpWithTheme(tester, const Countdown(value: 365, max: 365));
      final three = _classes(_countdownSpan().classes);

      expect(two, one);
      expect(three, one);
      expect(three, contains('text-headline-large'));
    });
  });
}
