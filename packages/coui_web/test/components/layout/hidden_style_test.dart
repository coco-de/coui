import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveHidden` directly.
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

String _transition(ResolvedHidden resolved) =>
    resolved.root.inlineStyles?.properties['transition'] ?? '';

/// Properties the collapse shorthand animates: `opacity`, `max-height`,
/// `max-width`. Not a design token — the length of the list the resolver
/// writes.
const _kAnimatedPropertyCount = 3;

void main() {
  // Why read the emitted string rather than the resolved field: a curve that
  // is merged correctly and never reaches the `transition` shorthand looks
  // finished from the authoring side and animates on the browser default.
  group('Hidden easing reaches the emitted transition', () {
    testComponents('default is the design-system easing token', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveHidden(context, hidden: false);

      expect(
        _transition(resolved),
        contains(CoreHiddenStyle.defaultTransitionCurve.toCss()),
      );
    });

    testComponents('the widget curve overrides it', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveHidden(
        context,
        hidden: false,
        curve: CoreEasing.easeOutBack,
      );

      final transition = _transition(resolved);
      expect(transition, contains(CoreEasing.easeOutBack.toCss()));
      expect(
        transition,
        isNot(contains(CoreHiddenStyle.defaultTransitionCurve.toCss())),
      );
    });

    testComponents('every animated property carries it', (tester) async {
      // One shorthand lists three properties; an easing applied to only the
      // first reads as the opacity fading on one curve while the collapse
      // runs on another.
      final context = _themedContext(tester);
      final resolved = resolveHidden(
        context,
        hidden: true,
        curve: CoreEasing.easeOutBack,
      );

      final timing = CoreEasing.easeOutBack.toCss();
      final occurrences = timing.allMatches(_transition(resolved)).length;
      expect(occurrences, equals(_kAnimatedPropertyCount));
    });
  });

  group('Hidden easing precedence', () {
    testComponents('theme style fills in when the widget is silent', (
      tester,
    ) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              hidden: CoreHiddenTheme(
                style: CoreHiddenStyle(transitionCurve: CoreEasing.easeInQuad),
              ),
            ),
          ),
          child: _ContextCapture((c) => context = c),
        ),
      );

      final resolved = resolveHidden(context, hidden: false);
      expect(
        _transition(resolved),
        contains(CoreEasing.easeInQuad.toCss()),
      );
    });

    testComponents('the widget curve wins over the theme', (tester) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              hidden: CoreHiddenTheme(curve: CoreEasing.easeInQuad),
            ),
          ),
          child: _ContextCapture((c) => context = c),
        ),
      );

      final resolved = resolveHidden(
        context,
        hidden: false,
        curve: CoreEasing.easeOutCirc,
      );
      expect(_transition(resolved), contains(CoreEasing.easeOutCirc.toCss()));
    });
  });
}
